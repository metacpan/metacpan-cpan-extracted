#!perl

use 5.010;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone unbless uniq);
use Test::More 0.98;

subtest "unbless" => sub {
    local $Function::Fallback::CoreOrPP::USE_NONCORE_XS_FIRST = 0;
    is_deeply(unbless(bless({}, "x")), {}, 'hash ref');
    is_deeply(unbless(bless([], "x")), [], 'array ref');
    is_deeply(unbless(bless(\( my $scalar = 1 ), "x")), \1, 'scalar ref');
    is_deeply(unbless(bless(sub { 42 }, "x"))->(), 42, "code ref");
};

subtest "uniq" => sub {
    local $Function::Fallback::CoreOrPP::USE_NONCORE_XS_FIRST = 0;
    is_deeply([uniq(1, 3, 2, 1, 3, 4)], [1, 3, 2, 4]);
};

DONE_TESTING:
done_testing();
