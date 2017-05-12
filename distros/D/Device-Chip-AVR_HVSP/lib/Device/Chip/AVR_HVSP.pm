#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2016 -- leonerd@leonerd.org.uk

package Device::Chip::AVR_HVSP;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.04';

use Carp;

use Future::Utils qw( repeat );
use Struct::Dumb qw( readonly_struct );

use constant PROTOCOL => "GPIO";

readonly_struct PartInfo   => [qw( signature flash_words flash_pagesize eeprom_words eeprom_pagesize has_efuse )];
readonly_struct MemoryInfo => [qw( wordsize pagesize words can_write )];

=head1 NAME

C<Device::Chip::AVR_HVSP> - high-voltage serial programming for F<AVR> chips

=head1 DESCRIPTION

This L<Device::Chip> subclass allows interaction with an F<AVR>
microcontroller of the F<ATtiny> family in high-voltage serial programming
(HVSP) mode. It is particularly useful for configuring fuses or working with a
chip with the C<RSTDISBL> fuse programmed, because in such cases a regular ISP
programmer cannot be used.

=head2 CONNECTIONS

To use this module you will need to make connections to the pins of the
F<ATtiny> chip:

  ATtiny | tiny84 | tiny85
  -------+--------+-------
     SDO |      9 |      7
     SII |      8 |      6
     SDI |      7 |      5
     SCI |      2 |      2
   RESET |      4 |      1
     Vcc |      1 |      8
     GND |     14 |      4

This module recognises the following kinds of adapter and automatically
assigns default pin connections for likely configurations:

  Bus Pirate | Sparkfun | Seeed    |:| ATtiny
             |  cable   |  cable   |:|
  -----------+----------+----------+-+-------
  MISO       | brown    | black    |:|    SDO
  CS         | red      | white    |:|    SII
  MOSI       | orange   | grey     |:|    SDI
  CLK        | yellow   | purple   |:|    SCI
  AUX        | green    | blue     |:| HV control
  +5V        | grey     | orange   |:|    Vcc
  GND        | black    | brown    |:|    GND

Z<>

  FTDI |:| ATtiny
  -----+-+-------
  D0   |:|    SCI
  D1   |:|    SDI
  D2   |:|    SDO
  D3   |:|    SII
  D4   |:| HV control

For other kinds of adapter, use the named parameters to the L</mount> method
to tell the chip driver which F<ATtiny> pin is connected to what GPIO line.

The C<HV control> line from the adapter will need to be able to control a +12V
supply to the C<RESET> pin of the F<ATtiny> chip. It should be active-high,
and can be achieved by a two-stage NPN-then-PNP transistor arrangement.

Additionally, the C<SDO> pin and the C<PA0> to C<PA2> pins of 14-pin devices
will need a pull-down to ground of around 100Ohm to 1kOhm.

=cut

=head1 MOUNT PARAMETERS

=head2 sdi, sii, sci, sdo

The names of GPIO lines on the adapter that are connected to the HVSP signal
pins of the F<ATtiny> chip.

=head2 hv

The name of the GPIO line on the adapter that is connected to the 12V power
supply control.

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

# TODO: Perhaps make a Future::Mutex object out of this
sub _enter_mutex
{
   my $self = shift;
   my ( $code ) = @_;

   my $oldmtx = $self->{mutex} // Future->done( $self );
   $self->{mutex} = my $newmtx = Future->new;

   $oldmtx->then( $code )
      ->then_with_f( sub {
         my $f = shift;
         $newmtx->done( $self );
         $f
      });
}

my %DEFAULT_PINS = (
   'Device::Chip::Adapter::BusPirate' => {
      sdi => "MOSI",
      sii => "CS",
      sci => "CLK",
      sdo => "MISO",
      hv  => "AUX",
   },

   'Device::Chip::Adapter::FTDI' => {
      sdi => "D1",
      sii => "D3",
      sci => "D0",
      sdo => "D2",
      hv  => "D4",
   },

   # For unit testing this is convenient
   'Test::Device::Chip::Adapter' => {
      map { $_ => $_ } qw( sdi sii sci sdo hv )
   },
);

