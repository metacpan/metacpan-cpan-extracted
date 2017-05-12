package MockDigitalInput;
use v5.12;
use Moo;
use namespace::clean;


has 'input_pin_count', is => 'ro';
has 'pin_desc' => (
    is      => 'ro',
    default => sub {[qw{
        V50 GND GND 0 1 2 3 GND
    }]}
);

with 'Device::WebIO::Device::DigitalInput';

has '_pin_input',     is => 'ro', default => sub {[]};
has '_pin_set_input', is => 'ro', default => sub {[]};


sub all_desc
{
    my ($self) = @_;
    my $pin_count = $self->input_pin_count;

    my %data = (
        UART    => 0,
        SPI     => 0,
        I2C     => 0,
        ONEWIRE => 0,
        GPIO => {
            map {
                my $value = $self->input_pin( $_ ) // 0;
                $_ => {
                    function => 'IN',
                    value    => $value,
                };
            } 0 .. ($pin_count - 1)
        },
    );

    return \%data;
}


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

