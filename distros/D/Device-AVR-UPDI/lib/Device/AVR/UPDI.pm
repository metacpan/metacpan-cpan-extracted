#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Device::AVR::UPDI;

use strict;
use warnings;

use Carp;

use Future::AsyncAwait;
use Future::IO 0.03; # ->sysread_exactly

use Struct::Dumb qw( readonly_struct );

our $VERSION = '0.01';

readonly_struct PartInfo => [qw(
   signature
   baseaddr_nvmctrl
   baseaddr_fuse
   baseaddr_sigrow

   baseaddr_flash
   pagesize

   fusenames
)];

my %partinfos;
{
   while( <DATA> ) {
      m/^#/ and next;
      chomp;
      my ( $name, $signature, @fields ) = split m/\|/, $_;
      $signature = pack "H*", $signature;
      my $fuses = [ map { length ? $_ : undef } split m/,/, pop @fields ];
      m/^0x/ and $_ = hex $_ for @fields;

      my $partinfo = PartInfo( $signature, @fields, $fuses );

      $partinfos{lc $name} = $partinfo;
      $partinfos{"m$1"} = $partinfo if $name =~ m/^ATmega(.*)$/;
      $partinfos{"t$1"} = $partinfo if $name =~ m/^ATtiny(.*)$/;
   }
}

=head1 NAME

C<Device::AVR::UPDI> - interact with an F<AVR> microcontroller over F<UPDI>

=head1 DESCRIPTION

This module provides a class for interacting with an F<AVR> microcontroller in
one of the newer F<ATmega> 0-series, or F<ATtiny> 0-series or 1-series types,
which uses the F<UPDI> programming and debug interface.

=head2 Hardware Interface

This code expects to find a serial port connected to the UPDI pin of the
microcontroller as a shared single-wire interface. Suitable hardware to
provide this can be created using a USB-UART adapter, connecting the C<RX>
line directly to the MCU's C<UPDI> pin, and connecting C<TX> via a
current-limiting resistor of 4.7 kohm.

   +------------+                    +-------------------+
   |         RX-|-------------+      |                   |
   | USB-UART   |             +------|-UPDI              |
   |         TX-|---[ 4k7 ]---+      |  ATmega or ATtiny |
   +------------+                    +-------------------|

=cut

=head1 CONSTRUCTORS

=cut

=head2 new

   $updi = Device::AVR::UPDI->new( ... )

Constructs and returns a new C<Device::AVR::UPDI> instance.

Takes the following named arguments:

=over 4

=item dev => STRING

Path to the device node representing the serial port connection.

=item fh => IO

Alternative to C<dev>, provides an IO handle directly. This should be an
instance of L<IO::Termios>, or at least, provide the same interface.

=item part => STRING

Name of the AVR chip to interact with. This is used to define parameters like
memory size and location of internal peripherals.

Any of the following forms are accepted

   part => "ATtiny814"  | "attiny814"  | "t814"
   part => "ATmega4809" | "atmega4809" | "m4809"

=back

After construction, the link must be initialised by calling L</init_link>
before any of the command methods are used.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $fh = $args{fh} // do {
      require IO::Termios;
      IO::Termios->open( $args{dev} );
   };

   $fh->cfmakeraw();

   # 115200baud, 8bits, Even parity, 2 stop
   $fh->set_mode( "115200,8,e,2" );
   $fh->setflag_clocal( 1 );

   # Opportunistically try to set an even faster baud rate. If it works, great;
   # if not we'll just use 115200 instead
   $fh->setbaud( 230400 );

   $fh->autoflush;

   my $part = $args{part} or croak "Require 'part'";
   my $partinfo = $partinfos{lc $part} //
      croak "Unrecognised part name $part";

   my $self = bless {
      fh => $fh,
      partinfo => $partinfo,
   }, $class;

   return $self;
}

=head1 ACCESSORS

=cut

=head2 partinfo

   $partinfo = $updi->partinfo

Returns the Part Info structure containing base addresses and other parameters
which may be useful for interacting with the chip.