sub mount
{
   my $self = shift;
   my ( $adapter, %params ) = @_;

   if( my $pins = $DEFAULT_PINS{ref $adapter} ) {
      %params = ( %$pins, %params );
   }

   foreach my $pin (qw( sdi sii sci sdo hv )) {
      defined $params{$pin} or croak "Require a pin assignment for '$pin'" ;

      $self->{$pin} = $params{$pin};
   }

   $self->SUPER::mount( @_ )
      ->then( sub {
         $self->protocol->write_gpios( {
            $self->{sdi} => 0,
            $self->{sii} => 0,
            $self->{sci} => 0,
         });
      })
      ->then( sub {
         # Set input
         $self->protocol->tris_gpios( [ $self->{sdo} ] );
      });
}

=head2 $chip->start->get

Powers up the device, reads and checks the signature, ensuring it is a
recognised chip.

This method leaves the chip powered up with +5V on Vcc and +12V on RESET. Use
the C<power>, C<hv_power> or C<all_power> methods to turn these off if it is
not required again immediately.

=cut

my %PARTS;
{
   local $_;
   while( <DATA> ) {
      my ( $name, $data ) = m/^(\S+)\s*=\s*(.*?)\s*$/ or next;
      $PARTS{$name} = PartInfo( split /\s+/, $data );
   }
}

sub start
{
   my $self = shift;

   $self->all_power(1)->then( sub {
      $self->read_signature;
   })->then( sub {
      my ( $sig ) = @_;
      $sig = uc unpack "H*", $sig;

      my $partinfo;
      my $part;
      ( $partinfo = $PARTS{$_} )->signature eq $sig and $part = $_, last
         for keys %PARTS;

      defined $part or return Future->fail( "Unrecognised signature $sig" );

      $self->{part}     = $part;
      $self->{partinfo} = $partinfo;

      # ARRAYref so we keep this nice order
      $self->{memories} = [
         #                          ws ps nw wr
         signature   => MemoryInfo(  8, 3, 3, 0 ),
         calibration => MemoryInfo(  8, 1, 1, 0 ),
         lock        => MemoryInfo(  8, 1, 1, 1 ),
         lfuse       => MemoryInfo(  8, 1, 1, 1 ),
         hfuse       => MemoryInfo(  8, 1, 1, 1 ),
         ( $partinfo->has_efuse ?
            ( efuse  => MemoryInfo(  8, 1, 1, 1 ) ) :
            () ),
         flash       => MemoryInfo( 16, $partinfo->flash_pagesize, $partinfo->flash_words, 1 ),
         eeprom      => MemoryInfo(  8, $partinfo->eeprom_pagesize, $partinfo->eeprom_words, 1 ),
      ];

      return Future->done( $self );
   });
}

=head2 $chip->stop->get

Shut down power to the device.

=cut

sub stop
{
   my $self = shift;
   $self->all_power(0);
}

=head2 $chip->power( $on )->get

Controls +5V to the Vcc pin of the F<ATtiny> chip.

=cut

sub power
{
   my $self = shift;
   $self->protocol->power( @_ );
}

=head2 $chip->hv_power( $on )->get

Controls +12V to the RESET pin of the F<ATtiny> chip.

=cut

sub hv_power
{
   my $self = shift;
   my ( $on ) = @_;

   $self->protocol->write_gpios( { $self->{hv} => $on } );
}

=head2 $chip->all_power( $on )->get

Controls both +5V and +12V supplies at once. The +12V supply is turned on last
but off first, ensuring the correct HVSP-RESET sequence is applied to the
chip.

=cut

sub all_power
{
   my $self = shift;
   my ( $on ) = @_;

   # Allow power to settle before turning on +12V on AUX
   # Normal serial line overheads should allow enough time here

   $on
      ? $self->power(1)->then( sub { $self->hv_power(1) } )
      : $self->hv_power(0)->then( sub { $self->power(0) } );
}

=head2 $name = $chip->partname

Returns the name of the chip whose signature was detected by the C<start>
method.

=cut

sub partname
{
   my $self = shift;
   return $self->{part};
}

=head2 $memory = $avr->memory_info( $name )

Returns a memory info structure giving details about the named memory for the
attached part. The following memory names are recognised:

 signature calibration lock lfuse hfuse efuse flash eeprom

(Note that the F<ATtiny13> has no C<efuse> memory).

The structure will respond to the following methods:

=over 4

=item * wordsize

