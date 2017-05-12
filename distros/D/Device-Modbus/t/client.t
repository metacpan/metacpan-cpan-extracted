#! /usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use Test::More;
BEGIN {
    use_ok('TestClient');
    use_ok('Device::Modbus::ADU');
};

done_testing();
