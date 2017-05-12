use strict;
use warnings;

use Test::More tests => 18;
BEGIN { use_ok('Device::Modbus::Response') };

# Without function specification
eval {
    my $req = Device::Modbus::Response->new(
        values   => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0]        
    );
};
like $@, qr/name or code is required/,
    'Function names or codes are necessary to create a request';


# With non-existent function
eval {
    my $req = Device::Modbus::Response->new(
        function => 'Non-existent',
        values   => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0]        
    );
};
like $@, qr/Function Non-existent is not supported/,
    'Non-supported functions croak';

# With non-existent function code
eval {
    my $req = Device::Modbus::Response->new(
        code     => 69,
        values   => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0]        
    );
};
like $@, qr/Code 69 is not supported/,
    'Non-supported function codes croak';

# Missing a required field
eval {
    my $response = Device::Modbus::Response->new(
        function => 'Read Coils',
        # values   => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0]        
    );
};
like $@, qr/requires 'values'/,
    'Requests croak for missing arguments';

# Write single coil requests without value to write

eval {
    my $req = Device::Modbus::Response->new(
        function => 'Write Single Coil',
        address  => 23,
        # value    => undef
    );
};
like $@, qr/requires 'value'/,
    'Write single coil with missing written value';


### Parameter validation tests

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x01,
        values   => []        
    );
};
is $@->{exception_code}, 3,
    'Read Coils response without data returns exception';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x02,
        values   => [(1)x2001]        
    );
};
is $@->{exception_code}, 3,
    'Read Discrete Inputs response with too much data';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x03,
        values   => []        
    );
};
is $@->{exception_code}, 3,
    'Read Input Registers response without data returns exception';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x04,
        values   => [(1)x126]        
    );
};
is $@->{exception_code}, 3,
    'Read Holding Registers response with too much data';

eval {
    my $req = Device::Modbus::Response->new(
        function => 'Write Single Coil',
        address  => 23,
        value    => undef
    );
};
is $@->{exception_code}, 3,
    'Write single coil with invalid value to write';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x17,
        values   => [(1)x126]        
    );
};
is $@->{exception_code}, 3,
    'Read/Write registers with too much data';

eval {
    my $req = Device::Modbus::Response->new(
        function => 'Write Single Register',
        address  => 23,
        value    => -1
    );
};
is $@->{exception_code}, 3,
    'Write single register with invalid value to write -- negative';

eval {
    my $req = Device::Modbus::Response->new(
        function => 'Write Single Register',
        address  => 23,
        value    => 0x10000
    );
};
is $@->{exception_code}, 3,
    'Write single register with invalid value to write -- too large';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x0F,
        address  => 23,
        quantity => 0      
    );
};
is $@->{exception_code}, 3,
    'Read Multiple Coils response without qty returns exception';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x0F,
        address  => 23,
        quantity => 1969
    );
};
is $@->{exception_code}, 3,
    'Read Multiple Coils response with a qty too big';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x10,
        address  => 23,
        quantity => 0      
    );
};
is $@->{exception_code}, 3,
    'Read Multiple Registers response without qty returns exception';

eval {
    my $response = Device::Modbus::Response->new(
        code     => 0x10,
        address  => 23,
        quantity => 126
    );
};
is $@->{exception_code}, 3,
    'Read Multiple Registers response with a qty too big';

done_testing();
