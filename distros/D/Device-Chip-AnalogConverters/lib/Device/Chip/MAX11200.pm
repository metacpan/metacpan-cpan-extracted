#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::MAX11200 0.16;
class Device::Chip::MAX11200
   :isa(Device::Chip);

use Carp;
use Future::AsyncAwait;
use Future::IO;
use Data::Bitfield 0.02 qw( bitfield boolfield enumfield );
use List::Util qw( first );

use constant PROTOCOL => "SPI";

=head1 NAME

C<Device::Chip::MAX11200> - chip driver for F<MAX11200>

=head1 SYNOPSIS

   use Device::Chip::MAX11200;
   use Future::AsyncAwait;

   my $chip = Device::Chip::MAX11200->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->trigger;

   printf "The reading is %d\n", await $chip->read_adc;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a F<Maxim>
F<MAX11200> or F<MAX11210> chip.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 2E6,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 init

   await $chip->init;

Performs startup self-calibration by setting C<NOSCG> and C<NOSCO> to zero
then requesting a calibration cycle.

=cut

async method init ()
{
   await $self->change_config(
      NOSCG => 0,
      NOSCO => 0,
   );

   await $self->selfcal;

   await Future::IO->sleep( 0.25 ); # selfcal takes 200msec (longer at LINEF=50Hz)
}

use constant {
   REG_STAT  => 0,
   REG_CTRL1 => 1,
   REG_CTRL2 => 2,
   REG_CTRL3 => 3,
   REG_DATA  => 4,
   REG_SOC   => 5,
   REG_SGC   => 6,
   REG_SCOC  => 7,
   REG_SCGC  => 8,
};

async method read_register ( $reg, $len = 1 )
{
   my $bytes = await $self->protocol->readwrite(
      pack "C a*", 0xC1 | ( $reg << 1 ), "\0" x $len
   );

   return substr $bytes, 1;
}

async method write_register ( $reg, $val )
{
   await $self->protocol->write(
      pack "C a*", 0xC0 | ( $reg << 1 ), $val
   );
}

my @RATES = qw( 1 2.5 5 10 15 30 60 120 );

use constant {
   CMD_SELFCAL   => 0x10,
   CMD_SYSOCAL   => 0x20,
   CMD_SYSGCAL   => 0x30,
   CMD_POWERDOWN => 0x08,
   CMD_CONV      => 0,
};

async method command ( $cmd )
{
   await $self->protocol->write( pack "C", 0x80 | $cmd );
}

=head2 read_status

   $status = await $chip->read_status;

Returns a C<HASH> reference containing the chip's current status.

   RDY   => 0 | 1
   MSTAT => 0 | 1
   UR    => 0 | 1
   OR    => 0 | 1
   RATE  => 1 | 2.5 | 5 | 10 | 15 | 30 | 60 | 120
   SYSOR => 0 | 1

=cut

bitfield { format => "bytes-LE" }, STAT =>
   RDY   => boolfield(0),
   MSTAT => boolfield(1),
   UR    => boolfield(2),
   OR    => boolfield(3),
   RATE  => enumfield(4, @RATES),
   SYSOR => boolfield(7);

async method read_status ()
{
   my $bytes = await $self->read_register( REG_STAT );

   return unpack_STAT( $bytes );
}

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the chip's current configuration.

   SCYCLE => 0 | 1
   FORMAT => "TWOS_COMP" | "OFFSET"
   SIGBUF => 0 | 1
   REFBUF => 0 | 1
   EXTCLK => 0 | 1
   UB     => "UNIPOLAR" | "BIPOLAR"
   LINEF  => "60Hz" | "50Hz"
   NOSCO  => 0 | 1
   NOSCG  => 0 | 1
   NOSYSO => 0 | 1
   NOSYSG => 0 | 1
   DGAIN  => 1 2 4 8 16  # only valid for the MAX11210

=cut

