#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Device::Chip::SSD1306::SPI4 0.11;
class Device::Chip::SSD1306::SPI4
   :isa(Device::Chip::SSD1306);

use Future::AsyncAwait;

=head1 NAME

C<Device::Chip::SSD1306::SPI4> - use a F<SSD1306> OLED driver in 4-wire SPI mode

=head1 DESCRIPTION

This L<Device::Chip::SSD1306> subclass provides specific communication to an
F<SSD1306> chip attached via SPI in 4-wire mode; using the C<D/C#> pin.

For actually interacting with the attached module, see the main
L<Device::Chip::SSD1306> documentation.

=cut

use constant PROTOCOL => "SPI";

method SPI_options
{
   return (
      mode => 0,
      max_bitrate => 1E6,
   );
}

=head1 MOUNT PARAMETERS

=head2 dc

The name of the GPIO line on the adapter that is connected to the C<D/C#> pin
of the chip.

=cut

method mount ( $adapter, %params )
{
   $self->{dc} = delete $params{dc} or
      die "Require a 'dc' parameter";

   return $self->SUPER::mount( $adapter, %params );
}

# passthrough
method power ( $on ) { $self->protocol->power( $on ) }

method set_dc ( $dc )
{
   $self->protocol->write_gpios( { $self->{dc} => $dc } );
}

async method send_cmd ( @vals )
{
   await $self->set_dc( 0 );
   await $self->protocol->readwrite( join "", map { chr } @vals );
}

async method send_data ( $bytes )
{
   await $self->set_dc( 1 );
   await $self->protocol->readwrite( $bytes );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
