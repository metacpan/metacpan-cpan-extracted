package MockPWMOutput;
use v5.12;
use Moo;

has 'pwm_bit_resolution_by_pin', is => 'ro';
has 'pwm_pin_count',             is => 'ro';
has '_output_int',               is => 'ro', default => sub {[]};
with 'Device::WebIO::Device::PWM';


sub pwm_bit_resolution
{
    my ($self, $pin) = @_;
    return $self->pwm_bit_resolution_by_pin->[$pin];
}

sub mock_get_output
{
    my ($self, $pin) = @_;
    return $self->_output_int->[$pin];
}

sub pwm_output_int
{
    my ($self, $pin, $val) = @_;
    $self->_output_int->[$pin] = $val;
    return 1;
}


1;
__END__

