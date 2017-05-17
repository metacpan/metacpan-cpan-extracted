use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Travis;

sub travis { 'Devel::Cover::Report::Codecov::Service::Travis' }

subtest 'if travis' => sub {
    local $ENV{TRAVIS} = 1;
    ok( travis->detect );
};

subtest 'if not travis' => sub {
    local $ENV{TRAVIS} = 0;
    ok( not travis->detect );
};

done_testing;
