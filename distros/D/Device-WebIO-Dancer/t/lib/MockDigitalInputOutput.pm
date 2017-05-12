package MockDigitalInputOutput;
use v5.12;
use Moo;
use namespace::clean;

has 'input_pin_count',  is => 'ro';
has 'output_pin_count', is => 'ro';

has 'pin_desc' => (
    is      => 'ro',
    default => sub {[qw{
        V50 GND 0 1 2 3 4 5 6 7
    }]}
);

with 'Device::WebIO::Device::DigitalInput';
with 'Device::WebIO::Device::DigitalOutput';


has '_pins' => (
    is      => 'ro',
    default => sub {[]},
);
has '_pins_set' => (
    is      => 'ro',
);


sub BUILDARGS
{
    my ($class, $args) = @_;

    my $pin_count = $args->{input_pin_count};
    $args->{'_pins_set'} = [ ('IN') x $pin_count ];

    return $args;
}


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
                my $function = $self->is_set_input( $_ ) ? 'IN'
                    : $self->is_set_output( $_ )         ? 'OUT'
                    : 'UNSET';
                my $value = $self->input_pin( $_ ) // 0;
                ($_ => {
                    function => $function,
                    value    => $value,
                });
            } 0 .. ($pin_count - 1)
        },
    );

    return \%data;
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
    return $self->_pins_set->[$pin] eq 'IN';
}

sub mock_get_output
{
    my ($self, $pin) = @_;
    return $self->_pins->[$pin];
}

sub is_set_output
{
    my ($self, $pin) = @_;
    return $self->_pins_set->[$pin] eq 'OUT';
}


sub input_pin
{
    my ($self, $pin) = @_;
    return $self->_pins->[$pin];
}

sub set_as_input
{
    my ($self, $pin) = @_;
    $self->_pins_set->[$pin] = 'IN';
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
    $self->_pins_set->[$pin] = 'OUT';
    return 1;
}


1;
__END__

