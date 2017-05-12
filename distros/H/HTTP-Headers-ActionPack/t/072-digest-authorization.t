#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::Authorization::Digest');
}

sub test_auth {
    my $auth = shift;

    is($auth->auth_type, 'Digest', '... got the right auth type');
    is($auth->username, 'jon.dough@mobile.biz', '... got the right username');
    is($auth->realm, 'RoamingUsers@mobile.biz', '... got the right realm');


    is_deeply(
        $auth->params,
        {
            username => 'jon.dough@mobile.biz',
            realm    => 'RoamingUsers@mobile.biz',
            nonce    => "CjPk9mRqNuT25eRkajM09uTl9nM09uTl9nMz5OX25PZz==",
            uri      => "sip:home.mobile.biz",
            qop      => 'auth-int',
            nc       => '00000001',
            cnonce   => "0a4f113b",
            response => "6629fae49393a05397450978507c4ef1",
            opaque   => "5ccc069c403ebaf9f0171e9517f40e41"
        },
        '... got the right params list'
    );

    is(
        $auth->as_string,
        q{Digest username="jon.dough@mobile.biz", realm="RoamingUsers@mobile.biz", nonce="CjPk9mRqNuT25eRkajM09uTl9nM09uTl9nMz5OX25PZz==", uri="sip:home.mobile.biz", qop="auth-int", nc="00000001", cnonce="0a4f113b", response="6629fae49393a05397450978507c4ef1", opaque="5ccc069c403ebaf9f0171e9517f40e41"},
          '... got the right stringification'
    );
}

test_auth(
    HTTP::Headers::ActionPack::Authorization::Digest->new_from_string(
        q{Digest
          username="jon.dough@mobile.biz",
          realm="RoamingUsers@mobile.biz",
          nonce="CjPk9mRqNuT25eRkajM09uTl9nM09uTl9nMz5OX25PZz==",
          uri="sip:home.mobile.biz",
          qop=auth-int,
          nc=00000001,
          cnonce="0a4f113b",
          response="6629fae49393a05397450978507c4ef1",
          opaque="5ccc069c403ebaf9f0171e9517f40e41"}
    )
);

test_auth(
    HTTP::Headers::ActionPack::Authorization::Digest->new(
        'Digest' => (
            username => 'jon.dough@mobile.biz',
            realm    => 'RoamingUsers@mobile.biz',
            nonce    => "CjPk9mRqNuT25eRkajM09uTl9nM09uTl9nMz5OX25PZz==",
            uri      => "sip:home.mobile.biz",
            qop      => 'auth-int',
            nc       => '00000001',
            cnonce   => "0a4f113b",
            response => "6629fae49393a05397450978507c4ef1",
            opaque   => "5ccc069c403ebaf9f0171e9517f40e41"
        )
    )
);

done_testing;