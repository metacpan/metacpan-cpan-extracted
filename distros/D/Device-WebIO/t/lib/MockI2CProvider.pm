package MockI2CProvider;
use v5.12;
use Moo;
use namespace::clean;

has 'i2c_channels', is => 'ro';
has '_registers' => (
    is      => 'ro',
    default => sub {{}},
);
with 'Device::WebIO::Device::I2CProvider';



sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub i2c_read
{
    my ($self, $channel, $addr, $register, $length) = @_;
    return @{ $self->_registers->{$channel}{$addr}{$register} };
}

sub i2c_write
{
    my ($self, $channel, $addr, $register, @bytes) = @_;
    $self->_registers->{$channel}{$addr}{$register} = \@bytes;
    return 1;
}


1;
__END__

