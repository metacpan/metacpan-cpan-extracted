#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Device::BusPirate::Mode;

use strict;
use warnings;

our $VERSION = '0.16';

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

sub _start_mode_and_await
{
   my $self = shift;
   my ( $send, $await ) = @_;

   my $pirate = $self->pirate;

   $pirate->write( $send );
   $pirate->read( length $await, "start mode" )->then( sub {
      my ( $buf ) = @_;
      return Future->done( $buf ) if $buf eq $await;
      return Future->fail( "Expected '$await' response but got '$buf'" );
   });
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

   $self->pirate->write( chr( 0x40 |
      ( $self->{power}  ? CONF_POWER  : 0 ) |
      ( $self->{pullup} ? CONF_PULLUP : 0 ) |
      ( $self->{aux}    ? CONF_AUX    : 0 ) |
      ( $self->{cs}     ? CONF_CS     : 0 ) )
   );
   $self->pirate->read( 1, "update peripherals" )
      ->then( sub {
         my( $buf ) = @_;
         $buf eq "\x01" or return Future->fail( "Expected ACK response to _update_peripherals" );
         return Future->done;
      });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
