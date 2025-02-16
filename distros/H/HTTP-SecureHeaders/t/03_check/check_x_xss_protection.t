use Test2::V0;

use HTTP::SecureHeaders;

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
    ok HTTP::SecureHeaders::check_x_xss_protection($_), "case: $_" for @OK;
};

subtest 'NG cases' => sub {
    ok !HTTP::SecureHeaders::check_x_xss_protection($_), "case: $_" for @NG_for_simplicity, @NG;
};

done_testing;
