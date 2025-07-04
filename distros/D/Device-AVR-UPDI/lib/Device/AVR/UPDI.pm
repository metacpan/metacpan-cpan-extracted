#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.807 ':experimental(inherit_field)';

package Device::AVR::UPDI 0.18;
class Device::AVR::UPDI :strict(params);

use Carp;

use Future::AsyncAwait;
use Future::IO 0.03; # ->sysread_exactly
use Sublike::Extended 'method';

use File::ShareDir qw( module_dir );
use YAML ();

my $SHAREDIR = module_dir( __PACKAGE__ );

use Object::Pad::ClassAttr::Struct 0.04;

use constant DEBUG => $ENV{UPDI_DEBUG} // 0;

class Device::AVR::UPDI::_PartInfo :Struct {
   field $name;

   field $signature;
   field $baseaddr_nvmctrl;
   field $baseaddr_fuse;
   field $baseaddr_sigrow;

   field $baseaddr_flash;
   field $pagesize_flash;
   field $size_flash;

   field $baseaddr_eeprom;
   field $pagesize_eeprom;
   field $size_eeprom;

   field $fusenames;
}

my %partinfos;
{
   while( readline DATA ) {
      m/^#/ and next;
      chomp;
      my ( $name, $signature, @fields ) = split m/\|/, $_;
      $signature = pack "H*", $signature;
      my $fuses = [ map { length $_ ? $_ : undef } split m/,/, pop @fields ];
      m/^0x/ and $_ = hex $_ for @fields;

      my $partinfo = Device::AVR::UPDI::_PartInfo->new_values( $name, $signature, @fields, $fuses );

      $partinfos{lc $name} = $partinfo;
      $partinfos{"m$1"} = $partinfo if $name =~ m/^ATmega(.*)$/;
      $partinfos{"t$1"} = $partinfo if $name =~ m/^ATtiny(.*)$/;
   }

   close DATA;
}

=head1 NAME

C<Device::AVR::UPDI> - interact with an F<AVR> microcontroller over F<UPDI>

=head1 DESCRIPTION

This module provides a class for interacting with an F<AVR> microcontroller
over the F<UPDI> programming and debug interface. This is used by chips in the
newer F<ATmega> 0-series, or F<ATtiny> 0-series or 1-series, or F<AVR DA> or
F<AVR DB> families.

=head2 Hardware Interface

This code expects to find a serial port connected to the UPDI pin of the
microcontroller as a shared single-wire interface. Suitable hardware to
provide this can be created using a USB-UART adapter, connecting the C<RX>
line directly to the MCU's C<UPDI> pin, and connecting C<TX> via a
current-limiting resistor of 1kohm.

=for highlighter

   +------------+                    +-------------------+
   |         RX-|-------------+      |                   |
   | USB-UART   |             +------|-UPDI              |
   |         TX-|---[ 1k  ]---+      |  ATmega or ATtiny |
   +------------+                    +-------------------|

=cut

=head1 CONSTRUCTORS

=for highlighter language=perl

=cut

=head2 new

   $updi = Device::AVR::UPDI->new( ... );

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
   part => "AVR64DA48"  | "avr64da48"

=item baud => INT

Optional. Overrides the baud rate for communications. Defaults to 115200.

Lower numbers may be useful if communication is unreliable, for example over a
long cable or with high capacitance or noise.

=back

After construction, the link must be initialised by calling L</init_link>
before any of the command methods are used.

=cut

field $_fh;
field $_partinfo :reader;

field $_nvm_version :writer(_set_nvm_version);

ADJUST :params (
   :$fh     = undef,
   :$dev    = undef,
   :$baud //= 115200,
   :$part,
) {
   $_fh = $fh // do {
      require IO::Termios;
      IO::Termios->open( $dev ) or
         die "Unable to open $dev - $!\n";
   };

   $_fh->cfmakeraw();

   # 8bits, Even parity, 2 stop
   $_fh->set_mode( "$baud,8,e,2" );
   $_fh->setflag_clocal( 1 );

   $_fh->autoflush;

   $_partinfo = $partinfos{lc $part} //
      croak "Unrecognised part name $part";
}

