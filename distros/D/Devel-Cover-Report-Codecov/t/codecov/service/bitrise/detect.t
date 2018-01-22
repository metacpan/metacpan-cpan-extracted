use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Bitrise;

subtest 'if bitrise' => sub {
    local $ENV{BITRISE_IO} = 1;
    is(Devel::Cover::Report::Codecov::Service::Bitrise->detect, 1);
};

subtest 'if not bitrise' => sub {
    local %ENV;
    is(Devel::Cover::Report::Codecov::Service::Bitrise->detect, 0);
};

done_testing;