Returns number of bits per word. This will be 8 for the byte-oriented
memories, but 16 for the main program flash.

=item * pagesize

Returns the number of words per page; the smallest amount that can be
written in one go.

=item * words

Returns the total number of words that are available.

=item * can_write

Returns true if the memory type can be written (in general; this does not take
into account the lock bits that might futher restrict a particular chip).

=back

=cut

sub memory_info
{
   my $self = shift;
   my ( $name ) = @_;

   my $memories = $self->{memories};
   $memories->[$_*2] eq $name and return $memories->[$_*2 + 1]
      for 0 .. $#$memories/2;

   die "$self->{part} does not have a $name memory";
}

=head2 %memories = $avr->memory_infos

Returns a key/value list of all the known device memories.

=cut

sub memory_infos
{
   my $self = shift;
   return @{ $self->{memories} };
}

=head2 $fuseinfo = $avr->fuseinfo

Returns a L<Device::Chip::AVR_HVSP::FuseInfo> instance containing information
on the fuses in the attached device type.

=cut

sub fuseinfo
{
   my $self = shift;

   require Device::Chip::AVR_HVSP::FuseInfo;
   return Device::Chip::AVR_HVSP::FuseInfo->for_part( $self->partname );
}

sub _transfer
{
   my $self = shift;

   my ( $sdi, $sii ) = @_;

   my $SCI = $self->{sci};
   my $SDI = $self->{sdi};
   my $SII = $self->{sii};
   my $SDO = $self->{sdo};

   my $sdo = 0;
   my $proto = $self->protocol;

   # A "byte" transfer consists of 11 clock transitions; idle low. Each bit is
   # clocked in from SDO on the falling edge of clocks 0 to 7, but clocked out
   # of SDI and SII on clocks 1 to 8.
   # We'll therefore toggle the clock 11 times; on each of the first 8 clocks
   # we raise it, then simultaneously lower it, writing out the next out bits
   # and reading in the input.
   # Serial transfer is MSB first in both directions
   #
   # We cheat massively here and rely on pipeline ordering of the actual
   # ->write calls, by writing all 22 of the underlying bit transitions to the
   # underlying device, then waiting on all 11 reads to come back.

   Future->needs_all( map {
      my $mask = $_ < 8 ? (1 << 7-$_) : 0;

      Future->needs_all(
         $proto->write_gpios( { $SCI => 1 } ),

         $mask ?
            (
               # TODO: this used to be
               #   $mode->writeread
               # on the BusPirate version
               Future->needs_all(
                  $proto->write_gpios( {
                     $SDI => ( $sdi & $mask ),
                     $SII => ( $sii & $mask ),
                     $SCI => 0
                  } )->then_done(),

                  $proto->read_gpios( [ $SDO ] )
               )->on_done( sub {
                  my ( $v ) = @_;
                  $sdo |= $mask if $v->{$SDO};
               })
            )
               : $proto->write_gpios( { $SCI => 0 } )
      )
   } 0 .. 10 )
      ->then( sub { Future->done( $sdo ) } );
}

sub _await_SDO_high
{
   my $self = shift;

   my $SDO = $self->{sdo};

   my $proto = $self->protocol;

   my $count = 50;
   repeat {
      $count-- or return Future->fail( "Timeout waiting for device to ACK" );

      $proto->read_gpios( [ $SDO ] )
   } until => sub { $_[0]->failure or $_[0]->get->{$SDO} };
}

# The AVR datasheet on HVSP does not name any of these operations, only
# giving them bit patterns. We'll use the names invented by RikusW. See also
#   https://sites.google.com/site/megau2s/

