package Device::WebIO::Device::PWM;
$Device::WebIO::Device::PWM::VERSION = '0.010';
use v5.12;
use Moo::Role;

with 'Device::WebIO::Device';

requires 'pwm_bit_resolution';
requires 'pwm_pin_count';
requires 'pwm_output_int';


sub pwm_max_int
{
    my ($self, $pin) = @_;
    my $resolution = $self->pwm_bit_resolution( $pin );
    return 2 ** $resolution - 1;
}

sub pwm_output_float
{
    my ($self, $pin, $out) = @_;
    my $max_int = $self->pwm_max_int( $pin );
    my $int_out = sprintf( '%.0f', $max_int * $out );
    return $self->pwm_output_int( $pin, $int_out );
}


1;
__END__

