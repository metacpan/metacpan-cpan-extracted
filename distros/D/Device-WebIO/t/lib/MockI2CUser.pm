package MockI2CUser;
use v5.12;
use Moo;
use namespace::clean;

with 'Device::WebIO::Device::I2CUser';


sub set_first_register
{
    my ($self, $value) = @_;
    my $webio    = $self->webio;
    my $provider = $self->provider;
    my $channel  = $self->channel;
    my $addr     = $self->address;

    $webio->i2c_write( $provider, $channel, $addr, 0x00, $value );
    return 1;
}

sub get_second_register
{
    my ($self) = @_;
    my $webio    = $self->webio;
    my $provider = $self->provider;
    my $channel  = $self->channel;
    my $addr     = $self->address;

    my ($value) = $webio->i2c_read( $provider, $channel, $addr, 0x01, 1 );
    return ($value);
}

1;
__END__

