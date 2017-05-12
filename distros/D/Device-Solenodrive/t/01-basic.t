#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# This test runs basic module tests

use strict;
use Test::More;

BEGIN { use_ok 'Device::Solenodrive'; }
BEGIN { use_ok 'Test::Exception'; }
require Test::Exception;

# Check we get an error message on missing input parameters
my $soleno;

can_ok( 'Device::Solenodrive', qw(device) );

throws_ok { $soleno = Device::Solenodrive->new() }
qr/Attribute .+ is required at constructor/, "Checking missing parameters";

$soleno = Device::Solenodrive->new( device => '/dev/ttyUSB0' );
ok $soleno, 'object created';
ok $soleno->isa('Device::Solenodrive'), 'and it is the right class';

done_testing();
