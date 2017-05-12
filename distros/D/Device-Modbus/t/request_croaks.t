use strict;
use warnings;

use Test::More tests => 19;
BEGIN { use_ok('Device::Modbus::Request') };

# Without function specification
eval {
    my $req = Device::Modbus::Request->new(
        address  => 23,
        quantity => 15
    );
};
like $@, qr/code is required/,
    'Function codes are necessary to create a request';


# With non-existent function
eval {
    my $req = Device::Modbus::Request->new(
        function => 'Non-existent',
        address  => 23,
        quantity => 15
    );
};
like $@, qr/not supported/,
    'Non-supported functions croak';

# With non-existent function code
eval {
    my $req = Device::Modbus::Request->new(
        code     => 69,
        address  => 23,
        quantity => 15
    );
};
like $@, qr/Function code 69 is not supported/,
    'Non-supported function codes croak';

# Missing a required field
eval {
    my $req = Device::Modbus::Request->new(
        function => 'Read Coils',
        # address  => 23,
        quantity => 15
    );
};
like $@, qr/requires 'address'/,
    'Requests croak for missing arguments';

# Reads with invalid quantity of discrete coils, inputs
{
    my $req = Device::Modbus::Request->new(
        function => 'Read Coils',
        address  => 23,
        quantity => 2001
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read Coils quantity too large';
}
{
    my $req = Device::Modbus::Request->new(
        function => 'Read Coils',
        address  => 23,
        quantity => 0
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read Coils quantity set to zero';
}

# Register reads with invalid quantities

{
    my $req = Device::Modbus::Request->new(
        function => 'Read Input Registers',
        address  => 23,
        quantity => 126
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read Input Registers quantity too large';
}
{
    my $req = Device::Modbus::Request->new(
        function => 'Read Input Registers',
        address  => 23,
        quantity => 0
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read Input Registers quantity set to zero';
}

# Write single register requests with invalid values
{
    my $req = Device::Modbus::Request->new(
        function => 'Write Single Register',
        address  => 23,
        value    => -1
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Write single register with negative value';
}

{
    my $req = Device::Modbus::Request->new(
        function => 'Write Single Register',
        address  => 23,
        value    => 0x10000
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Write single register with invalid value to write -- too large';
}

# Write multiple coils requests with invalid values
{
    my $req = Device::Modbus::Request->new(
        function => 'Write Multiple Coils',
        address  => 23,
        values    => []
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Write multiple coils with invalid quantity -- no values';
}
{
    my $req = Device::Modbus::Request->new(
        function => 'Write Multiple Coils',
        address  => 23,
        values   => [(1) x 1969]
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Write multiple coils with invalid quantity -- too large';
}

# Write multiple register requests with invalid values
{
    my $req = Device::Modbus::Request->new(
        function => 'Write Multiple Registers',
        address  => 23,
        values    => []
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Write multiple registers with invalid quantity -- no values';
}
{
    my $req = Device::Modbus::Request->new(
        function => 'Write Multiple Registers',
        address  => 23,
        values   => [(1) x 124]
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Write multiple registers with invalid quantity -- too large';
}

# Read-Write request verifications
{
    my $req = Device::Modbus::Request->new(
        function       => 'Read/Write Multiple Registers',
        read_address   => 23,
        read_quantity  => 0,
        write_address  => 34,
        values   => [(1) x 5]
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read-Write multiple registers -- zero read quantity';
}
{
    my $req = Device::Modbus::Request->new(
        function       => 'Read/Write Multiple Registers',
        read_address   => 23,
        read_quantity  => 126,
        write_address  => 34,
        values   => [(1) x 5]
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read-Write multiple registers -- too large read quantity';
}

{
    my $req = Device::Modbus::Request->new(
        function       => 'Read/Write Multiple Registers',
        read_address   => 23,
        read_quantity  => 125,
        write_address  => 34,
        values   => []
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read-Write multiple registers -- empty list of values to write';
}
{
    my $req = Device::Modbus::Request->new(
        function       => 'Read/Write Multiple Registers',
        read_address   => 23,
        read_quantity  => 125,
        write_address  => 34,
        values   => [(1) x 122]
    );
    isa_ok $req, 'Device::Modbus::Exception',
        'Read-Write multiple registers -- too large list of values to write';
}

done_testing();