bitfield { format => "bytes-LE" }, CONFIG =>
   # CTRL1
   SCYCLE => boolfield(1),
   FORMAT => enumfield(2, qw( TWOS_COMP OFFSET )),
   SIGBUF => boolfield(3),
   REFBUF => boolfield(4),
   EXTCLK => boolfield(5),
   UB     => enumfield(6, qw( BIPOLAR UNIPOLAR )),
   LINEF  => enumfield(7, qw( 60Hz 50Hz )),
   # CTRL2 is all GPIO control; we'll do that elsewhere
   # CTRL3
   NOSCO  => boolfield(8+1),
   NOSCG  => boolfield(8+2),
   NOSYSO => boolfield(8+3),
   NOSYSG => boolfield(8+4),
   DGAIN  => enumfield(8+5, qw( 1 2 4 8 16 ));

async method read_config ()
{
   my ( $ctrl1, $ctrl3 ) = await Future->needs_all(
      $self->read_register( REG_CTRL1 ), $self->read_register( REG_CTRL3 )
   );

   return $self->{config} = { unpack_CONFIG( $ctrl1 . $ctrl3 ) };
}

=head2 change_config

   await $chip->change_config( %changes );

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

=cut

async method change_config ( %changes )
{
   my $config = $self->{config} // await $self->read_config;

   $self->{config} = { %$config, %changes };
   my $ctrlb = pack_CONFIG( %{ $self->{config} } );

   await Future->needs_all(
      $self->write_register( REG_CTRL1, substr $ctrlb, 0, 1 ),
      $self->write_register( REG_CTRL3, substr $ctrlb, 1, 1 ),
   );
}

=head2 selfcal

   await $chip->selfcal;

Requests the chip perform a self-calibration.

=cut

async method selfcal ()
{
   await $self->command( CMD_SELFCAL );
}

=head2 syscal_offset

   await $chip->syscal_offset;

Requests the chip perform the offset part of system calibration.

=cut

async method syscal_offset ()
{
   await $self->command( CMD_SYSOCAL );
}

=head2 syscal_gain

   await $chip->syscal_gain;

Requests the chip perform the gain part of system calibration.

=cut

async method syscal_gain ()
{
   await $self->command( CMD_SYSGCAL );
}

=head2 trigger

   await $chip->trigger( $rate );

Requests the chip perform a conversion of the input level, at the given
rate (which must be one of the values specified for the C<RATE> configuration
option); defaulting to the value of L</default_trigger_rate> if not defined.
Once the conversion is complete it can be read using the C<read_adc> method.

=head2 default_trigger_rate

   $rate = $chip->default_trigger_rate
   $chip->default_trigger_rate = $new_rate

Lvalue accessor for the default trigger rate if L</trigger> is invoked without
one. Initialised to 120.

=cut

field $_default_trigger_rate = 120;
method default_trigger_rate :lvalue { $_default_trigger_rate }