field $_reg_ctrla = 0;

=head1 ACCESSORS

=cut

=head2 partinfo

   $partinfo = $updi->partinfo;

Returns the Part Info structure containing base addresses and other parameters
which may be useful for interacting with the chip.

The returned structure provides the following fields

   $name = $partinfo->name;

   $sig = $partinfo->signature;

   $addr = $partinfo->baseaddr_nvmctrl;
   $addr = $partinfo->baseaddr_fuse;
   $addr = $partinfo->baseaddr_flash;
   $addr = $partinfo->baseaddr_eeprom;
   $addr = $partinfo->baseaddr_sigrow;

   $bytes = $partinfo->pagesize_flash;
   $bytes = $partinfo->pagesize_eeprom;
   $bytes = $partinfo->size_flash;
   $bytes = $partinfo->size_eeprom;

   $fusenames = $partinfo->fusenames;

=cut

# generated accessor

=head2 fuseinfo

Returns a data structure containing information about the individual fuse
fields defined by this device.

This is parsed directly from a shipped YAML file; see the files in the
F<share/> directory for more details.

=cut

field $_fuseinfo;

method fuseinfo ()
{
   return $_fuseinfo //= do {
      my $yamlpath = "$SHAREDIR/${\ $self->partinfo->name }.yaml";
      unless( -f $yamlpath ) {
         die "No YAML file found at $yamlpath\n";
      }
      YAML::LoadFile( $yamlpath );
   };
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

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
      OP_ADDR16      => 0x01,
      OP_ADDR24      => 0x02,
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
      CTRLA_IBDLY => (1<<7),
      CTRLA_PARD  => (1<<5),
      CTRLA_DTD   => (1<<4),
      CTRLA_RSD   => (1<<3),
      CTRLA_GTVAL_MASK => 0x07,
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

async method _break ()
{
   my $was_baud = $_fh->getobaud;

   # Writing a 0 at 300baud is sufficient to look like a BREAK
   $_fh->setbaud( 300 );
   $_fh->print( "\x00" );

   await Future->wait_any(
      Future::IO->sysread( $_fh, 1 ),
      Future::IO->sleep( 0.05 )
         ->then_fail( "Timed out waiting for echo of BREAK - is this a UPDI programmer?\n" )
   );

   $_fh->setbaud( $was_baud );
}

async method _op_writeread ( $write, $readlen )
{
   printf STDERR "WR: => %v02X\n", $write if DEBUG > 1;
   await Future::IO->syswrite_exactly( $_fh, $write );

   my $buf = "";
   my $len = length( $write ) + $readlen;

   while( length $buf < $len ) {
      my $what = ( length $buf >= length $write ) ?
         "chip response - is the chip present?" :
         "echo of command - is this a UPDI programmer?";

      $buf .= await Future->wait_any(
         Future::IO->sysread( $_fh, $len - length $buf ),
         Future::IO->sleep( 0.1 )
            ->then_fail( "Timed out waiting for $what\n" )
      );

      my $got = substr( $buf,   0, length $write );
      my $exp = substr( $write, 0, length $buf );

      printf STDERR "RD: <= %v02X\n", $buf if DEBUG > 1;

      die "Received different bytes while waiting to receive echo of command - is this a UPDI programmer?\n"
         if $got ne $exp;
   }

   return substr( $buf, length( $write ) );
}

method _pack_op_addr ( $op, $addr )
{
   return $_nvm_version >= 2
      ? pack( "C S<C", $op|OP_ADDR24<<2, $addr & 0xFFFF, $addr >> 16 )
      : pack( "C S<",  $op|OP_ADDR16<<2, $addr );
}

