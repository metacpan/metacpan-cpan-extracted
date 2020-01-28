#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/lib';
use Test::HT;

ht_test(BadRequest => {}, {
    code   => 400,
    reason => 'Bad Request',
});

ht_test(400 => {}, {
    code   => 400,
    reason => 'Bad Request',
});

ht_test(
    Unauthorized => { www_authenticate => 'Basic realm="realm"' },
    {
        code    => 401,
        reason  => 'Unauthorized',
        headers => [ 'WWW-Authenticate' => 'Basic realm="realm"' ],
    },
);

ht_test(
    Unauthorized => {
        www_authenticate => [
            'Basic realm="basic realm"',
            'Digest realm="digest realm"',
        ]
    },
    {
        code    => 401,
        reason  => 'Unauthorized',
        headers => [
            'WWW-Authenticate' => 'Basic realm="basic realm"',
            'WWW-Authenticate' => 'Digest realm="digest realm"',
        ],
    },
);

ht_test(Forbidden => {}, {
    code   => 403,
    reason => 'Forbidden',
});

ht_test(NotFound=> {}, {
    code   => 404,
    reason => 'Not Found',
});

ht_test(MethodNotAllowed => { allow => [ qw(GET PUT) ] }, {
    code    => 405,
    reason  => 'Method Not Allowed',
    headers => [ Allow => 'GET,PUT' ],
});

like(
    exception {
        HTTP::Throwable::Factory->throw(MethodNotAllowed => {
            allow => [ 'GET', 'PUT', 'OPTIONS', 'PUT' ],
        });
    },
    qr/did not pass type constraint.+\{"allow"\}/,
    '... type check works (must be unique list)',
);

like(
    exception {
        HTTP::Throwable::Factory->throw(MethodNotAllowed => {
            allow => [ 'GET', 'PUT', 'OPTIONS', 'TEST' ],
        });
    },
    qr/did not pass type constraint.+\{"allow"\}/,
    '... type check works (must be all known methods)',
);

ht_test(NotAcceptable => {}, {
    code   => 406,
    reason => 'Not Acceptable',
});

ht_test(
    ProxyAuthenticationRequired => {
        proxy_authenticate => 'Basic realm="realm"'
    },
    {
        code    => 407,
        reason  => 'Proxy Authentication Required',
        headers => [ 'Proxy-Authenticate' => 'Basic realm="realm"' ],
    },
);

ht_test(
    ProxyAuthenticationRequired => {
        proxy_authenticate => [
            'Basic realm="realm"',
            'Digest realm="other_realm"',
        ],
    },
    {
        code    => 407,
        reason  => 'Proxy Authentication Required',
        headers => [
            'Proxy-Authenticate' => 'Basic realm="realm"',
            'Proxy-Authenticate' => 'Digest realm="other_realm"',
        ],
    },
);

ht_test(RequestTimeout => {}, {
    code   => 408,
    reason => 'Request Timeout',
});

ht_test(Conflict => {}, {
    code   => 409,
    reason => 'Conflict',
});

done_testing;
