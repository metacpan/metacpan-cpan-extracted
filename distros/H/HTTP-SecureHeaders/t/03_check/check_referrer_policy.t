use strict;
use warnings;
use Test::More;

use HTTP::SecureHeaders;

sub check { HTTP::SecureHeaders::check_referrer_policy(@_) }

my @OK = (
    'strict-origin-when-cross-origin',
    'no-referrer',
    'no-referrer-when-downgrade',
    'same-origin',
    'origin',
    'strict-origin',
    'origin-when-cross-origin',
    'unsafe-url',
);

my @NG_for_simplicity = (
    '',
);

my @NG = (
    'hoge'
);

subtest 'OK cases' => sub {
    ok check($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !check($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