async method _op_write_expecting_ack ( $op, $write )
{
   if( $_reg_ctrla & CTRLA_RSD ) {
      # No ACK expected
      await $self->_op_writeread( $write, 0 );
   }
   else {
      my $ack = await $self->_op_writeread( $write, 1 );
      $ack eq "\x40" or croak "Expected ACK to $op";
   }
}

async method stptr ( $addr )
{
   my $cmd = $_nvm_version >= 2
      ? pack( "C S<C", OP_ST|OP_PTRREG|OP_ADDR24, $addr & 0xFFFF, $addr >> 16 )
      : pack( "C S<",  OP_ST|OP_PTRREG|OP_ADDR16, $addr );

   await $self->_op_write_expecting_ack( "ST PTR" => SYNC . $cmd );
}

async method lds8 ( $addr )
{
   my $ret = unpack "C", await
      $self->_op_writeread( SYNC . $self->_pack_op_addr( OP_LDS, $addr ), 1 );

   printf STDERR ">> LDS8[%04X] -> %02X\n", $addr, $ret if DEBUG;
   return $ret;
}

async method sts8 ( $addr, $val )
{
   printf STDERR ">> STS8[%04X] = %02X\n", $addr, $val if DEBUG;

   await $self->_op_write_expecting_ack( STS8 =>
      SYNC . $self->_pack_op_addr( OP_STS, $addr ) );

   await $self->_op_write_expecting_ack( "STS8 DATA" =>
      pack( "C", $val ) );
}

async method ld ( $addr, $len )
{
   await $self->stptr( $addr );

   my $ret = "";

   while( $len ) {
      my $chunklen = $len;
      # REPEAT can only do at most 255 repeats
      $chunklen = 256 if $chunklen > 256;

      await
         $self->_op_writeread( SYNC . pack( "C C", OP_REPEAT, $chunklen - 1 ), 0 ) if $chunklen > 1;
      $ret .= await
         $self->_op_writeread( SYNC . pack( "C", OP_LD|OP_PTRINC|OP_DATA8 ), $chunklen );

      $len -= $chunklen;
   }

   printf STDERR ">> LD[%04X] -> %v02X\n", $addr, $ret if DEBUG;
   return $ret;
}

async method st8 ( $addr, $data )
{
   printf STDERR ">> ST[%04X] = %v02X\n", $addr, $data if DEBUG;

   my $len = length( $data );

   await $self->stptr( $addr );

   await
      $self->_op_writeread( SYNC . pack( "C C", OP_REPEAT, $len - 1 ), 0 ) if $len > 1;

   await
      $self->_op_writeread( SYNC . pack( "C", OP_ST|OP_PTRINC|OP_DATA8 ), 0 );

   # If we're in RSD mode we might as well just write all the data in one go
   if( $_reg_ctrla & CTRLA_RSD ) {
      await $self->_op_writeread( $data, 0 )
   }
   else {
      foreach my $byte ( split //, $data ) {
         await $self->_op_write_expecting_ack( "STR data" => $byte );
      }
   }
}

async method st16 ( $addr, $data )
{
   printf STDERR ">> ST[%04X] = %v02X\n", $addr, $data if DEBUG;

   # Count in 16bit words
   my $len = int( length( $data ) / 2 );

   await $self->stptr( $addr );

   await
      $self->_op_writeread( SYNC . pack( "C C", OP_REPEAT, $len - 1 ), 0 ) if $len > 1;

   await
      $self->_op_writeread( SYNC . pack( "C", OP_ST|OP_PTRINC|OP_DATA16 ), 0 );

   # If we're in RSD mode we might as well just write all the data in one go
   if( $_reg_ctrla & CTRLA_RSD ) {
      await $self->_op_writeread( substr( $data, 0, $len*2 ), 0 );
   }
   else {
      foreach my $word ( $data =~ m/.{2}/sg ) {
         await $self->_op_write_expecting_ack( "STR data" => $word );
      }
   }

   if( length( $data ) % 2 ) {
      # Final byte
      my $byte = substr $data, 2 * $len, 1;
      await
         $self->_op_writeread( SYNC . pack( "C", OP_ST|OP_PTRINC|OP_DATA8 ), 0 );

      await $self->_op_write_expecting_ack( "STR data" => $byte );
   }
}

