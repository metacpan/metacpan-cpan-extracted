#! /usr/bin/env perl

use lib 't/lib';
use Test::Unit;
use Test::Server;
use Test::More tests => 5;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Server';
    use_ok 'TestServer';
}

my $server = TestServer->new();

{
    eval {
        $server->add_server_unit('Non-existent', 3);
    };
    like $@, qr/Units must be subclasses/,
        'add_server_unit croaks with a non-reference';
}

{
    my $unit = bless {}, 'Fake::Unit';
    eval {
        $server->add_server_unit($unit, 3);
    };
    like $@, qr/Units must be subclasses/,
        'add_server_unit croaks with a reference that is not a unit';
}

eval {
    my $unit = Test::Unit->new;
    $server->add_server_unit($unit);
};
like $@, qr/subclasses must implement init_unit/,
    'Units must be subclassed from Device::Modbus::Unit';

done_testing();
