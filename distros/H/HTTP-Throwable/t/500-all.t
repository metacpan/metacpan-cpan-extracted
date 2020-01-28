#!/usr/bin/perl
use strict;
use warnings;

use Test::Deep qw(ignore re);
use Test::More;
use Test::Fatal;

use lib 't/lib';
use Test::HT;

ht_test(InternalServerError => {}, {
    code   => 500,
    reason => 'Internal Server Error',
    length => ignore(),
    body   => re(qr{500 Internal Server Error.+at t.lib.Test.HT.pm}s),
});

ht_test(NotImplemented => {}, {
    code   => 501,
    reason => 'Not Implemented',
});

ht_test(BadGateway => {}, {
    code   => 502,
    reason => 'Bad Gateway',
});

ht_test(ServiceUnavailable => { retry_after => 'A Little While' }, {
    code    => 503,
    reason  => 'Service Unavailable',
    headers => [ 'Retry-After' => 'A Little While' ],
});

ht_test(GatewayTimeout => {}, {
    code   => 504,
    reason => 'Gateway Timeout',
});

ht_test(HTTPVersionNotSupported => {}, {
    code   => 505,
    reason => 'HTTP Version Not Supported',
});

done_testing;