async method ldcs ( $reg )
{
   my $ret = unpack "C", await
      $self->_op_writeread( SYNC . pack( "C", OP_LDCS | $reg ), 1 );

   printf STDERR ">> LDCS[%02X] -> %02X\n", $reg, $ret if DEBUG;
   return $ret;
}

async method stcs ( $reg, $value )
{
   printf STDERR ">> STCS[%02X] = %02X\n", $reg, $value if DEBUG;

   await
      $self->_op_writeread( SYNC . pack( "CC", OP_STCS | $reg, $value ), 0 );
}

async method key ( $key )
{
   length $key == 8 or
      die "Expected 8 byte key\n";

   printf STDERR ">> KEY %v02X\n", $key if DEBUG;

   await
      $self->_op_writeread( SYNC . pack( "C a*", OP_KEY, $key ), 0 );
}

async method set_rsd ( $on )
{
   my $val = $on ? $_reg_ctrla | CTRLA_RSD : $_reg_ctrla & ~CTRLA_RSD;

   await $self->stcs( REG_CTRLA, $_reg_ctrla = $val ) if $_reg_ctrla != $val;
}

=head2 init_link

   await $updi->init_link;

Initialise the UPDI link for proper communication.

This method must be invoked after the object is constructed, before using any
of the other commands.

=cut

async method init_link ()
{
   # Sleep 100msec before sending BREAK in case of attached UPDI 12V pulse hardware
   await Future::IO->sleep( 0.1 );

   await $self->_break;

   # We have to disable collision detection or else the chip won't respond
   # properly
   await $self->stcs( REG_CTRLB, CTRLB_CCDETDIS );

   # Set CTRLA to known state also
   await $self->stcs( REG_CTRLA, $_reg_ctrla = 0 );

   # Read the SIB so we can determine what kind of NVM controller is required
   my $sib = await $self->read_sib;
   $sib->{nvm_version} =~ m/^P:(\d)/ or croak "Unrecognised NVM_VERSION string: $sib->{nvm_version}";
   $_nvm_version = $1;
}

=head2 read_updirev

   $rev = await $updi->read_updirev;

Reads the C<UPDIREV> field of the C<STATUSA> register.

=cut

async method read_updirev ()
{
   return ( await $self->ldcs( REG_STATUSA ) ) >> 4;
}

=head2 read_asi_sys_status

   $status = await $updi->read_asi_sys_status;

Reads the C<ASI_SYS_STATUS> register.

=cut

async method read_asi_sys_status ()
{
   return await $self->ldcs( REG_ASI_SYS_STATUS );
}

=head2 read_sib

   $sib = await $updi->read_sib;

Reads the System Information Block.

This is returned in a HASH reference, containing four keys:

   {
      family       => "tinyAVR",
      nvm_version  => "P:0",
      ocd_version  => "D:0",
      dbg_osc_freq => 3,
   }

=cut

async method read_sib ()
{
   my $bytes = await
      $self->_op_writeread( SYNC . pack( "C", OP_KEY_READSIB ), 16 );
   printf STDERR ">> READSIB -> %v02X\n", $bytes if DEBUG;

   my ( $family, $nvm, $ocd, $dbgosc ) = unpack "A7 x A3 A3 x A1", $bytes;
   return {
      family       => $family,
      nvm_version  => $nvm,
      ocd_version  => $ocd,
      dbg_osc_freq => $dbgosc,
   };
}

=head2 read_signature

   $signature = await $updi->read_signature;

Reads the three signature bytes from the Signature Row of the device. This is
returned as a plain byte string of length 3.

=cut

