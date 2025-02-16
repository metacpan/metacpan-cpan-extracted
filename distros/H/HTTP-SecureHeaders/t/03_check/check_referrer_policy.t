use Test2::V0;

use HTTP::SecureHeaders;

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
    ok HTTP::SecureHeaders::check_referrer_policy($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !HTTP::SecureHeaders::check_referrer_policy($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