use constant {
   # SII values
   HVSP_CMD  => 0x4C, # Command
   HVSP_LLA  => 0x0C, # Load Lo Address
   HVSP_LHA  => 0x1C, # Load Hi Address
   HVSP_LLD  => 0x2C, # Load Lo Data
   HVSP_LHD  => 0x3C, # Load Hi Data
   HVSP_WLB  => 0x64, # Write Lo Byte = WRL = WFU0
   HVSP_WHB  => 0x74, # Write Hi Byte = WRH = WFU1
   HVSP_WFU2 => 0x66, # Write Extended Fuse
   HVSP_RLB  => 0x68, # Read Lo Byte
   HVSP_RHB  => 0x78, # Read Hi Byte
   HVSP_RSIG => 0x68, # Read Signature
   HVSP_RFU0 => 0x68, # Read Low Fuse
   HVSP_RFU1 => 0x7A, # Read High Fuse
   HVSP_RFU2 => 0x6A, # Read Extended Fuse
   HVSP_REEP => 0x68, # Read EEPROM
   HVSP_ROSC => 0x78, # Read Oscillator calibration
   HVSP_RLCK => 0x78, # Read Lock
   HVSP_PLH  => 0x7D, # Page Latch Hi
   HVSP_PLL  => 0x6D, # Page Latch Lo
   HVSP_ORM  => 0x0C, # OR mask for SII to pulse actual read/write operation

   # HVSP_CMD Commands
   CMD_CE     => 0x80, # Chip Erase
   CMD_WFUSE  => 0x40, # Write Fuse
   CMD_WLOCK  => 0x20, # Write Lock
   CMD_WFLASH => 0x10, # Write FLASH
   CMD_WEEP   => 0x11, # Write EEPROM
   CMD_RSIG   => 0x08, # Read Signature
   CMD_RFUSE  => 0x04, # Read Fuse
   CMD_RFLASH => 0x02, # Read FLASH
   CMD_REEP   => 0x03, # Read EEPROM
   CMD_ROSC   => 0x08, # Read Oscillator calibration
   CMD_RLOCK  => 0x04, # Read Lock
};
# Some synonyms not found in the AVR ctrlstack software
use constant {
   HVSP_WLCK => HVSP_WLB, # Write Lock
   HVSP_WFU0 => HVSP_WLB, # Write Low Fuse
   HVSP_WFU1 => HVSP_WHB, # Write High Fuse
};

=head2 $avr->chip_erase->get

Performs an entire chip erase. This will clear the flash and EEPROM memories,
before resetting the lock bits. It does not affect the fuses.

=cut

sub chip_erase
{
   my $self = shift;

   $self->_transfer( CMD_CE, HVSP_CMD )
      ->then( sub { $self->_transfer( 0, HVSP_WLB ) })
      ->then( sub { $self->_transfer( 0, HVSP_WLB|HVSP_ORM ) })
      ->then( sub { $self->_await_SDO_high });
}

=head2 $bytes = $avr->read_signature->get

Reads the three device signature bytes and returns them in as a single binary
string.

=cut

sub read_signature
{
   my $self = shift;

   $self->_transfer( CMD_RSIG, HVSP_CMD )->then( sub {
      my @sig;
      repeat {
         my $byte = shift;
         $self->_transfer( $byte, HVSP_LLA )
            ->then( sub { $self->_transfer( 0, HVSP_RSIG ) } )
            ->then( sub { $self->_transfer( 0, HVSP_RSIG|HVSP_ORM ) } )
            ->on_done( sub { $sig[$byte] = shift; } );
      } foreach => [ 0 .. 2 ],
        otherwise => sub { Future->done( pack "C*", @sig ) };
   })
}

=head2 $byte = $avr->read_calibration->get

Reads the calibration byte.

=cut

sub read_calibration
{
   my $self = shift;

   $self->_transfer( CMD_ROSC, HVSP_CMD )
      ->then( sub { $self->_transfer( 0, HVSP_LLA ) } )
      ->then( sub { $self->_transfer( 0, HVSP_ROSC ) } )
      ->then( sub { $self->_transfer( 0, HVSP_ROSC|HVSP_ORM ) } )
      ->then( sub {
         Future->done( chr $_[0] )
      });
}

=head2 $byte = $avr->read_lock->get

Reads the lock byte.

=cut

sub read_lock
{
   my $self = shift;

   $self->_transfer( CMD_RLOCK, HVSP_CMD )
      ->then( sub { $self->_transfer( 0, HVSP_RLCK ) } )
      ->then( sub { $self->_transfer( 0, HVSP_RLCK|HVSP_ORM ) } )
      ->then( sub {
         my ( $byte ) = @_;
         Future->done( chr( $byte & 3 ) );
      });
}

=head2 $avr->write_lock( $byte )->get

Writes the lock byte.

=cut

