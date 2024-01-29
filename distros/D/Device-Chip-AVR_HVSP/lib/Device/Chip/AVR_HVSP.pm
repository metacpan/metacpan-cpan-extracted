#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::AVR_HVSP 0.08;
class Device::Chip::AVR_HVSP
   :isa(Device::Chip);

use Carp;

use Future::AsyncAwait;

use Object::Pad::ClassAttr::Struct 0.05;

use constant PROTOCOL => "GPIO";

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

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

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

field %_pins;

async method mount ( $adapter, %params )
{
   if( my $pins = $DEFAULT_PINS{ref $adapter} ) {
      %params = ( %$pins, %params );
   }

   foreach my $pin (qw( sdi sii sci sdo hv )) {
      defined $params{$pin} or croak "Require a pin assignment for '$pin'" ;

      $_pins{$pin} = $params{$pin};
   }

   await $self->SUPER::mount( $adapter, %params );

   await $self->protocol->write_gpios( {
      $_pins{sdi} => 0,
      $_pins{sii} => 0,
      $_pins{sci} => 0,
   });

   # Set input
   await $self->protocol->tris_gpios( [ $_pins{sdo} ] );
}

=head2 start

   await $chip->start;

Powers up the device, reads and checks the signature, ensuring it is a
recognised chip.

This method leaves the chip powered up with +5V on Vcc and +12V on RESET. Use
the C<power>, C<hv_power> or C<all_power> methods to turn these off if it is
not required again immediately.

=cut

class Device::Chip::AVR_HVSP::_PartInfo :Struct(readonly)
{
   field $signature;
   field $flash_words;
   field $flash_pagesize;
   field $eeprom_words;
   field $eeprom_pagesize;
   field $has_efuse;
}
sub PartInfo { Device::Chip::AVR_HVSP::_PartInfo->new_values( @_ ) }

class Device::Chip::AVR_HVSP::_MemoryInfo :Struct(readonly)
{
   field $wordsize;
   field $pagesize;
   field $words;
   field $can_write;
}
sub MemoryInfo { Device::Chip::AVR_HVSP::_MemoryInfo->new_values( @_ ) }

my %PARTS;
{
   local $_;
   while( <DATA> ) {
      my ( $name, $data ) = m/^(\S+)\s*=\s*(.*?)\s*$/ or next;
      $PARTS{$name} = PartInfo( split /\s+/, $data );
   }
}

field $_partname :reader;
field $_partinfo;
field @_memories;

async method start ()
{
   await $self->all_power(1);

   my $sig = uc unpack "H*", await $self->read_signature;

   my $partinfo;
   my $part;
   ( $partinfo = $PARTS{$_} )->signature eq $sig and $part = $_, last
      for keys %PARTS;

   defined $part or die "Unrecognised signature $sig\n";

   $_partname = $part;
   $_partinfo = $partinfo;

   @_memories = (
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
   );

   return $self;
}

=head2 stop

   await $chip->stop;

Shut down power to the device.

=cut

async method stop ()
{
   await $self->all_power(0);
}

=head2 power

   await $chip->power( $on );

Controls +5V to the Vcc pin of the F<ATtiny> chip.

=cut

async method power ( $on )
{
   await $self->protocol->power( $on );
}

=head2 hv_power

   await $chip->hv_power( $on );

Controls +12V to the RESET pin of the F<ATtiny> chip.

=cut

async method hv_power ( $on )
{
   await $self->protocol->write_gpios( { $_pins{hv} => $on } );
}

=head2 all_power

   await $chip->all_power( $on );

Controls both +5V and +12V supplies at once. The +12V supply is turned on last
but off first, ensuring the correct HVSP-RESET sequence is applied to the
chip.

=cut

async method all_power ( $on )
{
   # Allow power to settle before turning on +12V on AUX
   # Normal serial line overheads should allow enough time here

   if( $on ) {
      await $self->power(1);
      await $self->hv_power(1);
   }
   else {
      await $self->hv_power(0);
      await $self->power(0);
   }
}

=head2 $name = $chip->partname

Returns the name of the chip whose signature was detected by the C<start>
method.

=cut

# :reader

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

method memory_info ( $name )
{
   $_memories[$_*2] eq $name and return $_memories[$_*2 + 1]
      for 0 .. $#_memories/2;

   die "$_partname does not have a $name memory";
}

=head2 %memories = $avr->memory_infos

Returns a key/value list of all the known device memories.

=cut

method memory_infos ()
{
   return @_memories;
}

