package Device::Modbus::Response;

use parent 'Device::Modbus';
use Device::Modbus::Exception;
use Carp;
use strict;
use warnings;

my %parameters_for = (
    'Read Coils'
        => [qw(code bytes values)],
    'Read Discrete Inputs'
        => [qw(code bytes values)],
    'Read Holding Registers'
        => [qw(code bytes values)],
    'Read Input Registers'
        => [qw(code bytes values)],
    'Write Single Coil'
        => [qw(code address value)],
    'Write Single Register'
        => [qw(code address value)],
    'Write Multiple Coils'
        => [qw(code address quantity)],
    'Write Multiple Registers'
        => [qw(code address quantity)],
    'Read/Write Multiple Registers'
        => [qw(code bytes values)],
);

my %format_for = (
    0x01 => 'CCC*',
    0x02 => 'CCC*',
    0x03 => 'CCn*',
    0x04 => 'CCn*',
    0x05 => 'Cnn',
    0x06 => 'Cnn',
    0x0F => 'Cnn',
    0x10 => 'Cnn',
    0x17 => 'CCn*',
);


sub new {
    my ($class, %args) = @_;

    # Must receive either a function name or a function code
    croak 'A function name or code is required  when creating a response'
        unless $args{function} || $args{code};

    if ($args{function}) {
        croak "Function $args{function} is not supported"
            unless exists $Device::Modbus::code_for{$args{function}};
        $args{code} = $Device::Modbus::code_for{$args{function}};
    }
    else {
        croak "Code $args{code} is not supported"
            unless exists $Device::Modbus::function_for{$args{code}};
        $args{function} = $Device::Modbus::function_for{$args{code}};
    }


    # Validate we have all the needed parameters
    foreach (@{$parameters_for{$args{function}}}) {
        # This is calculated
        next if $_  eq 'bytes';

        # But the rest are required
        croak "Response for function $args{function} requires '$_'"
            unless exists $args{$_};
    }

    # Validate parameters
    if ($args{code} == 0x01 || $args{code} == 0x02) {
        unless (@{$args{values}} > 0 && @{$args{values}} <= 0x7D0) {
            die Device::Modbus::Exception->new(
                code           => $args{code} + 0x80,
                exception_code => 3
            );                    
        }
    }
    elsif ($args{code} == 0x03 || $args{code} == 0x04 || $args{code} == 0x17) {
        unless (@{$args{values}} > 0 && @{$args{values}} <= 0x7D) {
            die Device::Modbus::Exception->new(
                code           => $args{code} + 0x80,
                exception_code => 3
            );                    
        }
    }
    elsif ($args{code} == 0x05) {
        unless (defined $args{value}) {
            die Device::Modbus::Exception->new(
                code           => $args{code} + 0x80,
                exception_code => 3
            );                    
        }
    }
    elsif ($args{code} == 0x06) {
        unless ($args{value} >= 0 && $args{value} <= 0xFFFF) {
            die Device::Modbus::Exception->new(
                code           => $args{code} + 0x80,
                exception_code => 3
            );
        }
    }
    elsif ($args{code} == 0x0F) {
        unless ($args{quantity} > 0 && $args{quantity} <= 0x7B0) {
            die Device::Modbus::Exception->new(
                code           => $args{code} + 0x80,
                exception_code => 3
            );                    
        }
    }
    elsif ($args{code} == 0x10) {
        unless ($args{quantity} >= 1 && $args{quantity} <= 0x7B) {
            die Device::Modbus::Exception->new(
                code           => $args{code} + 0x80,
                exception_code => 3
            );
        }
    }

    return bless \%args, $class;
}

sub pdu {
    my $self = shift;

    if ($self->{code} == 0x01 || $self->{code} == 0x02) {
        my $values = $self->flatten_bit_values($self->{values});
        return pack('CC', $self->{code}, scalar(@$values))
            . join '', @$values;
    }
    elsif ($self->{code} == 0x03 || $self->{code} == 0x04 || $self->{code} == 0x17) {
        my $bytes = 2 * scalar @{$self->{values}};
        return  pack $format_for{$self->{code}},
            $self->{code}, $bytes, @{$self->{values}};
    }
    elsif ($self->{code} == 0x05 || $self->{code} == 0x06) {
        my $value = $self->{value};
        $value = 0xFF00 if $self->{code} == 0x05 && $self->{value};
        return pack $format_for{$self->{code}},
            $self->{code}, $self->{address}, $value;
    }
    elsif ($self->{code} == 0x0F || $self->{code} == 0x10) {
        return pack $format_for{$self->{code}},
            $self->{code}, $self->{address}, $self->{quantity};
    }
}

1;
