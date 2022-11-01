#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.66 ':experimental(init_expr)';

package Device::Chip::Sensor 0.25;

use strict;
use warnings;

use experimental 'signatures';
use Object::Pad ':experimental(mop adjust_params)';

use Carp;

=head1 NAME

C<Device::Chip::Sensor> - declarations of sensor readings for C<Device::Chip>

=head1 SYNOPSIS

   class Device::Chip::MySensorChip
      extends Device::Chip;

   use Device::Chip::Sensor -declare;

   ...

   declare_sensor voltage =>
      units     => "volts",
      precision => 3;

   async method read_voltage () {
      ...
   }

=head1 DESCRIPTION

This package provides some helper methods for describing metadata on
L<Device::Chip> drivers that provide sensor values. The resulting metadata
helps to describe the quantities that the sensor chip can measure, and
provides a consistent API for accessing them.

=cut

my %SENSORS_FOR_CLASS;

=head1 CHIP METHODS

When imported into a C<Device::Chip> driver class using the C<-declare> option
the following methods are added to it.

=cut

=head2 list_sensors

   @sensors = $chip->list_sensors;

Returns a list of individual sensor objects. Each object represents a single
sensor reading that can be measured.

=head1 OPTIONAL CHIP METHODS

The following methods may also be provided by the chip driver class if
required. Callers should check they are implemented (e.g. with C<can>) before
attempting to call them.

=head2 initialize_sensors

   await $chip->initialize_sensors;

If the chip requires any special configuration changes, initial calibrations,
startup delay, or other operations before the sensors are available then this
method should perform it. It can presume that the application wishes to
interact with the chip primarily via the sensors API, and thus if required it
can presume particular settings to make this happen.

=head1 SENSOR DECLARATIONS

Sensor metadata is provided by the following function.

=head2 declare_sensor

   declare_sensor $name => %params;

Declares a new sensor object with the given name and parameters.

The following named parameters are recognised:

=over 4

=item type => STRING

Optional. A string specifying what overall type of data is being returned.
Normally this is C<gauge> to indicate a quantity that is measured on every
observation. A type of C<counter> instead indicates that the value will be an
integer giving the total number of times some event has happened - typically
used to count interrupt events from chips.

A convenience function L</declare_sensor_counter> exists for making counters.

=item units => STRING

A string describing the units in which the value is returned. This should be
an empty string for purely abstract counting sensors, or else describe the
measured quantities in physical units (such as C<volts>, C<seconds>,
C<metres>, C<Hz>, ...)

=item precision => INT

The number of decimal places of floating-point accuracy that values should
be printed with. This should be 0 for integer readings.

=item method => STRING or CODE

Optional string or code reference giving the method on the main chip object to
call to obtain a new reading of this sensor's current value. If not provided a
default will be created by prefixing C<"read_"> onto the sensor name.

=item sanity_bounds => ARRAY[ 2 * NUM ]

I<Since version 0.23.>

Optional bounding values to sanity-test reported readings. If a reading is
obtained that is lower than the first value or higher than the second, it is
declared to be out of bounds by the L</read> method. Either bound may be set
to C<undef> to ignore that setting. For example, setting just a lower bound of
zero ensures that any negative values that are obtained are considered out of
the valid range.

=back

=head2 declare_sensor_counter

   declare_sensor_counter $name => %params;

Declares a sensor of the C<counter> type. This will pass C<undef> for the
units and 0 for precision.

=cut

sub import ( @opts )
{
   my $caller = caller;
   declare_into( $caller ) if grep { $_ eq "-declare" } @opts;
}

sub declare_into ( $caller )
{
   my $classmeta = Object::Pad::MOP::Class->for_class( $caller );

   my $sensors = $SENSORS_FOR_CLASS{$classmeta->name} //= [];

   $classmeta->add_method( list_sensors => sub ( $self ) {
      # TODO: some sort of superclass merge?
      return map { $_->bind( $self ) } $sensors->@*;
   } );

   my $declare = sub ( $name, %params ) {
      push $sensors->@*, Device::Chip::Sensor->new(
         name => $name,
         %params,
      );
   };

   no strict 'refs';
   *{"${caller}::declare_sensor"} = $declare;
   *{"${caller}::declare_sensor_counter"} = sub {
      $declare->( @_, type => "counter", units => undef, precision => 0 );
   };
}

class Device::Chip::Sensor;

use Future::AsyncAwait 0.38;

=head1 SENSOR METHODS

Each returned sensor object provides the following methods.

=head2 name

=head2 units

=head2 precision

   $name = $sensor->name;

   $units = $sensor->units;

   $prec = $sensor->precision;

Metadata fields from the sensor's declaration.

=head2 chip

   $chip = $sensor->chip;

The L<Device::Chip> instance this sensor is a part of.

=cut

my %TYPES = (
   gauge   => 1,
   counter => 1,
);

field $_type      :reader :param { "gauge" };
field $_name      :reader :param;
field $_units     :reader :param { undef };
field $_precision :reader :param { 0 };

field $_lbound;
field $_ubound;

field $_method :param { undef };

field $_chip :reader :param { undef };

ADJUST
{
   $TYPES{$_type} or
      croak "Unrecognised sensor type '$_type'";

   $_method //= "read_$_name";
}

ADJUST :params ( :$sanity_bounds = [] )
{
   ( $_lbound, $_ubound ) = $sanity_bounds->@*;
}

method bind ( $chip )
{
   return Device::Chip::Sensor->new(
      chip   => $chip,

      type      => $_type,
      name      => $_name,
      units     => $_units,
      precision => $_precision,
      method    => $_method,
      sanity_bounds => [ $_lbound, $_ubound ],
   );
}

=head2 read

   $value = await $sensor->read;

Performs an actual read operation on the sensor chip to return the currently
measured value.

This method always returns a single scalar value, even if the underlying
method on the sensor chip returned more than one.

If the value obtained from the sensor is outside of the sanity-check bounds
then an exception is thrown instead.

=cut

async method read ()
{
   defined( my $value = scalar await $_chip->$_method() )
      or return undef;

   if( defined $_lbound and $value < $_lbound or
      defined $_ubound and $value > $_ubound ) {
      die sprintf "Reading %s is out of range\n", $self->format( $value );
   }

   return $value;
}

=head2 format

   $string = $sensor->format( $value );

Returns a string by formatting an observed value to the required precision.

=cut

method format ( $value )
{
   return undef if !defined $value;
   return sprintf "%.*f", $_precision, $value;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
