use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Magnum;

sub magnum { 'Devel::Cover::Report::Codecov::Service::Magnum' }

subtest 'if Magnum CI' => sub {
    local $ENV{MAGNUM} = 'true';
    ok( magnum->detect );
};

subtest 'if not Magnum CI' => sub {
    local %ENV;
    ok( not magnum->detect );
};

done_testing;
