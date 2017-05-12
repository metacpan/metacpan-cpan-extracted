package MockDigitalOutput;
use v5.12;
use Moo;
use namespace::clean;

has 'output_pin_count', is => 'ro';
with 'Device::WebIO::Device::DigitalOutput';

has '_pin_output',     is => 'ro', default => sub {[]};
has '_pin_set_output', is => 'ro', default => sub {[]};


sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub mock_get_output
{
    my ($self, $pin) = @_;
    return $self->_pin_output->[$pin];
}

sub is_set_output
{
    my ($self, $pin) = @_;
    return $self->_pin_set_output->[$pin];
}


sub output_pin
{
    my ($self, $pin, $val) = @_;
    $self->_pin_output->[$pin] = $val;
    return 1;
}

sub set_as_output
{
    my ($self, $pin) = @_;
    $self->_pin_set_output->[$pin] = 1;
    return 1;
}


1;
__END__

