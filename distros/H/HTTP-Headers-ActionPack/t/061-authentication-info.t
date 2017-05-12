#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::AuthenticationInfo');
}

sub test_auth_info {
    my $auth_info = shift;

    is_deeply(
        $auth_info->params,
        {
            qop     => 'auth-int',
            rspauth => "6629fae49393a05397450978507c4ef1",
            cnonce  => "0a4f113b",
            nc      => '00000001'
        },
        '... got the expected params'
    );

    is(
        $auth_info->as_string,
        'qop="auth-int", rspauth="6629fae49393a05397450978507c4ef1", cnonce="0a4f113b", nc="00000001"',
        '... got the right stringification'
    );
}

test_auth_info(
    HTTP::Headers::ActionPack::AuthenticationInfo->new_from_string(
        'qop=auth-int, rspauth="6629fae49393a05397450978507c4ef1", cnonce="0a4f113b", nc=00000001'
    )
);

test_auth_info(
    HTTP::Headers::ActionPack::AuthenticationInfo->new(
        qop     => 'auth-int',
        rspauth => "6629fae49393a05397450978507c4ef1",
        cnonce  => "0a4f113b",
        nc      => '00000001'
    )
);

done_testing;