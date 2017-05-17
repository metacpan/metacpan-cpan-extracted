use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Wercker;

sub wercker { 'Devel::Cover::Report::Codecov::Service::Wercker' }

subtest 'if wercker' => sub {
    local $ENV{WERCKER_MAIN_PIPELINE_STARTED} = 1;
    ok( wercker->detect );
};

subtest 'if not wercker' => sub {
    local $ENV{WERCKER_MAIN_PIPELINE_STARTED} = 0;
    ok( not wercker->detect );
};

done_testing;
