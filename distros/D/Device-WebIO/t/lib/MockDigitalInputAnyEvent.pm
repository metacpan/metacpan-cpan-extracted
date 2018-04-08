package MockDigitalInputAnyEvent;
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
has 'condvar_for_pin' => (
    is => 'ro',
    default => sub {{}},
);

with 'Device::WebIO::Device::DigitalInputAnyEvent';

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


sub set_anyevent_condvar
{
    my ($self, $pin, $cv) = @_;
    $self->condvar_for_pin->{$pin} = $cv;
    return;
}

sub mock_set_input
{
    my ($self, $pin, $val) = @_;
    $self->_pin_input->[$pin] = $val;
    return if ! exists $self->condvar_for_pin->{$pin};

    my $cv = $self->condvar_for_pin->{$pin};
    my $old_cb = $cv->cb;

    $cv->send( $pin, $val );
    my $new_cv = AnyEvent->condvar;
    $new_cv->cb( $old_cb );
    $self->condvar_for_pin->{$pin} = $new_cv;

    return $val;
}

sub input_pin { }
sub set_as_input { }
sub is_set_input { }


1;
__END__