sub write_lock
{
   my $self = shift;
   my ( $byte ) = @_;

   $self->_transfer( CMD_WLOCK, HVSP_CMD )
      ->then( sub { $self->_transfer( ( ord $byte ) & 3, HVSP_LLD ) })
      ->then( sub { $self->_transfer( 0, HVSP_WLCK ) })
      ->then( sub { $self->_transfer( 0, HVSP_WLCK|HVSP_ORM ) })
      ->then( sub { $self->_await_SDO_high });
}

=head2 $int = $avr->read_fuse_byte( $fuse )->get

Reads one of the fuse bytes C<lfuse>, C<hfuse>, C<efuse>, returning an
integer.

=cut

my %SII_FOR_FUSE_READ = (
   lfuse => HVSP_RFU0,
   hfuse => HVSP_RFU1,
   efuse => HVSP_RFU2,
);

sub read_fuse_byte
{
   my $self = shift;
   my ( $fuse ) = @_;

   my $sii = $SII_FOR_FUSE_READ{$fuse} or croak "Unrecognised fuse type '$fuse'";

   $fuse eq "efuse" and !$self->{partinfo}->has_efuse and
      croak "This part does not have an 'efuse'";

   $self->_transfer( CMD_RFUSE, HVSP_CMD )
      ->then( sub { $self->_transfer( 0, $sii ) } )
      ->then( sub { $self->_transfer( 0, $sii|HVSP_ORM ) } )
}

=head2 $avr->write_fuse_byte( $fuse, $byte )->get

Writes one of the fuse bytes C<lfuse>, C<hfuse>, C<efuse> from an integer.

=cut

my %SII_FOR_FUSE_WRITE = (
   lfuse => HVSP_WFU0,
   hfuse => HVSP_WFU1,
   efuse => HVSP_WFU2,
);

sub write_fuse_byte
{
   my $self = shift;
   my ( $fuse, $byte ) = @_;

   my $sii = $SII_FOR_FUSE_WRITE{$fuse} or croak "Unrecognised fuse type '$fuse'";

   $fuse eq "efuse" and !$self->{partinfo}->has_efuse and
      croak "This part does not have an 'efuse'";

   $self->_transfer( CMD_WFUSE, HVSP_CMD )
      ->then( sub { $self->_transfer( $byte, HVSP_LLD ) })
      ->then( sub { $self->_transfer( 0, $sii ) })
      ->then( sub { $self->_transfer( 0, $sii|HVSP_ORM ) })
      ->then( sub { $self->_await_SDO_high });
}

=head2 $byte = $avr->read_lfuse->get

=head2 $byte = $avr->read_hfuse->get

=head2 $byte = $avr->read_efuse->get

Convenient shortcuts to reading the low, high and extended fuses directly,
returning a byte.

=head2 $avr->write_lfuse( $byte )->get

=head2 $avr->write_hfuse( $byte )->get

=head2 $avr->write_efuse( $byte )->get

Convenient shortcuts for writing the low, high and extended fuses directly,
from a byte.

=cut

foreach my $fuse (qw( lfuse hfuse efuse )) {
   no strict 'refs';
   *{"read_$fuse"} = sub {
      shift->read_fuse_byte( $fuse )
         ->then( sub { Future->done( chr $_[0] ) });
   };
   *{"write_$fuse"} = sub {
      $_[0]->write_fuse_byte( $fuse, ord $_[1] );
   };
}

=head2 $bytes = $avr->read_flash( %args )->get

Reads a range of the flash memory and returns it as a binary string.

Takes the following optional arguments:

=over 4

=item start => INT

=item stop => INT

Address range to read. If omitted, reads the entire memory.

=item bytes => INT

Alternative to C<stop>; gives the nubmer of bytes (i.e. not words of flash)
to read.

=back

=cut

