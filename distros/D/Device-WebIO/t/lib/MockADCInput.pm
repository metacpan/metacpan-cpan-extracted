package MockADCInput;
use v5.12;
use Moo;

has 'adc_bit_resolution_by_pin', is => 'ro';
has 'adc_volt_ref_by_pin',       is => 'ro';
has 'adc_pin_count',             is => 'ro';
has '_input_int',                is => 'ro', default => sub {[]};
with 'Device::WebIO::Device::ADC';


sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub adc_bit_resolution
{
    my ($self, $pin) = @_;
    return $self->adc_bit_resolution_by_pin->[$pin];
}

sub adc_volt_ref
{
    my ($self, $pin) = @_;
    return $self->adc_volt_ref_by_pin->[$pin];
}

sub mock_set_input
{
    my ($self, $pin, $val) = @_;
    $self->_input_int->[$pin] = $val;
    return 1;
}

sub adc_input_int
{
    my ($self, $pin) = @_;
    return $self->_input_int->[$pin];
}


1;
__END__