async method read_signature ()
{
   # The ATtiny814 datasheet says
   #   All Atmel microcontrollers have a three-byte signature code which
   #   identifies the device. This code can be read in both serial and parallel
   #   mode, also when the device is locked. The three bytes reside in a
   #   separate address space.
   # So far no attempt at reading signature over UPDI from a locked device has
   # been successful. :(

   return await $self->ld( $_partinfo->baseaddr_sigrow, 3 );
}

=head2 request_reset

   await $updi->request_reset( $reset );

Sets or clears the system reset request. Typically used to issue a system
reset by momentarilly toggling the request on and off again:

   await $updi->request_reset( 1 );
   await $updi->request_reset( 0 );

=cut

async method request_reset ( $reset )
{
   await $self->stcs( REG_ASI_RESET_REQ, $reset ? ASI_RESET_REQ_SIGNATURE : 0 );
}

=head2 erase_chip

   await $updi->erase_chip;

Requests a full chip erase, waiting until the erase is complete.

After this, the chip will be unlocked.

Takes an optional named argument:

=over 4

=item no_reset => BOOL

If true, does not issue a system reset request after loading the key. This
allows you to load multiple keys at once before sending the reset, which
may be required e.g. to recover from a bad C<SYSCFG0> fuse setting.

   await $updi->erase_chip( no_reset => 1 );
   await $updi->enable_nvmprog;

=back

=cut

