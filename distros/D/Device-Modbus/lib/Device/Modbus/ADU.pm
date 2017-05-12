package Device::Modbus::ADU;

use Carp;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub message {
    my ($self, $msg) = @_;
    if ($msg) {
        $self->{message} = $msg;
    }
    croak "This ADU does not contain any messages"
        unless exists $self->{message};
    return $self->{message};
}

sub success {
    my $self = shift;
    return exists $self->{message} && $self->{message}->{code} < 0x80;
}

sub function {
    my $self = shift;
    return $self->message->{function};
}

sub code {
    my $self = shift;
    return $self->message->{code};
}

sub values {
    my $self = shift;
    return $self->message->{values} // [$self->message->{value}];
}

sub unit {
    my ($self, $unit) = @_;
    croak "Unit number is invalid"
        if defined $unit && ($unit < 1 || $unit > 0xff);

    if (defined $unit) {
        $self->{unit} = $unit;
    }
    croak "Unit has not been declared"
        unless exists $self->{unit};
    return $self->{unit};
}

sub binary_message {
    croak "binary_message must be implemented by a subclass of Device::Modbus::ADU";
}

1;
