use Test2::V0;

use HTTP::SecureHeaders;

my @OK = (
    'noopen',
);

my @NG_for_simplicity = (
);

my @NG = (
    'open',
);

subtest 'OK cases' => sub {
    ok HTTP::SecureHeaders::check_x_download_options($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !HTTP::SecureHeaders::check_x_download_options($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
