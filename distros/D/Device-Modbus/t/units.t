use Test::More tests => 22;
use strict;
use warnings;

use Data::Dumper;

BEGIN { use_ok 'Device::Modbus::Unit' }

{

    my $unit = Device::Modbus::Unit->new(id => 3);

    isa_ok $unit, 'Device::Modbus::Unit';
    is  $unit->id, 3,
        'Unit created successfully and ID is correct';

    is ref $unit->routes->{'holding_registers:read'}, 'ARRAY',
        'Addresses will be stored in a hash of array refs';
    is scalar @{$unit->routes->{'holding_registers:read'}}, 0,
        'The arrays start empty';

    #                Zone           addr  qty    method
    #           ------------------- ----- --- -----------------
    $unit->get('holding_registers', '1-5', 5,  sub { return 6 });

    is scalar @{$unit->routes->{'holding_registers:read'}}, 1,
        'Added an address to the holding_registers:read array';

    my $match = $unit->route('holding_registers', 'read', 3, 5);

    isa_ok $match, 'Device::Modbus::Unit::Route',
        'Routing mechanism works';

    is $match->routine->(), 6,
        "Executing 'get' routine works fine";
    undef $match;

    $match = $unit->route('holding_registers', 'read', 6, 5);
    is $match, 2,
        'Code 2: Address did not match';
    undef $match;

    $match = $unit->route('holding_registers', 'read', 3, 6);
    is $match, 2,
        'Code 2: Address matches but quantity does not';
    undef $match;


    #                Zone            addr  qty    method
    #           -------------------  ---- -----  -----------------
    $unit->put('holding_registers',   33, '1,3',  sub { return 19 });

    is scalar @{$unit->routes->{'holding_registers:write'}}, 1,
        'Added an address to the holding_registers:write array';

    $match = $unit->route('holding_registers', 'write', 33, 3);

    isa_ok $match, 'Device::Modbus::Unit::Route',
        'Routing mechanism works';

    is $match->routine->(), 19,
        "Executing 'put' routine works fine";
}

{
    package Hello;

    use parent 'Device::Modbus::Unit';

    sub hello {
        return 'Dolly';
    }

    sub good_bye {
        return 'Adieu';
    }
}

my $unit = Hello->new(id => 4);

#                Zone            addr qty   method
#           -------------------  ---- ---  ---------
$unit->put('holding_registers',    2,  1,  'hello');
$unit->get('holding_registers',    6,  1,  'good_bye');

my $match = $unit->route('holding_registers','write', 2,1);
isa_ok $match, 'Device::Modbus::Unit::Route';

is $match->routine->(), 'Dolly',
    'Named methods can be entered into the dispatch table -- put';

$match = $unit->route('holding_registers','read', 6, 1);
isa_ok $match, 'Device::Modbus::Unit::Route';

is $match->routine->(), 'Adieu',
    'Named methods can be entered into the dispatch table -- get';

eval {
    $unit->put('holding_registers', 2, 1, 'non-existent');
};
like $@, qr/could not resolve a code reference/,
    "'put' requires a valid method name or code reference";

eval {
    $unit->put('holding_registers', 2, 1, {});
};
like $@, qr/could not resolve a code reference/,
    "'put' requires a valid method name or code reference";

eval {
    $unit->get('holding_registers', 2, 1, 'non-existent');
};
like $@, qr/could not resolve a code reference/,
    "'get' requires a valid method name or code reference";

eval {
    $unit->get('holding_registers', 2, 1, {});
};
like $@, qr/could not resolve a code reference/,
    "'get' requires a valid method name or code reference";

eval {
    my $unit = Hello->new();
};
like $@, qr/Missing required parameter/,
    'You cannot create a unit without ID number';

done_testing();