The returned structure provides the following fields

   $sig = $partinfo->signature

   $addr = $partinfo->baseaddr_nvmctrl
   $addr = $partinfo->baseaddr_fuse
   $addr = $partinfo->baseaddr_flash
   $addr = $partinfo->baseaddr_sigrow

   $bytes = $partinfo->pagesize

   $fusenames = $partinfo->fusenames

=cut

sub partinfo
{
   my $self = shift;
   return $self->{partinfo};
}

=head1 METHODS

=cut

use constant {
   # SYNC byte
   SYNC => "\x55",

   # Instruction opcodes
   OP_LDS         => 0x00,
   OP_STS         => 0x40,
      OP_DATA8       => 0x00,
      OP_DATA16      => 0x01,
      OP_ADDR8       => 0x00,
      OP_ADDR16      => 0x04,
   OP_LD          => 0x20,
   OP_ST          => 0x60,
      OP_PTR         => 0x00,
      OP_PTRINC      => 0x04,
      OP_PTRREG      => 0x08,
   OP_LDCS        => 0x80,
   OP_STCS        => 0xC0,
   OP_REPEAT      => 0xA0,
   OP_KEY         => 0xE0,
   OP_KEY_READSIB => 0xE5,

   # UPDI registers
   REG_STATUSA => 0x00,
   REG_STATUSB => 0x01,
   REG_CTRLA   => 0x02,
   REG_CTRLB   => 0x03,
      CTRLB_NACKDIS  => (1<<4),
      CTRLB_CCDETDIS => (1<<3),
      CTRLB_UPDIDIS  => (1<<2),

   REG_ASI_KEY_STATUS => 0x07,
      ASI_KEY_UROWWRITE => (1<<5),
      ASI_KEY_NVMPROG   => (1<<4),
      ASI_KEY_CHIPERASE => (1<<3),
   REG_ASI_RESET_REQ  => 0x08,
      ASI_RESET_REQ_SIGNATURE => 0x59,
   REG_ASI_CTRLA      => 0x09,
   REG_ASI_SYS_CTRLA  => 0x0A,
   REG_ASI_SYS_STATUS => 0x0B,
      ASI_SYS_STATUS_RSTSYS     => (1<<5),
      ASI_SYS_STATUS_INSLEEP    => (1<<4),
      ASI_SYS_STATUS_NVMPROG    => (1<<3),
      ASI_SYS_STATUS_UROWPROG   => (1<<2),
      ASI_SYS_STATUS_LOCKSTATUS => (1<<0),
   REG_ASI_CRC_STATUS => 0x0C,

   # Keys
   KEY_CHIPERASE => "\x65\x73\x61\x72\x45\x4D\x56\x4E",
   KEY_NVMPROG   => "\x20\x67\x6F\x72\x50\x4D\x56\x4E",
};

async sub _break
{
   my $self = shift;

   my $fh = $self->{fh};

   my $was_baud = $fh->getobaud;

   # Writing a 0 at 300baud is sufficient to look like a BREAK
   $fh->setbaud( 300 );
   $fh->print( "\x00" );

   await Future::IO->sysread( $fh, 1 );

   $fh->setbaud( $was_baud );
}

async sub _op_writeread
{
   my $self = shift;
   my ( $write, $readlen ) = @_;

   my $fh = $self->{fh};

   $fh->print( $write );

   my $len = length( $write ) + $readlen;

   my $buf = await Future::IO->sysread_exactly( $fh, $len );

   return substr( $buf, length( $write ) );
}

async sub lds8
{
   my $self = shift;
   my ( $addr ) = @_;

   return unpack "C", await
      $self->_op_writeread( SYNC . pack( "C S<", OP_LDS|OP_ADDR16, $addr ), 1 );
}

async sub sts8
{
   my $self = shift;
   my ( $addr, $val ) = @_;

   my $ack = await
      $self->_op_writeread( SYNC . pack( "C S<", OP_STS|OP_ADDR16, $addr ), 1 );
   $ack eq "\x40" or croak "Expected ACK to STS8";

   $ack = await
      $self->_op_writeread( pack( "C", $val ), 1 );
   $ack eq "\x40" or croak "Expected ACK to STS8 DATA";
}