async method trigger ( $rate = $_default_trigger_rate )
{
   defined( my $rateidx = first { $RATES[$_] == $rate } 0 .. $#RATES )
      or croak "Unrecognised conversion rate $rate";

   await $self->command( CMD_CONV | $rateidx );
}

=head2 read_adc

   $value = await $chip->read_adc;

Reads the most recent reading from the result register on the tip. This method
should be called after a suitable delay after the L</trigger> method when in
single cycle mode, or at any time when in continuous mode.

The reading is returned directly from the chip as a plain 24-bit integer,
either signed or unsigned as per the C<FORMAT> configuration.

=cut

async method read_adc ()
{
   my $bytes = await $self->read_register( REG_DATA, 3 );

   return unpack "L>", "\0$bytes";
}

=head2 read_adc_ratio

   $ratio = await $chip->read_adc_ratio;

Converts a reading obtained by L</read_adc> into a ratio between -1 and 1,
taking into account the current mode setting of the chip.

=cut

async method read_adc_ratio ()
{
   my ( $value, $config ) = await Future->needs_all(
      $self->read_adc,
      ( $self->{config} ? Future->done( $self->{config} ) : $self->read_config )
   );

   if( $config->{UB} eq "UNIPOLAR" ) {
      # Raw 24bit integer
      return $value / 2**24;
   }
   else {
      if( $config->{FORMAT} eq "TWOS_COMP" ) {
         # Signed integer in twos-complement form
         $value -= 2**24 if $value >= 2**23;
      }
      else {
         # Signed-integer in offset form
         $value -= 2**23;
      }
      return $value / 2**23;
   }
}

=head2 write_gpios

   await $chip->write_gpios( $values, $direction );

=head2 read_gpios

   $values = await $chip->read_gpios;

Sets or reads the values of the GPIO pins as a 4-bit integer. Bits in the
C<$direction> should be high to put the corresponding pin into output mode, or
low to put it into input mode.

As an alternative to these methods, see instead L</gpio_adapter>.

=cut

async method write_gpios ( $values, $dir )
{
   await $self->write_register( REG_CTRL2, pack "C", ( $dir << 4 ) | $values );
}

async method read_gpios ()
{
   my $bytes = await $self->read_register( REG_CTRL2 );

   return 0x0F & unpack "C", $bytes;
}

=head2 Calibration Registers

   $value = await $chip->read_selfcal_offset;
   $value = await $chip->read_selfcal_gain;
   $value = await $chip->read_syscal_offset;
   $value = await $chip->read_syscal_gain;

   await $chip->write_selfcal_offset( $value );
   await $chip->write_selfcal_gain( $value );
   await $chip->write_syscal_offset( $value );
   await $chip->write_syscal_gain( $value );

Reads or writes the values of the calibration registers, as plain 24-bit
integers.

=cut

BEGIN {
   use Object::Pad 0.800 ':experimental(mop)';
   my $mop = Object::Pad::MOP::Class->for_caller;

   foreach (
      [ "selfcal_offset", REG_SCOC ],
      [ "selfcal_gain",   REG_SCGC ],
      [ "syscal_offset",  REG_SOC  ],
      [ "syscal_gain",    REG_SGC  ],
   ) {
      my ( $name, $reg ) = @$_;

      $mop->add_method( "read_$name" => async method () {
         my $bytes = await $self->read_register( $reg, 3 );
         return unpack "I>", "\0" . $bytes;
      } );

      $mop->add_method( "write_$name" => async method ( $value ) {
         await $self->write_register( $reg,
            substr( pack( "I>", $value ), 1 )
         );
      } );
   }
}

=head2 as_gpio_adapter

   $adapter = $chip->as_gpio_adapter

Returns an instance implementing the L<Device::Chip::Adapter> interface,
allowing access to the four GPIO pins via the standard adapter API.

=cut

method as_gpio_adapter
{
   return Device::Chip::MAX11200::_GPIOAdapter->new( chip => $self );
}

class Device::Chip::MAX11200::_GPIOAdapter {
   use Carp;

   field $_chip :param;

   async method make_protocol ( $pname )
   {
      $pname eq "GPIO" or
         croak "Unrecognised protocol name $pname";

      return $self;
   }

   method list_gpios { qw( GPIO1 GPIO2 GPIO3 GPIO4 ) }

   method meta_gpios
   {
      return map {
         Device::Chip::Adapter::GPIODefinition( $_, "rw", 0 )
      } $self->list_gpios;
   }

   field $_dir = "";
   field $_val = "";

   async method write_gpios ( $values )
   {
      foreach my $n ( 1 .. 4 ) {
         defined( my $v = $values->{"GPIO$n"} ) or next;

         vec( $_dir, $n-1, 1 ) = 1;
         vec( $_val, $n-1, 1 ) = $v;
      }

      await $_chip->write_gpios( ord $_val, ord $_dir );
   }

   async method tris_gpios ( $pins )
   {
      my $newdir = $_dir;
      foreach my $pin ( @$pins ) {
         $pin =~ m/^GPIO(\d)/ and $1 >= 1 and $1 <= 4 or
            croak "Unrecognised GPIO pin name $pin";
         my $n = $1;

         vec( $newdir, $n-1, 1 ) = 0;
      }

      if( $newdir ne $_dir ) {
         $_dir = $newdir;
         await $_chip->write_gpios( ord $_val, ord $_dir );
      }
   }

   async method read_gpios ( $pins )
   {
      await $self->tris_gpios( $pins );

      my $read = chr await $_chip->read_gpios;

      my %ret;
      foreach my $pin ( @$pins ) {
         $pin =~ m/^GPIO(\d)/ and my $n = $1;
         $ret{$pin} = vec( $read, $n-1, 1 );
      }

      return \%ret;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
