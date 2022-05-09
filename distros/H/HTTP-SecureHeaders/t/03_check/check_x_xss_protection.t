use strict;
use warnings;
use Test::More;

use HTTP::SecureHeaders;

sub check { HTTP::SecureHeaders::check_x_xss_protection(@_) }

my @OK = (
    '0',
    '1',
    '1; mode=block',
);

my @NG_for_simplicity = (
    '1; report=xxx'
);

my @NG = (
    '2',
    '1; mode=hoge',
);

subtest 'OK cases' => sub {
    ok check($_), "case: $_" for @OK;
};

subtest 'NG cases' => sub {
    ok !check($_), "case: $_" for @NG_for_simplicity, @NG;
};

done_testing;
