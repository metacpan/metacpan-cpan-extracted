package MockSPI;
use v5.12;
use Moo;
use namespace::clean;

has 'spi_channels', is => 'ro';
has 'data',         is => 'rw';
has '_speed',       is => 'rw', default => sub { 500_000 };
with 'Device::WebIO::Device::SPI';



sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub spi_set_speed
{
    my ($self, $channel, $speed) = @_;
    $self->_speed( $speed );
    return 1;
}

sub spi_read
{
    my ($self, $channel, $len) = @_;
    return $self->data;
}

sub spi_write
{
    my ($self, $channel, $data) = @_;
    $self->data( $data );
    return 1;
}


1;
__END__