async method erase_chip ( :$no_reset = 0 )
{
   await $self->key( KEY_CHIPERASE );

   die "Failed to set CHIPERASE key\n" unless ASI_KEY_CHIPERASE & await $self->ldcs( REG_ASI_KEY_STATUS );

   return if $no_reset;

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

   await $updi->enable_nvmprog;

Requests the chip to enter NVM programming mode.

=cut

async method enable_nvmprog ()
{
   await $self->key( KEY_NVMPROG );

   die "Failed to set NVMPROG key\n" unless ASI_KEY_NVMPROG & await $self->ldcs( REG_ASI_KEY_STATUS );

   await $self->request_reset( 1 );
   await $self->request_reset( 0 );

   my $timeout = 50;
   while( --$timeout ) {
      last if ASI_SYS_STATUS_NVMPROG & await $self->ldcs( REG_ASI_SYS_STATUS );

      await Future::IO->sleep( 0.05 );
   }
   die "Timed out waiting for NVMPROG key to be accepted\n" if !$timeout;
}

field $_nvmctrl;

method nvmctrl ()
{
   return $_nvmctrl if defined $_nvmctrl;

   defined $_nvm_version or
      croak "Must ->init_link before calling ->nvmctrl";

   # ATtiny and ATmega chips claim "P:0"
   return $_nvmctrl = Device::AVR::UPDI::_NVMCtrlv0->new( updi => $self )
      if $_nvm_version == 0;

   # AVR Dx chips claim "P:2"
   return $_nvmctrl = Device::AVR::UPDI::_NVMCtrlv2->new( updi => $self )
      if $_nvm_version == 2;

   croak "Unrecognised NVM version $_nvm_version";
}

=head2 read_flash_page

   $data = await $updi->read_flash_page( $addr, $len );

Reads a single flash page and returns the data. C<$addr> is within the flash
address space.

=cut

async method read_flash_page ( $addr, $len )
{
   return await $self->nvmctrl->read_flash_page( $addr, $len );
}

=head2 write_flash_page

   await $updi->write_flash_page( $addr, $data );

Writes a single flash page into the NVM controller in 16-bit word transfers.
C<$addr> is within the flash address space.

=cut

async method write_flash_page ( $addr, $data )
{
   await $self->nvmctrl->write_flash_page( $addr, $data );
}

=head2 read_eeprom_page

   $data = await $updi->read_eeprom_page( $addr, $len );

Reads a single EEPROM page and returns the data. C<$addr> is within the EEPROM
address space.

=cut

async method read_eeprom_page ( $addr, $len )
{
   return await $self->nvmctrl->read_eeprom_page( $addr, $len );
}

=head2 write_eeprom_page

   await $updi->write_eeprom_page( $addr, $data );

Similar to L</write_flash_page> but issues a combined erase-and-write
command and C<$addr> is within the EEPROM address space.

=cut

async method write_eeprom_page ( $addr, $data )
{
   await $self->nvmctrl->write_eeprom_page( $addr, $data );
}

=head2 write_fuse

   await $updi->write_fuse( $idx, $value );

Writes a fuse value. C<$idx> is the index of the fuse within the FUSES memory
segment, from 0 onwards.

=cut

async method write_fuse ( $idx, $value )
{
   await $self->nvmctrl->write_fuse( $idx, $value );
}

=head2 read_fuse

   $value = await $updi->read_fuse( $idx );

Reads a fuse value. C<$idx> is the index of the fuse within the FUSES memory
segment, from 0 onwards.

=cut

async method read_fuse ( $idx )
{
   my $addr = $_partinfo->baseaddr_fuse + $idx;

   return await $self->lds8( $addr );
}

class # hide from indexer
   Device::AVR::UPDI::_NVMCtrl {

   use constant {
      NVMCTRL_CTRLA  => 0,
      NVMCTRL_STATUS => 2,
         NVMCTRL_STATUS_FBUSY => (1<<0),
   };

   field $_updi     :param :inheritable;
   field $_partinfo :inheritable;

   ADJUST
   {
      $_partinfo = $_updi->partinfo;
   }

   async method nvmctrl_command ( $cmd )
   {
      await $_updi->sts8( $_partinfo->baseaddr_nvmctrl + NVMCTRL_CTRLA, $cmd );
   }

   async method await_nvm_not_busy ()
   {
      my $timeout = 50;
      while( --$timeout ) {
         last if not( NVMCTRL_STATUS_FBUSY & await $_updi->lds8(
            $_partinfo->baseaddr_nvmctrl + NVMCTRL_STATUS ) );

         await Future::IO->sleep( 0.01 );
      }
   }
}

class # hide from indexer
   Device::AVR::UPDI::_NVMCtrlv0 {

   inherit Device::AVR::UPDI::_NVMCtrl qw( $_updi $_partinfo );

   use Carp;

   use constant {
      # Command values
         NVMCTRL_CMD_WP   => 1,
         NVMCTRL_CMD_ER   => 2,
         NVMCTRL_CMD_ERWP => 3,
         NVMCTRL_CMD_PBC  => 4,
         NVMCTRL_CMD_CHER => 5,
         NVMCTRL_CMD_EEER => 6,
         NVMCTRL_CMD_WFU  => 7,
      NVMCTRL_CTRLB  => 1,
      NVMCTRL_DATA   => 6,
      NVMCTRL_ADDR   => 8,
   };

   async method read_flash_page ( $addr, $len )
   {
      return await $_updi->ld( $_partinfo->baseaddr_flash + $addr, $len );
   }

   async method read_eeprom_page ( $addr, $len )
   {
      return await $_updi->ld( $_partinfo->baseaddr_eeprom + $addr, $len );
   }

   async method _write_page ( $addr, $data, $wordsize, $cmd )
   {
      # clear page buffer
      await $self->nvmctrl_command( NVMCTRL_CMD_PBC );
      await $self->await_nvm_not_busy;

      # Disable response sig for speed
      await $_updi->set_rsd( 1 );

      if( $wordsize == 8 ) {
         await $_updi->st8( $addr, $data );
      }
      elsif( $wordsize == 16 ) {
         await $_updi->st16( $addr, $data );
      }
      else {
         croak "Invalid word size";
      }

      # Re-enable response sig again
      await $_updi->set_rsd( 0 );

      await $self->nvmctrl_command( $cmd );
      await $self->await_nvm_not_busy;
   }

   async method write_flash_page ( $addr, $data )
   {
      await $self->_write_page( $_partinfo->baseaddr_flash + $addr, $data, 16, NVMCTRL_CMD_WP );
   }

   async method write_eeprom_page ( $addr, $data )
   {
      await $self->_write_page( $_partinfo->baseaddr_eeprom + $addr, $data, 8, NVMCTRL_CMD_ERWP );
   }

   async method write_fuse ( $idx, $value )
   {
      my $addr = $_partinfo->baseaddr_fuse + $idx;

      my $baseaddr = $_partinfo->baseaddr_nvmctrl;

      # Oddly, this works but an attempt at STS16 does not. Unsure why
      await $_updi->sts8 ( $baseaddr + NVMCTRL_ADDR  , $addr & 0xFF );
      await $_updi->sts8 ( $baseaddr + NVMCTRL_ADDR+1, $addr >> 8 );

      await $_updi->sts8 ( $baseaddr + NVMCTRL_DATA, $value );

      await $self->nvmctrl_command( NVMCTRL_CMD_WFU );

      await $self->await_nvm_not_busy;
   }
}

class # hide from indexer
   Device::AVR::UPDI::_NVMCtrlv2 {

   inherit Device::AVR::UPDI::_NVMCtrl qw( $_updi $_partinfo );

   use Carp;

   use constant {
      # Command values
         NVMCTRL_CMD_NOCMD  => 0x00,
         NVMCTRL_CMD_FLWR   => 0x02,
         NVMCTRL_CMD_EEERWR => 0x13,

      NVMCTRL_CTRLB => 1,
   };

   async method _set_flmap ( $bank )
   {
      await $_updi->sts8( $_partinfo->baseaddr_nvmctrl + NVMCTRL_CTRLB, $bank << 4 );
   }

   async method read_flash_page ( $addr, $len )
   {
      await $self->_set_flmap( $addr >> 15 );
      $addr &= 0x7FFF;

      return await $_updi->ld( $_partinfo->baseaddr_flash + $addr, $len );
   }

   async method read_eeprom_page ( $addr, $len )
   {
      return await $_updi->ld( $_partinfo->baseaddr_eeprom + $addr, $len );
   }

   async method _write_page ( $addr, $data, $wordsize, $cmd )
   {
      # set page write mode
      await $self->nvmctrl_command( $cmd );

      # Disable response sig for speed on long data
      #  (no point on single-byte fuses)
      await $_updi->set_rsd( 1 ) if length $data > 1;

      if( $wordsize == 8 ) {
         await $_updi->st8( $addr, $data );
      }
      elsif( $wordsize == 16 ) {
         await $_updi->st16( $addr, $data );
      }
      else {
         croak "Invalid word size";
      }

      # Re-enable response sig again
      await $_updi->set_rsd( 0 );

      await $self->await_nvm_not_busy;

      # clear command
      await $self->nvmctrl_command( NVMCTRL_CMD_NOCMD );
      await $self->await_nvm_not_busy;
   }

   async method write_flash_page ( $addr, $data )
   {
      await $self->_set_flmap( $addr >> 15 );
      $addr &= 0x7FFF;

      await $self->_write_page( $_partinfo->baseaddr_flash + $addr, $data, 16, NVMCTRL_CMD_FLWR );
   }

   async method write_eeprom_page ( $addr, $data )
   {
      await $self->_write_page( $_partinfo->baseaddr_eeprom + $addr, $data, 8, NVMCTRL_CMD_EEERWR );
   }

   async method write_fuse ( $idx, $value )
   {
      # Fuses are written by pretending it's EEPROM
      my $data = pack "C", $value;

      await $self->_write_page( $_partinfo->baseaddr_fuse + $idx, $data, 8, NVMCTRL_CMD_EEERWR );
   }
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
# These data are maintained by rebuild-partinfo.pl
# name|signature|baseaddr_nvmctl|baseaddr_fuse|baseaddr_sigrow|baseaddr_flash|pagesize_flash|size_flash|baseaddr_eeprom|pagesize_eeprom|size_eeprom|fuses
ATmega808|1e9326|0x1000|0x1280|0x1100|0x4000|64|8192|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega809|1e932a|0x1000|0x1280|0x1100|0x4000|64|8192|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega1608|1e9427|0x1000|0x1280|0x1100|0x4000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega1609|1e9426|0x1000|0x1280|0x1100|0x4000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega3208|1e9530|0x1000|0x1280|0x1100|0x4000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega3209|1e9531|0x1000|0x1280|0x1100|0x4000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega4808|1e9650|0x1000|0x1280|0x1100|0x4000|128|49152|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATmega4809|1e9651|0x1000|0x1280|0x1100|0x4000|128|49152|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny202|1e9123|0x1000|0x1280|0x1100|0x8000|64|2048|0x1400|32|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny204|1e9122|0x1000|0x1280|0x1100|0x8000|64|2048|0x1400|32|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny212|1e9121|0x1000|0x1280|0x1100|0x8000|64|2048|0x1400|32|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny214|1e9120|0x1000|0x1280|0x1100|0x8000|64|2048|0x1400|32|64|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny402|1e9227|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny404|1e9226|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny406|1e9225|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny412|1e9223|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny414|1e9222|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny416|1e9221|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny417|1e9220|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny424|1e922c|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny426|1e922b|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny427|1e922a|0x1000|0x1280|0x1100|0x8000|64|4096|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny804|1e9325|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny806|1e9324|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny807|1e9323|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny814|1e9322|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny816|1e9321|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny817|1e9320|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny824|1e9329|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny826|1e9328|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny827|1e9327|0x1000|0x1280|0x1100|0x8000|64|8192|0x1400|32|128|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1604|1e9425|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1606|1e9424|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1607|1e9423|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1614|1e9422|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1616|1e9421|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1617|1e9420|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1624|1e942a|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1626|1e9429|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny1627|1e9428|0x1000|0x1280|0x1100|0x8000|64|16384|0x1400|32|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3214|1e9520|0x1000|0x1280|0x1100|0x8000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3216|1e9521|0x1000|0x1280|0x1100|0x8000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3217|1e9522|0x1000|0x1280|0x1100|0x8000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,TCD0CFG,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3224|1e9528|0x1000|0x1280|0x1100|0x8000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3226|1e9527|0x1000|0x1280|0x1100|0x8000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
ATtiny3227|1e9526|0x1000|0x1280|0x1100|0x8000|128|32768|0x1400|64|256|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,APPEND,BOOTEND
AVR32DA28|1e9534|0x1000|0x1050|0x1100|0x8000|512|32768|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR32DA32|1e9533|0x1000|0x1050|0x1100|0x8000|512|32768|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR32DA48|1e9532|0x1000|0x1050|0x1100|0x8000|512|32768|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR32DB28|1e9537|0x1000|0x1050|0x1100|0x8000|512|32768|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR32DB32|1e9536|0x1000|0x1050|0x1100|0x8000|512|32768|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR32DB48|1e9535|0x1000|0x1050|0x1100|0x8000|512|32768|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DA28|1e9615|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DA32|1e9614|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DA48|1e9613|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DA64|1e9612|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DB28|1e9619|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DB32|1e9618|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DB48|1e9617|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR64DB64|1e9616|0x1000|0x1050|0x1100|0x8000|512|65536|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DA28|1e970a|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DA32|1e9709|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DA48|1e9708|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DA64|1e9707|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DB28|1e970e|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DB32|1e970d|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DB48|1e970c|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
AVR128DB64|1e970b|0x1000|0x1050|0x1100|0x8000|512|131072|0x1400|1|512|WDTCFG,BODCFG,OSCCFG,,,SYSCFG0,SYSCFG1,CODESIZE,BOOTSIZE
