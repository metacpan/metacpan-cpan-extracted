package MockDigitalInput;
use v5.12;
use Moo;
use namespace::clean;


has 'input_pin_count', is => 'ro';

with 'Device::WebIO::Device::DigitalInput';

has '_pin_input',     is => 'ro', default => sub {[]};
has '_pin_set_input', is => 'ro', default => sub {[]};


sub mock_set_input
{
    my ($self, $pin, $val) = @_;
    $self->_pin_input->[$pin] = $val;
    return $val;
}

sub is_set_input
{
    my ($self, $pin) = @_;
    return $self->_pin_set_input->[$pin];
}


sub input_pin
{
    my ($self, $pin) = @_;
    return $self->_pin_input->[$pin];
}

sub set_as_input
{
    my ($self, $pin) = @_;
    $self->_pin_set_input->[$pin] = 1;
    return 1;
}


1;
__END__

