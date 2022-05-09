use strict;
use warnings;
use Test::More;

use HTTP::SecureHeaders;

sub check { HTTP::SecureHeaders::check_content_security_policy(@_) }

# TODO more test cases

my @OK = (
    "default-src 'self'",
    "default-src 'self' https:",

    # default case
    "default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'",

    "webrtc 'allow'",
    "webrtc 'block'",
);

my @NG_for_simplicity = (
);

my @NG = (
    "hoge-src 'self'",
    "default_src 'self'",
    "default-src'self'",
    "default-src  'self'",
    "default-src",
    "default-src ",

    "webrtc 'hoge'",
);

subtest 'OK cases' => sub {
    ok check($_), $_ for @OK;
};

subtest 'NG cases' => sub {
    ok !check($_), $_ for @NG_for_simplicity, @NG;
};

done_testing;
