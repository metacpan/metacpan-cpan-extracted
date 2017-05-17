use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Mercurial;


subtest basic => sub {
    ok( Devel::Cover::Report::Codecov::Service::Mercurial->fallback );
};

done_testing;