sub read_flash
{
   my $self = shift;
   my %opts = @_;

   my $partinfo = $self->{partinfo} or croak "Cannot ->read_flash of an unrecognised part";

   my $start = $opts{start} // 0;
   my $stop  = $opts{stop}  //
      $opts{bytes} ? $start + ( $opts{bytes}/2 ) : $partinfo->flash_words;

   my $bytes = "";

   $self->_transfer( CMD_RFLASH, HVSP_CMD )->then( sub {
      my $cur_ahi = -1;

      repeat {
         my ( $addr ) = @_;
         my $alo = $addr & 0xff;
         my $ahi = $addr >> 8;

         $self->_transfer( $alo, HVSP_LLA )
            ->then( sub { $cur_ahi == $ahi ? Future->done
                                           : $self->_transfer( $cur_ahi = $ahi, HVSP_LHA ) })
            ->then( sub { $self->_transfer( 0, HVSP_RLB ) })
            ->then( sub { $self->_transfer( 0, HVSP_RLB|HVSP_ORM ) })
            ->then( sub { $bytes .= chr $_[0];
                          $self->_transfer( 0, HVSP_RHB ) })
            ->then( sub { $self->_transfer( 0, HVSP_RHB|HVSP_ORM ) })
            ->then( sub { $bytes .= chr $_[0];
                          Future->done; });
      } foreach => [ $start .. $stop - 1 ],
        otherwise => sub { Future->done( $bytes ) };
   });
}

=head2 $avr->write_flash( $bytes )->get

Writes the flash memory from the binary string.

=cut

sub write_flash
{
   my $self = shift;
   my ( $bytes ) = @_;

   my $partinfo = $self->{partinfo} or croak "Cannot ->write_flash of an unrecognised part";
   my $nbytes_page = $partinfo->flash_pagesize * 2; # words are 2 bytes

   croak "Cannot write - too large" if length $bytes > $partinfo->flash_words * 2;

   $self->_transfer( CMD_WFLASH, HVSP_CMD )->then( sub {
      my @chunks = $bytes =~ m/(.{1,$nbytes_page})/gs;
      my $addr = 0;

      repeat {
         my $thisaddr = $addr;
         $addr += $partinfo->flash_pagesize;

         $self->_write_flash_page( $_[0], $thisaddr )
      } foreach => \@chunks;
   })
      ->then( sub { $self->_transfer( 0, HVSP_CMD ) });
}

sub _write_flash_page
{
   my $self = shift;
   my ( $bytes, $baseaddr ) = @_;

   (
      repeat {
         my $addr = $baseaddr + $_[0];
         my $byte_lo = substr $bytes, $_[0]*2, 1;
         my $byte_hi = substr $bytes, $_[0]*2 + 1, 1;

         # Datasheet disagrees with the byte value written in the final
         # instruction. Datasheet says 6C even though the OR mask would yield
         # the value 6E. It turns out emperically that either value works fine
         # so for neatness of following other code patterns, we use 6E here.

         $self->_transfer( $addr & 0xff, HVSP_LLA )
            ->then( sub { $self->_transfer( ord $byte_lo, HVSP_LLD ) })
            ->then( sub { $self->_transfer( 0, HVSP_PLL ) })
            ->then( sub { $self->_transfer( 0, HVSP_PLL|HVSP_ORM ) })
            ->then( sub { $self->_transfer( ord $byte_hi, HVSP_LHD ) })
            ->then( sub { $self->_transfer( 0, HVSP_PLH ) })
            ->then( sub { $self->_transfer( 0, HVSP_PLH|HVSP_ORM ) })
      } foreach => [ 0 .. length($bytes)/2 - 1 ]
   )
      ->then( sub { $self->_transfer( $baseaddr >> 8, HVSP_LHA ) })
      ->then( sub { $self->_transfer( 0, HVSP_WLB ) })
      ->then( sub { $self->_transfer( 0, HVSP_WLB|HVSP_ORM ) })
      ->then( sub { $self->_await_SDO_high });
}

=head2 $bytes = $avr->read_eeprom( %args )->get

Reads a range of the EEPROM memory and returns it as a binary string.

Takes the following optional arguments:

=over 4

=item start => INT

=item stop => INT

Address range to read. If omitted, reads the entire memory.

=item bytes => INT

Alternative to C<stop>; gives the nubmer of bytes to read.

=back

=cut

