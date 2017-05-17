use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::AppVeyor;

sub appveyor { 'Devel::Cover::Report::Codecov::Service::AppVeyor' }

subtest 'if appveyor' => sub {
    local $ENV{APPVEYOR} = 1;
    ok( appveyor->detect );
};

subtest 'if not appveyor' => sub {
    local $ENV{APPVEYOR} = 0;
    ok( not appveyor->detect );
};

done_testing;
