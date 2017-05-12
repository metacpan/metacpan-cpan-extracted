package MockDigitalInputCallback;
use v5.12;
use Moo;
use namespace::clean;

has 'input_pin_count', is => 'ro';
has 'rising' => (
    is      => 'ro',
    default => sub{{
    }},
);
has 'falling' => (
    is      => 'ro',
    default => sub {{
    }},
);
has 'pin_desc' => (
    is      => 'ro',
    default => sub {[qw{
        V50 GND GND 0 1 2 3 GND
    }]}
);
has '_pin_set_input', is => 'ro', default => sub {[]};


with 'Device::WebIO::Device::DigitalInputCallback';


sub all_desc
{
    # placeholder
}

sub input_pin
{
    # placeholder
}

sub input_begin_loop
{
    # placeholder
    return 1;
}

sub input_callback_pin
{
    my ($self, $pin, $when, $callback) = @_;

    if( $self->TRIGGER_RISING == $when ) {
        push @{ $self->rising->{$pin} } => $callback;
    }
    elsif( $self->TRIGGER_FALLING == $when ) {
        push @{ $self->falling->{$pin} } => $callback;
    }
    elsif( $self->TRIGGER_RISING_FALLING == $when ) {
        push @{ $self->rising->{$pin} } => $callback;
        push @{ $self->falling->{$pin} } => $callback;
    }
    else {
        # Bad call, do nothing
    }

    return 1;
}

sub trigger_rising
{
    my ($self, $pin) = @_;
    my $triggers = $self->rising->{$pin};
    $_->(1) for @$triggers;
    return 1;
}

sub trigger_falling
{
    my ($self, $pin) = @_;
    my $triggers = $self->falling->{$pin};
    $_->(0) for @$triggers;
    return 1;
}

sub set_as_input
{
    my ($self, $pin) = @_;
    $self->_pin_set_input->[$pin] = 1;
    return 1;
}

sub is_set_input
{
    my ($self, $pin) = @_;
    return $self->_pin_set_input->[$pin];
}


1;
__END__
