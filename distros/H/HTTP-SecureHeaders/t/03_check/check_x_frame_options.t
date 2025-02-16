use Test2::V0;

use HTTP::SecureHeaders;

my @OK = (
    'SAMEORIGIN',
    'DENY',
);

my @NG_for_simplicity = (
    'ALLOW-FROM https://metacpan.org' # deprecated
);

my @NG = (
    'HOGE',
    'sameorigin',
    'deny',
);

subtest 'OK cases' => sub {
    ok HTTP::SecureHeaders::check_x_frame_options($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !HTTP::SecureHeaders::check_x_frame_options($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
