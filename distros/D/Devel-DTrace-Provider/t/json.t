use Devel::DTrace::Provider::Builder;
use strict;
use warnings;
use Test::More qw/ no_plan /;

BEGIN {
    provider 'provider0' => as {
        probe 'probe1', 'json';
    };
};

probe1 {
    ok(shift->fire({ foo => 42 }));
};
probe1 {
    ok(shift->fire([1, 2, 3]));
};

probe1 {
    eval {
        shift->fire(undef);
    };
    ok($!);
};

ok(1);
