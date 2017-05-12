use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Semaphore;

sub semaphore { 'Devel::Cover::Report::Codecov::Service::Semaphore' }

subtest 'if semaphore' => sub {
    local $ENV{SEMAPHORE} = 1;
    ok( semaphore->detect );
};

subtest 'if not semaphore' => sub {
    local %ENV;
    ok( not semaphore->detect );
};

done_testing;
