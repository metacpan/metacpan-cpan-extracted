package Device::Chip::Adapter::LinuxKernel::_I2C;

use strict;
use warnings;

use base qw( Device::Chip::Adapter::LinuxKernel::_base );
use Carp qw/croak/;
use IO::File;
use Fcntl;

our $VERSION = '0.00006';

use constant I2C_SLAVE => 0x0703;

require XSLoader;
XSLoader::load();

sub configure {
    my $self = shift;
    my %args = @_;

    $self->{address} = delete $args{addr};
    $self->{max_rate} = delete $args{max_bitrate}; # We're unable to affect this from userland it seems

    croak "Missing required parameter 'bus'" unless defined $self->{i2c_bus};
    croak "Missing required parameter 'addr'" unless defined $self->{address};

    croak "Unrecognised configuration options: " . join( ", ", keys %args ) if %args;

    my $fh = IO::File->new( $self->{i2c_bus}, O_RDWR );
    if (!$fh) {
        croak "Unable to open I2C Device File at $self->{i2c_bus}";
    }
    $self->{fh} = $fh;

    $fh->ioctl(I2C_SLAVE,$self->{address});

    Future->done($self);
}

sub write {
    my $self = shift;
    my ($bytes_out) = @_;

    _i2cdev_write($self->{fh}->fileno(), $self->{address}, $bytes_out);

    Future->done;
}

sub read {
    my ($self, $len_in) = @_;

    my $val = _i2cdev_read($self->{fh}->fileno(), $self->{address}, $len_in);

    Future->done($val);
}

sub write_then_read {
    my $self = shift;
    my ($bytes_out, $len_in) = @_;

    my $val = _i2cdev_write_read($self->{fh}->fileno(), $self->{address}, $bytes_out, $len_in);

    Future->done($val);
}
