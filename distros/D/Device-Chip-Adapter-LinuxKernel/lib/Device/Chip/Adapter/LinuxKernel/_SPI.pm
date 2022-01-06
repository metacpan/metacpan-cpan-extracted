package 
  Device::Chip::Adapter::LinuxKernel::_SPI;

use strict;
use warnings;
use base qw( Device::Chip::Adapter );
use Carp qw/croak/;

our $VERSION = '0.00005';

require XSLoader;
XSLoader::load();

use Device::Chip::Adapter::LinuxKernel::_base;
use base qw( Device::Chip::Adapter::LinuxKernel::_base );
use Carp qw/croak/;

sub configure {
    my $self = shift;
    my %args = @_;

    if (defined $self->{spidev})
    {
        _spidev_close($self->{spidev});
    }

    $self->{spidev} = Device::Chip::Adapter::LinuxKernel::_SPI::_spidev_open("/dev/".$self->{spi_bus});
    Device::Chip::Adapter::LinuxKernel::_SPI::_spidev_set_mode($self->{spidev}, $args{mode})
	if defined $args{mode};
    Device::Chip::Adapter::LinuxKernel::_SPI::_spidev_set_speed($self->{spidev}, $args{max_bitrate})
	if defined $args{max_bitrate};

    Future->done($self);
}

sub DESTROY {
    my $self = shift;

    if (defined $self->{spidev})
    {
        _spidev_close($self->{spidev});
    }
}

sub readwrite {
    my $self = shift;
    my $bytes = shift;

    my $bytes_in = _spidev_transfer($self->{spidev}, $bytes);

    Future->done($bytes_in);
}

sub write {
    my $self = shift;
    my $bytes = shift;

    $self->readwrite($bytes);
}

sub read {
    my $self = shift;
    my $len = shift;

    my $bytes_out = chr(0) x $len;
    return $self->readwrite($bytes_out);
}

0x55AA;
