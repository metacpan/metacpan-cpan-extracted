#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::AS3935 0.04;
class Device::Chip::AS3935
   :isa(Device::Chip);

use Device::Chip::Sensor 0.19 -declare;

use Data::Bitfield qw( bitfield boolfield enumfield intfield );
use Future::AsyncAwait;

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::AS3935> - chip driver for F<AS3935>

=head1 SYNOPSIS

   use Device::Chip::AS3935;
   use Future::AsyncAwait;

   my $chip = Device::Chip::AS3935->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   if( ( await $chip->read_int )->{INT_L} ) {
      printf "Lightning detected %dkm away\n", await $chip->read_distance;
   }

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communcation to an F<ams>
F<AS3935> lightning detector chip attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      addr        => 0x02,
      max_bitrate => 400E3,
   );
}

async method initialize_sensors ()
{
   await $self->reset;

   await $self->calibrate_rco;
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 reset

   await $chip->reset;

Sends a reset command to initialise the configuration back to defaults.

=cut

async method reset ()
{
   $self->protocol->write( pack "C C", 0x3C, 0x96 );
}

=head2 calibrate_rco

   await $chip->calibrate_rco;

Sends a calibrate command to request the chip perform its internal RC
oscillator calibration.

=cut

async method calibrate_rco ()
{
   $self->protocol->write( pack "C C", 0x3D, 0x96 );
}

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference of the contents of configuration registers using
fields named from the data sheet.

   AFE_GB       => 0 .. 31
   PWD          => "active" | "powerdown"
   NF_LEV       => 0 .. 7
   WDTH         => 0 .. 15
   CL_STAT      => bool
   MIN_NUM_LIGH => 1 | 5 | 9 | 16
   SREJ         => 0 .. 15
   LCO_FDIV     => 16 | 32 | 64 | 128
   MASK_DIST    => bool
   DISP_LCO     => bool
   DISP_SRCO    => bool
   DISP_TRCO    => bool
   TUN_CAP      => 0 .. 15

Additionally, the following keys are provided calculated from those, as a
convenience.

   afe        => "indoor" | "outdoor"
   noisefloor => int (in units of µVrms)

=head2 change_config

   await $chip->change_config( %changes );

Writes updates to the configuration registers.

=cut

use constant {
   # The data sheet doesn't actually give names to registers, so we'll invent
   # these
   REG_CONFIG0      => 0x00,
   REG_INT          => 0x03,
   REG_DISTANCE     => 0x07,
   REG_CONFIG8      => 0x08,
   REG_CALIB_STATUS => 0x3A,
};

bitfield { format => "bytes-LE" }, CONFIG =>
   # 0x00
   AFE_GB       => intfield ( 0*8+1, 5 ),
   PWD          => enumfield(     0, qw( active powerdown ) ),
   # 0x01
   NF_LEV       => intfield ( 1*8+4, 3 ),
   WDTH         => intfield ( 1*8+0, 4 ),
   # 0x02
   CL_STAT      => boolfield( 2*8+6 ),
   MIN_NUM_LIGH => enumfield( 2*8+4, qw( 1 5 9 16 ) ),
   SREJ         => intfield ( 2*8+0, 4 ),
   # 0x03
   LCO_FDIV     => enumfield( 3*8+6, qw( 16 32 64 128 ) ),
   MASK_DIST    => boolfield( 3*8+5 ),
   # 0x08
   DISP_LCO     => boolfield( 4*8+7 ),
   DISP_SRCO    => boolfield( 4*8+6 ),
   DISP_TRCO    => boolfield( 4*8+5 ),
   TUN_CAP      => intfield ( 4*8+0, 4 ),
   ;

my @NF_MAP_INDOOR  = ( 28, 45, 62, 78, 95, 112, 130, 146 );
my @NF_MAP_OURDOOR = ( 390, 630, 860, 1100, 1140, 1570, 1800, 2000 );

field $_CONFIG;

async method read_config ()
{
   # TODO: second region too
   $_CONFIG //= join "",
      await $self->protocol->write_then_read( ( pack "C", REG_CONFIG0 ), 4 ),
      await $self->protocol->write_then_read( ( pack "C", REG_CONFIG8 ), 1 );

   my %config = unpack_CONFIG( $_CONFIG );

   $config{afe} = $config{AFE_GB};
   $config{afe} = "indoor"  if $config{AFE_GB} == 18;
   $config{afe} = "outdoor" if $config{AFE_GB} == 14;

   my $noisefloor_map;
   $noisefloor_map = \@NF_MAP_INDOOR  if $config{AFE_GB} == 18;
   $noisefloor_map = \@NF_MAP_OURDOOR if $config{AFE_GB} == 14;
   $config{noisefloor} = $noisefloor_map->[ $config{NF_LEV} ] if $noisefloor_map;

   return \%config;
}

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   $config->{$_} = $changes{$_} for keys %changes;

   delete $config->{afe};
   delete $config->{noisefloor};

   my $bytes = pack_CONFIG( %$config );

   if( $_CONFIG ne $bytes ) {
      await $self->protocol->write( pack "C a*", REG_CONFIG0, substr $bytes, 0, 4 );
      await $self->protocol->write( pack "C a*", REG_CONFIG8, substr $bytes, 4, 1 );

      $_CONFIG = $bytes;
   }
}