=head2 $fuseinfo = $avr->fuseinfo

Returns a L<Device::Chip::AVR_HVSP::FuseInfo> instance containing information
on the fuses in the attached device type.

=cut

method fuseinfo ()
{
   require Device::Chip::AVR_HVSP::FuseInfo;
   return Device::Chip::AVR_HVSP::FuseInfo->for_part( $self->partname );
}

async method _transfer ( $sdi, $sii )
{
   my $SCI = $_pins{sci};
   my $SDI = $_pins{sdi};
   my $SII = $_pins{sii};
   my $SDO = $_pins{sdo};

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

   my @f;
   foreach my $i ( 0 .. 10 ) {
      my $mask = $i < 8 ? (1 << 7-$i) : 0;

      push @f, $proto->write_gpios( { $SCI => 1 } );

      if( !$mask ) {
         push @f, $proto->write_gpios( { $SCI => 0 } );
         next;
      }

      # TODO: this used to be
      #   $mode->writeread
      # on the BusPirate version
      push @f,
         $proto->write_gpios( {
            $SDI => ( $sdi & $mask ),
            $SII => ( $sii & $mask ),
            $SCI => 0
         } ),

         $proto->read_gpios( [ $SDO ] )->on_done( sub ( $v ) {
            $sdo |= $mask if $v->{$SDO};
         });
   }

   await Future->needs_all( @f );

   return $sdo;
}

