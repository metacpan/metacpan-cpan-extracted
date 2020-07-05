#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2019 -- leonerd@leonerd.org.uk

package Device::BusPirate::Mode;

use strict;
use warnings;

our $VERSION = '0.20';

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

sub new
{
   my $class = shift;
   my ( $bp ) = @_;

   my $self = bless {
      bp => $bp,
   }, $class;

   $self->{cs}     = 0;
   $self->{power}  = 0;
   $self->{pullup} = 0;
   $self->{aux}    = 0;

   return $self;
}

=head1 METHODS

=cut

=head2 pirate

   $pirate = $mode->pirate

Returns the underlying L<Device::BusPirate> instance.

=cut

sub pirate
{
   my $self = shift;
   return $self->{bp};
}

async sub _start_mode_and_await
{
   my $self = shift;
   my ( $send, $await ) = @_;

   my $pirate = $self->pirate;

   $pirate->write( $send );
   my $buf = await $pirate->read( length $await, "start mode" );

   return $buf if $buf eq $await;
   die "Expected '$await' response but got '$buf'";
}

=head2 power

   $mode->power( $power )->get

Enable or disable the C<VREG> 5V and 3.3V power outputs.

=cut

sub power
{
   my $self = shift;
   $self->{power} = !!shift;
   $self->_update_peripherals;
}

=head2 pullup

   $mode->pullup( $pullup )->get

Enable or disable the IO pin pullup resistors from C<Vpu>. These are connected
to the C<MISO>, C<CLK>, C<MOSI> and C<CS> pins.

=cut

sub pullup
{
   my $self = shift;
   $self->{pullup} = !!shift;
   $self->_update_peripherals;
}

=head2 aux

   $mode->aux( $aux )->get

Set the C<AUX> output pin level.

=cut

sub aux
{
   my $self = shift;
   $self->{aux} = !!shift;
   $self->_update_peripherals;
}

=head2 cs

   $mode->cs( $cs )->get

Set the C<CS> output pin level.

=cut

sub cs
{
   my $self = shift;
   $self->{cs} = !!shift;
   $self->_update_peripherals;
}

sub _update_peripherals
{
   my $self = shift;

   $self->pirate->write_expect_ack( chr( 0x40 |
      ( $self->{power}  ? CONF_POWER  : 0 ) |
      ( $self->{pullup} ? CONF_PULLUP : 0 ) |
      ( $self->{aux}    ? CONF_AUX    : 0 ) |
      ( $self->{cs}     ? CONF_CS     : 0 ) ), "_update_peripherals" );
}

=head2 set_pwm

   $mode->set_pwm( freq => $freq, duty => $duty )->get

Sets the PWM generator to the given frequency and duty cycle, as a percentage.
If unspecified, duty cycle will be 50%. Set frequency to 0 to disable.

=cut

use constant {
   PRESCALE_1 => 0,
   PRESCALE_8 => 1,
   PRESCALE_64 => 2,
   PRESCALE_256 => 3,
};

sub set_pwm
{
   my $self = shift;
   my %args = @_;

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

   $voltage = $mode->read_adc_voltage->get

Reads the voltage on the ADC pin and returns it as a numerical value in volts.

=cut

async sub read_adc_voltage
{
   my $self = shift;

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