=head2 read_calib_status

   $status = await $chip->read_calib_status;

Returns a 4-element C<HASH> reference indicating the calibration status:

   TRCO_CALIB_DONE => bool
   TRCO_CALIB_NOK  => bool
   SRCO_CALIB_DONE => bool
   SRCO_CALIB_NOK  => bool

=cut

async method read_calib_status ()
{
   my ( $trco, $srco ) = unpack "C C",
      await $self->protocol->write_then_read( ( pack "C", REG_CALIB_STATUS ), 2 );

   return {
      TRCO_CALIB_DONE => !!( $trco & 0x80 ),
      TRCO_CALIB_NOK  => !!( $trco & 0x40 ),
      SRCO_CALIB_DONE => !!( $srco & 0x80 ),
      SRCO_CALIB_NOK  => !!( $srco & 0x40 ),
   };
}

=head2 read_int

   $ints = await $chip->read_int;

Returns a 3-element C<HASH> reference containing the three interrupt flags:

   INT_NH => bool
   INT_D  => bool
   INT_L  => bool

=cut

async method read_int ()
{
   my $int = unpack "C",
      await $self->protocol->write_then_read( ( pack "C", REG_INT ), 1 );
   $int &= 0x0F;

   return {
      INT_NH => !!( $int & 0x01 ),
      INT_D  => !!( $int & 0x04 ),
      INT_L  => !!( $int & 0x08 ),
   };
}

=head2 read_distance

   $distance = await $chip->read_distance;

Returns an integer giving the estimated lightning distance, in km, or C<undef>
if it is below the detection limit.

=cut

async method read_distance ()
{
   my $distance = unpack "C",
      await $self->protocol->write_then_read( ( pack "C", REG_DISTANCE ), 1 );
   $distance &= 0x3F;

   undef $distance if $distance == 0x3F;

   return $distance;
}

field $_pending_read_int_f;

method next_read_int
{
   return $_pending_read_int_f //= $self->read_int->on_ready( sub { undef $_pending_read_int_f } );
}

foreach ( [ noise_high => "INT_NH" ], [ disturbance => "INT_D" ], [ strike => "INT_L" ] ) {
   my ( $name, $intflag ) = @$_;

   declare_sensor_counter "lightning_${name}_events" =>
      method => async method {
         my $ints = await $self->next_read_int;
         return $ints->{$intflag};
      };
}

declare_sensor lightning_distance =>
   units => "km",
   precision => 0,
   method => "read_distance";

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
