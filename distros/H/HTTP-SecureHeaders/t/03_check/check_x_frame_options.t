use strict;
use warnings;
use Test::More;

use HTTP::SecureHeaders;

sub check { HTTP::SecureHeaders::check_x_frame_options(@_) }

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
    ok check($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !check($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
