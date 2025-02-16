use Test2::V0;

use HTTP::SecureHeaders;

my @OK = (
    'none',
    'master-only',
    'by-content-type',
    'by-ftp-filename',
    'all',
);

my @NG_for_simplicity = (
);

my @NG = (
    'nonenone',
    'xnone',
    'NONE',
);

subtest 'OK cases' => sub {
    ok HTTP::SecureHeaders::check_x_permitted_cross_domain_policies($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !HTTP::SecureHeaders::check_x_permitted_cross_domain_policies($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