async sub ld
{
   my $self = shift;
   my ( $addr, $len ) = @_;

   my $ack = await
      $self->_op_writeread( SYNC . pack( "C S<", OP_ST|OP_PTRREG|OP_DATA16, $addr ), 1 );
   $ack eq "\x40" or croak "Expected ACK to ST PTR";

   await
      $self->_op_writeread( SYNC . pack( "C C", OP_REPEAT, $len - 1 ), 0 ) if $len > 1;
   return await
      $self->_op_writeread( SYNC . pack( "C", OP_LD|OP_PTRINC|OP_DATA8 ), $len );
}

async sub st
{
   my $self = shift;
   my ( $addr, $data ) = @_;

   # Count in 16bit words
   my $len = int( length( $data ) / 2 );

   my $ack = await
      $self->_op_writeread( SYNC . pack( "C S<", OP_ST|OP_PTRREG|OP_DATA16, $addr ), 1 );
   $ack eq "\x40" or croak "Expected ACK to ST PTR";

   await
      $self->_op_writeread( SYNC . pack( "C C", OP_REPEAT, $len - 1 ), 0 ) if $len > 1;

   await
      $self->_op_writeread( SYNC . pack( "C", OP_ST|OP_PTRINC|OP_DATA16 ), 0 );

   foreach my $word ( $data =~ m/.{2}/sg ) {
      $ack = await $self->_op_writeread( $word, 1 );
      $ack eq "\x40" or croak "Expected ACK to STR data";
   }

   if( length( $data ) % 2 ) {
      # Final byte
      my $byte = substr $data, 2 * $len, 1;
      await
         $self->_op_writeread( SYNC . pack( "C", OP_ST|OP_PTRINC|OP_DATA8 ), 0 );

      $ack = await $self->_op_writeread( $byte, 1 );
      $ack eq "\x40" or croak "Expected ACK to STR data";
   }
}

async sub ldcs
{
   my $self = shift;
   my ( $reg ) = @_;

   return unpack "C", await
      $self->_op_writeread( SYNC . pack( "C", OP_LDCS | $reg ), 1 )
}

async sub stcs
{
   my $self = shift;
   my ( $reg, $value ) = @_;

   await
      $self->_op_writeread( SYNC . pack( "CC", OP_STCS | $reg, $value ), 0 );
}

async sub key
{
   my $self = shift;
   my ( $key ) = @_;

   length $key == 8 or
      die "Expected 8 byte key\n";

   await
      $self->_op_writeread( SYNC . pack( "C a*", OP_KEY, $key ), 0 );
}

=head2 init_link

   $updi->init_link->get

Initialise the UPDI link for proper communication.

This method must be invoked after the object is constructed, before using any
of the other commands.

=cut

async sub init_link
{
   my $self = shift;

   await $self->_break;

   # We have to disable collision detection or else the chip won't respond
   # properly
   await $self->stcs( REG_CTRLB, CTRLB_CCDETDIS );
}

=head2 read_updirev

   $rev = $updi->read_updirev->get

Reads the C<UPDIREV> field of the C<STATUSA> register.

=cut

async sub read_updirev
{
   my $self = shift;

   return ( await $self->ldcs( REG_STATUSA ) ) >> 4;
}

=head2 read_asi_sys_status

Reads the C<ASI_SYS_STATUS> register.

=cut

async sub read_asi_sys_status
{
   my $self = shift;

   return await $self->ldcs( REG_ASI_SYS_STATUS );
}

=head2 read_sib

   $sib = $updi->read_sib->get

Reads the System Information Block.

This is returned in a HASH reference, containing four keys:

   {
      family       => "tinyAVR",
      nvm_version  => "P:0",
      ocd_version  => "D:0",
      dbg_osc_freq => 3,
   }

=cut

