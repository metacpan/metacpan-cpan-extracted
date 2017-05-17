use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Shippable;

sub detect {
    return Devel::Cover::Report::Codecov::Service::Shippable->detect(@_);
}

subtest 'if Shippable' => sub {
    local %ENV = ( SHIPPABLE => 1 );
    ok( detect );
};

subtest 'if not Shippable' => sub {
    local %ENV;
    ok( not detect );
};

done_testing;
