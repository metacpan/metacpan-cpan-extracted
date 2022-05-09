use strict;
use warnings;
use Test::More;

use HTTP::SecureHeaders;

sub check { HTTP::SecureHeaders::check_x_permitted_cross_domain_policies(@_) }

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
    ok check($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !check($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
