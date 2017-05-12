package Device::Modbus::Request;

use parent 'Device::Modbus';
use Device::Modbus::Exception;
use Carp;
use strict;
use warnings;

my %parameters_for = (
    'Read Coils'
        => [qw(code address quantity)],
    'Read Discrete Inputs'
        => [qw(code address quantity)],
    'Read Holding Registers'
        => [qw(code address quantity)],
    'Read Input Registers'
        => [qw(code address quantity)],
    'Write Single Coil'
        => [qw(code address value)],
    'Write Single Register'
        => [qw(code address value)],
    'Write Multiple Coils'
        => [qw(code address quantity bytes values)],
    'Write Multiple Registers'
        => [qw(code address quantity bytes values)],
    'Read/Write Multiple Registers'
        => [qw(code read_address read_quantity
            write_address write_quantity bytes values)],
);


my %format_for = (
    0x01 => 'Cnn',
    0x02 => 'Cnn',
    0x03 => 'Cnn',
    0x04 => 'Cnn',
    0x05 => 'Cnn',
    0x06 => 'Cnn',
    0x0F => 'CnnCC*',
    0x10 => 'CnnCn*',
    0x17 => 'CnnnnCn*',
);

sub new {
    my ($class, %args) = @_;
    croak 'A function name or code is required when creating a request'
        unless $args{function} || $args{code};

    if ($args{function}) {
        croak "Function $args{function} is not supported"
            unless exists $Device::Modbus::code_for{$args{function}};
        $args{code} = $Device::Modbus::code_for{$args{function}};
    }
    else {
        croak "Function code $args{code} is not supported"
            unless exists $Device::Modbus::function_for{$args{code}};
        $args{function} = $Device::Modbus::function_for{$args{code}};
    }        

    # Validate we have all the needed parameters
    foreach (@{$parameters_for{$args{function}}}) {
        # These are calculated
        next if $_ eq 'bytes' || $_ eq 'write_quantity';
        next if $_ eq 'quantity' && ($args{code} == 0x0F || $args{code} == 0x10);

        # But the rest are required
        croak "Function $args{function} requires '$_'"
            unless exists $args{$_};
    }

    # Validate parameters
    foreach ($args{code}) {
        if ($args{code} == 0x01 || $args{code} == 0x02) {
            unless (defined $args{quantity} && $args{quantity} >= 1 && $args{quantity} <= 0x7D0) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        elsif ($args{code} == 0x03 || $args{code} == 0x04) {
            unless (defined $args{quantity} && $args{quantity} >= 1 && $args{quantity} <= 0x7D) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        elsif ($args{code} == 0x05) {
            # Rather than validate, coerce values
            $args{value} = $args{value} ? 1 : 0;
        }
        elsif ($args{code} == 0x06) {
            unless (defined $args{value} && $args{value} >= 0 && $args{value} <= 0xFFFF) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        elsif ($args{code} == 0x0F) {
            unless (defined $args{values} && @{$args{values}} >= 1 && @{$args{values}} <= 0x7B0) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        elsif ($args{code} == 0x10) {
            unless (defined $args{values} && @{$args{values}} >= 1 && @{$args{values}} <= 0x7B) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
        elsif ($args{code} == 0x17) {
            unless (
                   defined $args{read_quantity}
                && defined $args{values}
                && $args{read_quantity}  >= 1
                && $args{read_quantity}  <= 0x7D
                && @{$args{values}} >= 1
                && @{$args{values}} <= 0x79) {
                return Device::Modbus::Exception->new(
                    code           => $args{code} + 0x80,
                    exception_code => 3
                );
            }
        }
    }

    return bless \%args, $class;
}

sub pdu {
    my $self = shift;

    if ($self->{code} == 0x01 || $self->{code} == 0x02 || $self->{code} == 0x03 || $self->{code} == 0x04) {
        return  pack $format_for{$self->{code}},
            $self->{code}, $self->{address}, $self->{quantity};
    }
    elsif ($self->{code} == 0x05 || $self->{code} == 0x06) {
        my $value = $self->{value};
        $value = 0xFF00 if $self->{code} == 0x05 && $self->{value};
        return pack $format_for{$self->{code}},
            $self->{code}, $self->{address}, $value;
    }
    elsif ($self->{code} == 0x0F) {
        my $values   = $self->flatten_bit_values($self->{values});
        my $quantity = scalar @{$self->{values}};
        my $pdu = pack $format_for{$self->{code}},
            $self->{code}, $self->{address},
            $quantity, scalar @$values;
        return $pdu . join '', @$values;
    }
    elsif ($self->{code} == 0x10) {
        my $quantity = scalar @{$self->{values}};
        my $bytes    = 2*$quantity;
        return pack $format_for{$self->{code}},
            $self->{code}, $self->{address}, $quantity, $bytes,
            @{$self->{values}};
    }
    elsif ($self->{code} == 0x17) {
        my $quantity = scalar @{$self->{values}};
        my $bytes    = 2*$quantity;
        return pack $format_for{$self->{code}},
            $self->{code},
            $self->{read_address},
            $self->{read_quantity},
            $self->{write_address},
            $quantity,
            $bytes,
            @{$self->{values}};
    }
}

1;

__END__

=head1 NAME

Device::Modbus::Request - Modbus requests for Device::Modbus

=head1 SYNOPSIS

 use Device::Modbus::Request;

 my $req = Device::Modbus::Request->new(
    code     => 0x01,
    address  => 330,
    quantity => 6
 );

 my $req2 = Device::Modbus::Request->new(
    function => 'Read Coils',
    address  => 330,
    quantity => 6
 );
 
 my $pdu = $req->pdu; # gets the binary representation of the request 

=head1 DESCRIPTION

This class builds Modbus request objects, which can later issue their transport-independent PDU (Protocol Data Unit). These objects can then be sent by a Device::Modbus client or received by a server. See the main documentation at L<Device::Modbus>.

=head1 METHODS

This class offers just two methods, with the constructor being the most important one.

=head2 Constructor

Nine request functions are supported. To define the function of your request, you must define either its function name or its function code. The rest of the arguments are always mandatory, but they differ among the different request functions. Please see the summary table below; details are explained further below.

The supported request types and their arguments are:

 +------+-------------------------------+------------------------------+
 | Code | Function                      | Other arguments              |
 +------+-------------------------------+------------------------------+
 | 0x01 | Read Coils                    | address, quantity            |
 | 0x02 | Read Discrete Inputs          | address, quantity            |
 | 0x03 | Read Holding Registers        | address, quantity            |
 | 0x04 | Read Input Registers          | address, quantity            |
 | 0x05 | Write Single Coil             | address, value               |
 | 0x06 | Write Single Register         | address, value               |
 | 0x0F | Write Multiple Coils          | address, values              |
 | 0x10 | Write Multiple Registers      | address, values              |
 | 0x17 | Read/Write Multiple Registers | read_address, read_quantity, |
 |      |                               | write_address, values        |
 +------+-------------------------------|------------------------------+

Depending on the code or the function, the rest of the arguments become also mandatory. The table above shows a summary. Details are discussed below.

=head3 function or code

You must always specify either the function name or the function code in the constructor. See the two examples in the synopsis.

=head3 Other arguments

The rest of the arguments to the constructor depend on the request that you are building. The details are as follows:

=head4 * Read Coils, Read Discrete Inputs, Read Holding Registers, Read Input Registers

These functions have codes from 1 to 4.

=over

=item address

Coded in a 16-bit word, so the address must be between 0 and 65535.

=item quantity

For functions 0x01 and 0x02, quantity must be less than or equal to 2000. For functions 0x03 and 0x04, the maximum is 125.

=back

=head4 * Write Single Coil and Write Single Register

These functions have codes 5 and 6.

=over

=item address

Coded in a 16-bit word, so the address must be between 0 and 65535.

=item value

For a single coil, the value is taken as true or false. False values include undef, the empty string, and 0. Register values are always a number between 0 and 65535.

=back

=head4 * Write Multiple Coils

This is function code 15, 0x0F.

=over

=item address

Coded in a 16-bit word, so the address must be between 0 and 65535.

=item values

You can enter up to 1968 values in an array reference. Each value will be treated as a true or false value.

=back

=head4 * Write Multiple Registers

This is function code 16, 0x10.

=over

=item address

Coded in a 16-bit word, so the address must be between 0 and 65535.

=item values

You can enter up to 123 values in an array reference. Each value will be coded in a 16-bit word, so they must be between 0 and 65535.

=back

=head4 * Read/Write Multiple Registers

This is function number 0x17. It requires the following arguments:

=over

=item read_address

The address where you want to start reading registers. As usual, it must be a number between 0 and 65535.

=item read_quantity

A number up to 125. This is the number of registers that will be read.

=item write_address

The address where you want to start writing register values. Again, it must be a number between 0 and 65535.

=item values

You can enter up to 121 values in an array reference. Each value will be coded in a 16-bit word, so they must be between 0 and 65535.

=back

=head2 pdu

This method returns the binary representation of the request. Before sending it to a server (or to a slave, which amounts to the same), you must wrap the PDU within a protocol header and footer. See the ADU methods of the clients for this.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

