#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::WWWAuthenticate');
}

sub test_basic {
    my $www_authen = shift;

    is($www_authen->auth_type, 'Basic', '... got the right auth type');
    is($www_authen->realm, 'WallyWorld', '... got the right realm');

    is_deeply(
        $www_authen->params,
        { realm => 'WallyWorld' },
        '... got the parameters we expected'
    );

    is($www_authen->as_string, 'Basic realm="WallyWorld"', '... got the right stringification');
}

sub test_digest {
    my $www_authen = shift;

    is($www_authen->auth_type, 'Digest', '... got the right auth type');
    is($www_authen->realm, 'testrealm@host.com', '... got the right realm');

    is_deeply(
        $www_authen->params,
        {
            realm  => 'testrealm@host.com',
            qop    => "auth,auth-int",
            nonce  => "dcd98b7102dd2f0e8b11d0f600bfb0c093",
            opaque => "5ccc069c403ebaf9f0171e9517f40e41"
        },
        '... got the parameters we expected'
    );

    is(
        $www_authen->as_string,
        'Digest realm="testrealm@host.com", qop="auth,auth-int", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", opaque="5ccc069c403ebaf9f0171e9517f40e41"',
        '... got the right stringification'
    );
}


test_basic(
    HTTP::Headers::ActionPack::WWWAuthenticate->new_from_string(
        'Basic realm="WallyWorld"'
    )
);

test_basic(
    HTTP::Headers::ActionPack::WWWAuthenticate->new(
        'Basic' => (
            realm => "WallyWorld"
        )
    )
);


test_digest(
    HTTP::Headers::ActionPack::WWWAuthenticate->new_from_string(
        'Digest realm="testrealm@host.com", qop="auth,auth-int", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", opaque="5ccc069c403ebaf9f0171e9517f40e41"'
    )
);

test_digest(
    HTTP::Headers::ActionPack::WWWAuthenticate->new(
        'Digest' => (
            realm  => 'testrealm@host.com',
            qop    => "auth,auth-int",
            nonce  => "dcd98b7102dd2f0e8b11d0f600bfb0c093",
            opaque => "5ccc069c403ebaf9f0171e9517f40e41"
        )
    )
);

done_testing;