async sub read_sib
{
   my $self = shift;

   my $bytes = await
      $self->_op_writeread( SYNC . pack( "C", OP_KEY_READSIB ), 16 );
   my ( $family, $nvm, $ocd, $dbgosc ) = unpack "A7 x A3 A3 x A1", $bytes;
   return {
      family       => $family,
      nvm_version  => $nvm,
      ocd_version  => $ocd,
      dbg_osc_freq => $dbgosc,
   };
}

=head2 read_signature

   $signature = $updi->read_signature->get

Reads the three signature bytes from the Signature Row of the device. This is
returned as a plain byte string of length 3.

=cut

async sub read_signature
{
   my $self = shift;

   # The ATtiny814 datasheet says
   #   All Atmel microcontrollers have a three-byte signature code which
   #   identifies the device. This code can be read in both serial and parallel
   #   mode, also when the device is locked. The three bytes reside in a
   #   separate address space.
   # So far no attempt at reading signature over UPDI from a locked device has
   # been successful. :(

   return await $self->ld( $self->{partinfo}->baseaddr_sigrow, 3 );
}

=head2 request_reset

   $updi->request_reset( $reset )->get

Sets or clears the system reset request. Typically used to issue a system
reset by momentarilly toggling the request on and off again:

   await $updi->request_reset( 1 );
   await $updi->request_reset( 0 );

=cut

async sub request_reset
{
   my $self = shift;
   my ( $reset ) = @_;

   await $self->stcs( REG_ASI_RESET_REQ, $reset ? ASI_RESET_REQ_SIGNATURE : 0 );
}

=head2 erase_chip

   $updi->erase_chip->get

Requests a full chip erase, waiting until the erase is complete.

After this, the chip will be unlocked.

=cut

async sub erase_chip
{
   my $self = shift;

   await $self->key( KEY_CHIPERASE );

   die "Failed to set CHIPERASE key\n" unless ASI_KEY_CHIPERASE & await $self->ldcs( REG_ASI_KEY_STATUS );

   await $self->request_reset( 1 );
   await $self->request_reset( 0 );

   my $timeout = 50;
   while( --$timeout ) {
      last if not ASI_SYS_STATUS_LOCKSTATUS & await $self->ldcs( REG_ASI_SYS_STATUS );

      await Future::IO->sleep( 0.05 );
   }
   die "Failed to unlock chip\n" if !$timeout;
}

=head2 enable_nvmprog

   $updi->enable_nvmprog->get

Requests the chip to enter NVM programming mode.

=cut

async sub enable_nvmprog
{
   my $self = shift;

   await $self->key( KEY_NVMPROG );

   die "Failed to set NVMPROG key\n" unless ASI_KEY_NVMPROG & await $self->ldcs( REG_ASI_KEY_STATUS );

   await $self->request_reset( 1 );
   await $self->request_reset( 0 );

   my $timeout = 50;
   while( --$timeout ) {
      last if ASI_SYS_STATUS_NVMPROG & await $self->ldcs( REG_ASI_SYS_STATUS );

      await Future::IO->sleep( 0.05 );
   }
}

use constant {
   NVMCTRL_CTRLA  => 0,
      NVMCTRL_CMD_WP   => 1,
      NVMCTRL_CMD_ER   => 2,
      NVMCTRL_CMD_ERWP => 3,
      NVMCTRL_CMD_PBC  => 4,
      NVMCTRL_CMD_CHER => 5,
      NVMCTRL_CMD_EEER => 6,
      NVMCTRL_CMD_WFU  => 7,
   NVMCTRL_CTRLB  => 1,
   NVMCTRL_STATUS => 2,
      NVMCTRL_STATUS_FBUSY => (1<<0),
   NVMCTRL_DATA   => 6,
   NVMCTRL_ADDR   => 8,
};

async sub nvmctrl_command
{
   my $self = shift;
   my ( $cmd ) = @_;

   await $self->sts8( $self->{partinfo}->baseaddr_nvmctrl + NVMCTRL_CTRLA, $cmd );
}

async sub await_nvm_not_busy
{
   my $self = shift;

   my $timeout = 50;
   while( --$timeout ) {
      last if not( NVMCTRL_STATUS_FBUSY & await $self->lds8(
         $self->{partinfo}->baseaddr_nvmctrl + NVMCTRL_STATUS, 1 ) );

      await Future::IO->sleep( 0.01 );
   }
}

