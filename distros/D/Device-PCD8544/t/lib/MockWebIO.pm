package MockWebIO;
use v5.12;
use Moo;
use namespace::clean;

has 'spi_channels', is => 'ro';
has 'data',         is => 'rw';
with 'Device::WebIO::Device::SPI';

has 'output_pin_count', is => 'ro';
with 'Device::WebIO::Device::DigitalOutput';


# Everything is just placeholders

sub pin_desc
{
}

sub all_desc
{
}


sub spi_set_speed
{
}

sub spi_read
{
}

sub spi_write
{
}

sub output_pin
{
}

sub set_as_output
{
}

sub is_set_output
{
}


1;
__END__