async method _await_SDO_high ()
{
   my $SDO = $_pins{sdo};

   my $proto = $self->protocol;

   my $count = 50;
   while(1) {
      $count-- or die "Timeout waiting for device to ACK";

      last if ( await $proto->read_gpios( [ $SDO ] ) )->{$SDO};
   }
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

=head2 chip_erase

   await $avr->chip_erase;

Performs an entire chip erase. This will clear the flash and EEPROM memories,
before resetting the lock bits. It does not affect the fuses.

=cut

async method chip_erase ()
{
   await $self->_transfer( CMD_CE, HVSP_CMD );

   await $self->_transfer( 0, HVSP_WLB );
   await $self->_transfer( 0, HVSP_WLB|HVSP_ORM );

   await $self->_await_SDO_high;
}

=head2 read_signature

   $bytes = await $avr->read_signature;

Reads the three device signature bytes and returns them in as a single binary
string.

=cut

async method read_signature ()
{
   await $self->_transfer( CMD_RSIG, HVSP_CMD );

   my @sig;
   foreach my $byte ( 0 .. 2 ) {
      await $self->_transfer( $byte, HVSP_LLA );
      await $self->_transfer( 0, HVSP_RSIG );
      push @sig, await $self->_transfer( 0, HVSP_RSIG|HVSP_ORM );
   }

   return pack "C*", @sig;
}

=head2 read_calibration

   $byte = await $avr->read_calibration;

Reads the calibration byte.

=cut

async method read_calibration ()
{
   await $self->_transfer( CMD_ROSC, HVSP_CMD );

   await $self->_transfer( 0, HVSP_LLA );
   await $self->_transfer( 0, HVSP_ROSC );
   my $val = await $self->_transfer( 0, HVSP_ROSC|HVSP_ORM );

   return chr $val;
}

=head2 read_lock

   $byte = await $avr->read_lock;

Reads the lock byte.

=cut

async method read_lock ()
{
   await $self->_transfer( CMD_RLOCK, HVSP_CMD );

   await $self->_transfer( 0, HVSP_RLCK );
   my $val = await $self->_transfer( 0, HVSP_RLCK|HVSP_ORM );

   return chr( $val & 3 );
}

=head2 write_lock

   await $avr->write_lock( $byte );

Writes the lock byte.

=cut

async method write_lock ( $byte )
{
   await $self->_transfer( CMD_WLOCK, HVSP_CMD );

   await $self->_transfer( ( ord $byte ) & 3, HVSP_LLD );
   await $self->_transfer( 0, HVSP_WLCK );
   await $self->_transfer( 0, HVSP_WLCK|HVSP_ORM );

   await $self->_await_SDO_high;
}

=head2 read_fuse_byte

   $int = await $avr->read_fuse_byte( $fuse );

Reads one of the fuse bytes C<lfuse>, C<hfuse>, C<efuse>, returning an
integer.

=cut

my %SII_FOR_FUSE_READ = (
   lfuse => HVSP_RFU0,
   hfuse => HVSP_RFU1,
   efuse => HVSP_RFU2,
);

async method read_fuse_byte ( $fuse )
{
   my $sii = $SII_FOR_FUSE_READ{$fuse} or croak "Unrecognised fuse type '$fuse'";

   $fuse eq "efuse" and !$_partinfo->has_efuse and
      croak "This part does not have an 'efuse'";

   await $self->_transfer( CMD_RFUSE, HVSP_CMD );

   await $self->_transfer( 0, $sii );
   return await $self->_transfer( 0, $sii|HVSP_ORM );
}

=head2 write_fuse_byte

   await $avr->write_fuse_byte( $fuse, $byte );

Writes one of the fuse bytes C<lfuse>, C<hfuse>, C<efuse> from an integer.

=cut

my %SII_FOR_FUSE_WRITE = (
   lfuse => HVSP_WFU0,
   hfuse => HVSP_WFU1,
   efuse => HVSP_WFU2,
);

async method write_fuse_byte ( $fuse, $byte )
{
   my $sii = $SII_FOR_FUSE_WRITE{$fuse} or croak "Unrecognised fuse type '$fuse'";

   $fuse eq "efuse" and !$_partinfo->has_efuse and
      croak "This part does not have an 'efuse'";

   await $self->_transfer( CMD_WFUSE, HVSP_CMD );

   await $self->_transfer( $byte, HVSP_LLD );
   await $self->_transfer( 0, $sii );
   await $self->_transfer( 0, $sii|HVSP_ORM );

   await $self->_await_SDO_high;
}

=head2 read_lfuse

=head2 read_hfuse

=head2 read_efuse

   $byte = await $avr->read_lfuse;

   $byte = await $avr->read_hfuse;

   $byte = await $avr->read_efuse;

Convenient shortcuts to reading the low, high and extended fuses directly,
returning a byte.

=head2 write_lfuse

=head2 write_hfuse

=head2 write_efuse

   await $avr->write_lfuse( $byte );

   await $avr->write_hfuse( $byte );

   await $avr->write_efuse( $byte );

Convenient shortcuts for writing the low, high and extended fuses directly,
from a byte.

=cut

BEGIN {
   use Object::Pad 0.800 ':experimental(mop)';
   my $meta = Object::Pad::MOP::Class->for_caller;

   foreach my $fuse (qw( lfuse hfuse efuse )) {
      $meta->add_method( "read_$fuse" => async method {
         return chr await $self->read_fuse_byte( $fuse );
      } );
      $meta->add_method( "write_$fuse" => async method {
         await $self->write_fuse_byte( $fuse, ord $_[0] );
      } );
   }
}

=head2 read_flash

   $bytes = await $avr->read_flash( %args );

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

async method read_flash ( %opts )
{
   my $partinfo = $_partinfo or croak "Cannot ->read_flash of an unrecognised part";

   my $start = $opts{start} // 0;
   my $stop  = $opts{stop}  //
      $opts{bytes} ? $start + ( $opts{bytes}/2 ) : $partinfo->flash_words;

   my $bytes = "";

   await $self->_transfer( CMD_RFLASH, HVSP_CMD );
   my $cur_ahi = -1;

   foreach my $addr ( $start .. $stop - 1 ) {
      my $alo = $addr & 0xff;
      my $ahi = $addr >> 8;

      await $self->_transfer( $alo, HVSP_LLA );

      await $self->_transfer( $cur_ahi = $ahi, HVSP_LHA ) if $cur_ahi != $ahi;

      await $self->_transfer( 0, HVSP_RLB );
      $bytes .= chr await $self->_transfer( 0, HVSP_RLB|HVSP_ORM );

      await $self->_transfer( 0, HVSP_RHB );
      $bytes .= chr await $self->_transfer( 0, HVSP_RHB|HVSP_ORM );
   }

   return $bytes;
}

=head2 write_flash

   await $avr->write_flash( $bytes );

Writes the flash memory from the binary string.

=cut

async method write_flash ( $bytes )
{
   my $partinfo = $_partinfo or croak "Cannot ->write_flash of an unrecognised part";
   my $nbytes_page = $partinfo->flash_pagesize * 2; # words are 2 bytes

   croak "Cannot write - too large" if length $bytes > $partinfo->flash_words * 2;

   await $self->_transfer( CMD_WFLASH, HVSP_CMD );

   my @chunks = $bytes =~ m/(.{1,$nbytes_page})/gs;
   my $addr = 0;

   foreach my $chunk ( @chunks ) {
      my $thisaddr = $addr;
      $addr += $partinfo->flash_pagesize;

      await $self->_write_flash_page( $chunk, $thisaddr );
   }

   await $self->_transfer( 0, HVSP_CMD );
}

async method _write_flash_page ( $bytes, $baseaddr )
{
   foreach my $idx ( 0 .. length($bytes)/2 - 1 ) {
      my $addr = $baseaddr + $idx;
      my $byte_lo = substr $bytes, $idx*2, 1;
      my $byte_hi = substr $bytes, $idx*2 + 1, 1;

      # Datasheet disagrees with the byte value written in the final
      # instruction. Datasheet says 6C even though the OR mask would yield
      # the value 6E. It turns out emperically that either value works fine
      # so for neatness of following other code patterns, we use 6E here.

      await $self->_transfer( $addr & 0xff, HVSP_LLA );
      await $self->_transfer( ord $byte_lo, HVSP_LLD );
      await $self->_transfer( 0, HVSP_PLL );
      await $self->_transfer( 0, HVSP_PLL|HVSP_ORM );
      await $self->_transfer( ord $byte_hi, HVSP_LHD );
      await $self->_transfer( 0, HVSP_PLH );
      await $self->_transfer( 0, HVSP_PLH|HVSP_ORM );
   }

   await $self->_transfer( $baseaddr >> 8, HVSP_LHA );
   await $self->_transfer( 0, HVSP_WLB );
   await $self->_transfer( 0, HVSP_WLB|HVSP_ORM );
   await $self->_await_SDO_high;
}

=head2 read_eeprom

   $bytes = await $avr->read_eeprom( %args );

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

async method read_eeprom ( %opts )
{
   my $partinfo = $_partinfo or croak "Cannot ->read_eeprom of an unrecognised part";

   my $start = $opts{start} // 0;
   my $stop  = $opts{stop}  //
      $opts{bytes} ? $start + $opts{bytes} : $partinfo->eeprom_words;

   my $bytes = "";

   await $self->_transfer( CMD_REEP, HVSP_CMD );

   my $cur_ahi = -1;

   foreach my $addr ( $start .. $stop - 1 ) {
      my $alo = $addr & 0xff;
      my $ahi = $addr >> 8;

      await $self->_transfer( $alo, HVSP_LLA );

      await $self->_transfer( $cur_ahi = $ahi, HVSP_LHA ) if $cur_ahi != $ahi;

      await $self->_transfer( 0, HVSP_REEP );
      $bytes .= chr await $self->_transfer( 0, HVSP_REEP|HVSP_ORM );
   }

   return $bytes;
}

=head2 write_eeprom

   await $avr->write_eeprom( $bytes );

Writes the EEPROM memory from the binary string.

=cut

async method write_eeprom ( $bytes )
{
   my $partinfo = $_partinfo or croak "Cannot ->write_eeprom of an unrecognised part";

   croak "Cannot write - too large" if length $bytes > $partinfo->eeprom_words;

   my $nwords_page = $partinfo->eeprom_pagesize;

   await $self->_transfer( CMD_WEEP, HVSP_CMD );

   my @chunks = $bytes =~ m/(.{1,$nwords_page})/gs;
   my $addr = 0;

   foreach my $chunk ( @chunks ) {
      my $thisaddr = $addr;
      $addr += $nwords_page;

      await $self->_write_eeprom_page( $chunk, $thisaddr )
   }

   await $self->_transfer( 0, HVSP_CMD );
}

async method _write_eeprom_page ( $bytes, $baseaddr )
{
   foreach my $idx ( 0 .. length($bytes) - 1 ) {
      my $addr = $baseaddr + $idx;
      my $byte = substr $bytes, $idx, 1;

      # Datasheet disagrees with the byte value written in the final
      # instruction. Datasheet says 6C even though the OR mask would yield
      # the value 6E. It turns out emperically that either value works fine
      # so for neatness of following other code patterns, we use 6E here.

      await $self->_transfer( $addr & 0xff, HVSP_LLA );
      await $self->_transfer( $addr >> 8, HVSP_LHA );
      await $self->_transfer( ord $byte, HVSP_LLD );
      await $self->_transfer( 0, HVSP_PLL );
      await $self->_transfer( 0, HVSP_PLL|HVSP_ORM );
   }

   await $self->_transfer( 0, HVSP_WLB );
   await $self->_transfer( 0, HVSP_WLB|HVSP_ORM );
   await $self->_await_SDO_high;
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