sub read_eeprom
{
   my $self = shift;
   my %opts = @_;

   my $partinfo = $self->{partinfo} or croak "Cannot ->read_eeprom of an unrecognised part";

   my $start = $opts{start} // 0;
   my $stop  = $opts{stop}  //
      $opts{bytes} ? $start + $opts{bytes} : $partinfo->eeprom_words;

   my $bytes = "";

   $self->_transfer( CMD_REEP, HVSP_CMD )->then( sub {
      my $cur_ahi = -1;

      repeat {
         my ( $addr ) = @_;
         my $alo = $addr & 0xff;
         my $ahi = $addr >> 8;

         $self->_transfer( $alo, HVSP_LLA )
            ->then( sub { $cur_ahi == $ahi ? Future->done
                                           : $self->_transfer( $cur_ahi = $ahi, HVSP_LHA ) } )
            ->then( sub { $self->_transfer( 0, HVSP_REEP ) } )
            ->then( sub { $self->_transfer( 0, HVSP_REEP|HVSP_ORM ) } )
            ->then( sub { $bytes .= chr $_[0];
                          Future->done; });
      } foreach => [ $start .. $stop - 1 ],
        otherwise => sub { Future->done( $bytes ) };
   });
}

=head2 $avr->write_eeprom( $bytes )->get

Writes the EEPROM memory from the binary string.

=cut

sub write_eeprom
{
   my $self = shift;
   my ( $bytes ) = @_;

   my $partinfo = $self->{partinfo} or croak "Cannot ->write_eeprom of an unrecognised part";

   croak "Cannot write - too large" if length $bytes > $partinfo->eeprom_words;

   my $nwords_page = $partinfo->eeprom_pagesize;

   $self->_transfer( CMD_WEEP, HVSP_CMD )->then( sub {
      my @chunks = $bytes =~ m/(.{1,$nwords_page})/gs;
      my $addr = 0;

      repeat {
         my $thisaddr = $addr;
         $addr += $nwords_page;

         $self->_write_eeprom_page( $_[0], $thisaddr )
      } foreach => \@chunks;
   })
      ->then( sub { $self->_transfer( 0, HVSP_CMD ) });
}

sub _write_eeprom_page
{
   my $self = shift;
   my ( $bytes, $baseaddr ) = @_;

   (
      repeat {
         my $addr = $baseaddr + $_[0];
         my $byte = substr $bytes, $_[0], 1;

         # Datasheet disagrees with the byte value written in the final
         # instruction. Datasheet says 6C even though the OR mask would yield
         # the value 6E. It turns out emperically that either value works fine
         # so for neatness of following other code patterns, we use 6E here.

         $self->_transfer( $addr & 0xff, HVSP_LLA )
            ->then( sub { $self->_transfer( $addr >> 8, HVSP_LHA ) })
            ->then( sub { $self->_transfer( ord $byte, HVSP_LLD ) })
            ->then( sub { $self->_transfer( 0, HVSP_PLL ) })
            ->then( sub { $self->_transfer( 0, HVSP_PLL|HVSP_ORM ) })
      } foreach => [ 0 .. length($bytes) - 1 ]
   )
      ->then( sub { $self->_transfer( 0, HVSP_WLB ) })
      ->then( sub { $self->_transfer( 0, HVSP_WLB|HVSP_ORM ) })
      ->then( sub { $self->_await_SDO_high });
}

=head1 SEE ALSO

=over 4

=item *

L<http://dangerousprototypes.com/2014/10/27/high-voltage-serial-programming-for-avr-chips-with-the-bus-pirate/> -
High voltage serial programming for AVR chips with the Bus Pirate.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

__DATA__
# name       = Sig    Flash sz EEPROM sz efuse
ATA5702M322  = 1E9569 32768 16   2304 16 0
ATA5782      = 1E9565 16384 32   1152 16 0
ATA5831      = 1E9561 16384 32   1152 16 0
ATA5832      = 1E9562 16384 32   1152 16 0
ATA5833      = 1E9563 16384 32   1152 16 0
ATmega16HVA  = 1E940C  8192 64    256  4 0
ATmega64HVE2 = 1E9610 32768 64   1024  4 0
ATmega8HVA   = 1E9310  4096 64    256  4 0
ATtiny13     = 1E9007   512 16     64  4 0
ATtiny24     = 1E910B  1024 16    128  4 1
ATtiny25     = 1E9108  1024 16    128  4 1
ATtiny44     = 1E9207  2048 32    256  4 1
ATtiny441    = 1E9215  2048  8    256  4 1
ATtiny45     = 1E9206  2048 32    256  4 1
ATtiny84     = 1E930C  4096 32    512  4 1
ATtiny841    = 1E9315  4096  8    512  4 1
ATtiny85     = 1E930B  4096 32    512  4 1