=head2 write_nvm_page

   $updi->write_nvm_page( $addr, $data )->get

Writes a single page into NVM flash using the NVM controller.

=cut

async sub write_nvm_page
{
   my $self = shift;
   my ( $addr, $data ) = @_;

   # clear page buffer
   await $self->nvmctrl_command( NVMCTRL_CMD_PBC );
   await $self->await_nvm_not_busy;

   await $self->st( $self->{partinfo}->baseaddr_flash + $addr, $data );

   await $self->nvmctrl_command( NVMCTRL_CMD_WP );
   await $self->await_nvm_not_busy;
}

=head2 write_fuse

   $updi->write_fuse( $idx, $value )->get

Writes a fuse value. C<$idx> is the index of the fuse within the FUSES memory
segment, from 0 onwards.

=cut

async sub write_fuse
{
   my $self = shift;
   my ( $idx, $value ) = @_;

   my $addr = $self->{partinfo}->baseaddr_fuse + $idx;

   my $baseaddr_nvmctrl = $self->{partinfo}->baseaddr_nvmctrl;

   # Oddly, this works but an attempt at STS16 does not. Unsure why
   await $self->sts8 ( $baseaddr_nvmctrl + NVMCTRL_ADDR  , $addr & 0xFF );
   await $self->sts8 ( $baseaddr_nvmctrl + NVMCTRL_ADDR+1, $addr >> 8 );

   await $self->sts8 ( $baseaddr_nvmctrl + NVMCTRL_DATA, $value );

   await $self->nvmctrl_command( NVMCTRL_CMD_WFU );

   await $self->await_nvm_not_busy;
}

=head2 read_fuse

   $value = $updi->read_fuse( $idx )->get

Reads a fuse value. C<$idx> is the index of the fuse within the FUSES memory
segment, from 0 onwards.

=cut

async sub read_fuse
{
   my $self = shift;
   my ( $idx ) = @_;

   my $addr = $self->{partinfo}->baseaddr_fuse + $idx;

   return await $self->lds8( $addr );
}

=head1 SEE ALSO

=over 2

=item *

"AVR UPDI Programming Cable"

An adapter cable to flash firmware onto an AVR microcontroller chip via UPDI,
compatible with this module.

L<https://www.tindie.com/products/16571/>

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

__DATA__
# These data are maintained by ./rebuild-partinfo.pl
# name|signature|baseaddr_nvmctl|baseaddr_fuse|baseaddr_sigrow|baseaddr_flash|pagesize|fuses
ATmega1608|1e9427|0x1000|0x1280|0x1100|0x4000|64|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega1609|1e9426|0x1000|0x1280|0x1100|0x4000|64|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega3208|1e9530|0x1000|0x1280|0x1100|0x4000|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega3209|1e9531|0x1000|0x1280|0x1100|0x4000|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega4808|1e9650|0x1000|0x1280|0x1100|0x4000|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega4809|1e9651|0x1000|0x1280|0x1100|0x4000|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega808|1e9326|0x1000|0x1280|0x1100|0x4000|64|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega809|1e932a|0x1000|0x1280|0x1100|0x4000|64|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1604|1e9425|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1606|1e9424|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1607|1e9423|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1614|1e9422|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1616|1e9421|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1617|1e9420|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny202|1e9123|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny204|1e9122|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny212|1e9121|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny214|1e9120|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3214|1e9520|0x1000|0x1280|0x1100|0x8000|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3216|1e9521|0x1000|0x1280|0x1100|0x8000|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3217|1e9522|0x1000|0x1280|0x1100|0x8000|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny402|1e9227|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny404|1e9226|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny406|1e9225|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny412|1e9223|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny414|1e9222|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny416|1e9221|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny417|1e9220|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny804|1e9325|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny806|1e9324|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny807|1e9323|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny814|1e9322|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny816|1e9321|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny817|1e9320|0x1000|0x1280|0x1100|0x8000|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
