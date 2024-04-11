#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2021 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::BusPirate::Mode 0.25;
class Device::BusPirate::Mode;

use Carp;

use Future::AsyncAwait;

use constant PIRATE_DEBUG => $ENV{PIRATE_DEBUG} // 0;

use constant {
   CONF_CS     => 0x01,
   CONF_AUX    => 0x02,
   CONF_PULLUP => 0x04,
   CONF_POWER  => 0x08,
};

=head1 NAME

C<Device::BusPirate::Mode> - base class for C<Device::BusPirate> modes

=head1 DESCRIPTION

The following methods are implemented by all the various mode subclasses.

=cut

field $_pirate :reader :param;

field $_cs     = 0;
field $_power  = 0;
field $_pullup = 0;
field $_aux    = 0;

=head1 METHODS

The following methods documented with C<await> expressions L<Future> instances.

=cut

=head2 pirate

   $pirate = $mode->pirate;

Returns the underlying L<Device::BusPirate> instance.

=cut

# generated accessor

async method _start_mode_and_await ( $send, $await )
{
   my $pirate = $self->pirate;

   $pirate->write( $send );
   my $buf = await $pirate->read( length $await, "start mode" );

   return $buf if $buf eq $await;
   die "Expected '$await' response but got '$buf'";
}

=head2 power

   await $mode->power( $power );

Enable or disable the C<VREG> 5V and 3.3V power outputs.

=cut

method power ( $on )
{
   $_power = !!$on;
   $self->_update_peripherals;
}

=head2 pullup

   await $mode->pullup( $pullup );

Enable or disable the IO pin pullup resistors from C<Vpu>. These are connected
to the C<MISO>, C<CLK>, C<MOSI> and C<CS> pins.

=cut

method pullup ( $on )
{
   $_pullup = !!$on;
   $self->_update_peripherals;
}

=head2 aux

   await $mode->aux( $aux );

Set the C<AUX> output pin level.

=cut

method aux ( $on )
{
   $_aux = !!$on;
   $self->_update_peripherals;
}

=head2 cs

   await $mode->cs( $cs );

Set the C<CS> output pin level.

=cut

# For SPI subclass
method _set_cs { $_cs = shift }

method cs ( $on )
{
   $_cs = !!$on;
   $self->_update_peripherals;
}

method _update_peripherals
{
   $self->pirate->write_expect_ack( chr( 0x40 |
      ( $_power  ? CONF_POWER  : 0 ) |
      ( $_pullup ? CONF_PULLUP : 0 ) |
      ( $_aux    ? CONF_AUX    : 0 ) |
      ( $_cs     ? CONF_CS     : 0 ) ), "_update_peripherals" );
}

=head2 set_pwm

   await $mode->set_pwm( freq => $freq, duty => $duty );

Sets the PWM generator to the given frequency and duty cycle, as a percentage.
If unspecified, duty cycle will be 50%. Set frequency to 0 to disable.

=cut

use constant {
   PRESCALE_1 => 0,
   PRESCALE_8 => 1,
   PRESCALE_64 => 2,
   PRESCALE_256 => 3,
};

method set_pwm ( %args )
{
   $self->MODE eq "BB" or
      croak "Cannot ->set_pwm except in BB mode";

   my $freq = $args{freq} // croak "Require freq";
   my $duty = $args{duty} // 50;

   if( $freq == 0 ) {
      print STDERR "PIRATE BB CLEAR-PWM\n" if PIRATE_DEBUG;
      return $self->pirate->write_expect_ack( "\x13", "clear PWM" );
   }

   # in fCPU counts at 16MHz
   my $period = 16E6 / $freq;

   my $prescale = PRESCALE_1;
   $prescale = PRESCALE_8,   $period /= 8 if $period >= 2**16;
   $prescale = PRESCALE_64,  $period /= 8 if $period >= 2**16;
   $prescale = PRESCALE_256, $period /= 4 if $period >= 2**16;
   croak "PWM frequency too low" if $period >= 2**16;

   $duty = $period * $duty / 100;

   print STDERR "PIRATE BB SET-PWM\n" if PIRATE_DEBUG;
   $self->pirate->write_expect_ack(
      pack( "C C S> S>", 0x12, $prescale, $duty, $period ), "set PWM"
   );
}

=head2 read_adc_voltage

   $voltage = await $mode->read_adc_voltage;

Reads the voltage on the ADC pin and returns it as a numerical value in volts.

=cut

async method read_adc_voltage ()
{
   $self->MODE eq "BB" or
      croak "Cannot ->read_adc except in BB mode";

   await $self->pirate->write( "\x14" );
   my $buf = await $self->pirate->read( 2 );

   return unpack( "S>", $buf ) * 6.6 / 1024;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
