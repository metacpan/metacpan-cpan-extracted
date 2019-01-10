#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package Device::Chip::SSD1306::I2C;

use strict;
use warnings;
use base qw( Device::Chip::SSD1306 );

our $VERSION = '0.08';

use constant PROTOCOL => "I2C";

use constant DEFAULT_ADDR => 0x3C;

=encoding UTF-8

=head1 NAME

C<Device::Chip::SSD1306::I2C> - use a F<SSD1306> OLED driver in I²C mode

=head1 DESCRIPTION

This L<Device::Chip::SSD1306> subclass provides specific communication to an
F<SSD1306> chip attached via I²C.

For actually interacting with the attached module, see the main
L<Device::Chip::SSD1306> documentation.

=cut

sub mount
{
   my $self = shift;
   my ( $adapter, %params ) = @_;

   $self->{addr} = delete $params{addr} // DEFAULT_ADDR;

   return $self->SUPER::mount( $adapter, %params );
}

sub I2C_options
{
   my $self = shift;

   return (
      addr => $self->{addr},
   );
}

# passthrough
sub power { $_[0]->protocol->power( $_[1] ) }

sub send_cmd
{
   my $self = shift;
   my @vals = @_;

   my $final = pop @vals;

   $self->protocol->write( join "", ( map { "\x80" . chr $_ } @vals ),
      "\x00" . chr $final );
}

sub send_data
{
   my $self = shift;
   my ( $bytes ) = @_;

   $self->protocol->write( "\x40" . $_[0] )
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
