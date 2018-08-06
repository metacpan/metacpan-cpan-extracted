#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package Device::Chip::SSD1306::SPI4;

use strict;
use warnings;
use base qw( Device::Chip::SSD1306 );

our $VERSION = '0.05';

=head1 NAME

C<Device::Chip::SSD1306::SPI4> - use a F<SSD1306> OLED driver in 4-wire SPI mode

=head1 DESCRIPTION

This L<Device::Chip::SSD1306> subclass provides specific communication to an
F<SSD1306> chip attached via SPI in 4-wire mode; using the C<D/C#> pin.

For actually interacting with the attached module, see the main
L<Device::Chip::SSD1306> documentation.

=cut

use constant PROTOCOL => "SPI";

sub SPI_options
{
   return (
      mode => 0,
      max_bitrate => 8E6,
   );
}

=head1 MOUNT PARAMETERS

=head2 dc

The name of the GPIO line on the adapter that is connected to the C<D/C#> pin
of the chip.

=cut

sub mount
{
   my $self = shift;
   my ( $adapter, %params ) = @_;

   $self->{dc} = delete $params{dc} or
      die "Require a 'dc' parameter";

   return $self->SUPER::mount( $adapter, %params );
}

# passthrough
sub power { $_[0]->protocol->power( $_[1] ) }

sub set_dc
{
   my $self = shift;
   my ( $dc ) = @_;

   $self->protocol->write_gpios( { $self->{dc} => $dc } );
}

sub send_cmd
{
   my $self = shift;
   my @vals = @_;

   $self->set_dc(0)->then( sub {
      $self->protocol->readwrite( join "", map { chr } @vals )
   });
}

sub send_data
{
   my $self = shift;
   my ( $bytes ) = @_;

   $self->set_dc(1)->then( sub {
      $self->protocol->readwrite( $bytes );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
