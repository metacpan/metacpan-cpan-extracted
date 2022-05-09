use strict;
use warnings;
use Test::More;

use HTTP::SecureHeaders;

sub check { HTTP::SecureHeaders::check_x_download_options(@_) }

my @OK = (
    'noopen',
);

my @NG_for_simplicity = (
);

my @NG = (
    'open',
);

subtest 'OK cases' => sub {
    ok check($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !check($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
