package MockDigitalInputOutput;
use v5.12;
use Moo;
use namespace::clean;

use constant input_pin_count  => 10;
use constant output_pin_count => 8;
use constant TYPE_INPUT  => 1;
use constant TYPE_OUTPUT => 0;

with 'Device::WebIO::Device::DigitalInput';
with 'Device::WebIO::Device::DigitalOutput';


has '_pins' => (
    is      => 'ro',
    default => sub {[
        (0) x input_pin_count(),
    ]},
);
has '_pins_set' => (
    is      => 'ro',
    default => sub {[
        (0) x input_pin_count(),
    ]},
);


sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub mock_set_input
{
    my ($self, $pin, $val) = @_;
    $self->_pins->[$pin] = $val;
    return $val;
}

sub is_set_input
{
    my ($self, $pin) = @_;
    return $self->_pins_set->[$pin] == TYPE_INPUT;
}

sub mock_get_output
{
    my ($self, $pin) = @_;
    return $self->_pins->[$pin];
}

sub is_set_output
{
    my ($self, $pin) = @_;
    return $self->_pins_set->[$pin] == TYPE_OUTPUT;
}


sub input_pin
{
    my ($self, $pin) = @_;
    return $self->_pins->[$pin];
}

sub set_as_input
{
    my ($self, $pin) = @_;
    $self->_pins_set->[$pin] = TYPE_INPUT;
    return 1;
}

sub output_pin
{
    my ($self, $pin, $val) = @_;
    $self->_pins->[$pin] = $val;
    return 1;
}

sub set_as_output
{
    my ($self, $pin) = @_;
    $self->_pins_set->[$pin] = TYPE_OUTPUT;
    return 1;
}


1;
__END__

