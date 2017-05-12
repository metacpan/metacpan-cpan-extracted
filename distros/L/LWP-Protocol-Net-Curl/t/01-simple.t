#!perl
use strict;
use utf8;
use warnings qw(all);

# HACK! LWP::Simple insist running $ua->env_proxy on initialization
BEGIN { /_proxy$/ix and delete $ENV{$_} for keys %ENV };

use Net::Curl::Easy qw(:constants);

use LWP::Protocol::Net::Curl
    takeover        => 0,
    CURLOPT_ENCODING=> '',
    CURLOPT_REFERER ,=> q(http://localhost/),
    httpheader      => [qq(X-User-Agent: @{[ Net::Curl::version ]})];

use LWP::Simple;
use Test::HTTP::Server;
use Test::More;

## no critic (ProhibitPackageVars)
ok(
    grep { /^https?$/x } @LWP::Protocol::Net::Curl::implements,
    q(implements: ) . join(q(/), @LWP::Protocol::Net::Curl::implements)
);

ok(
    $LWP::Protocol::Net::Curl::implements{http},
    q(implements HTTP)
);

my $server = Test::HTTP::Server->new;

unlike(
    get($server->uri . q(echo/head)),
    qr/\Q@{[ Net::Curl::version ]}\E/sx,
    q(original LWP)
);

LWP::Protocol::implementor(http => q(LWP::Protocol::Net::Curl));

like(
    get($server->uri . q(echo/head)),
    qr/\Q@{[ Net::Curl::version ]}\E/sx,
    q(GET)
);

like(
    (head($server->uri . q(repeat/10/qwerty)))[0],
    qr(^text/plain$)ix,
    q(HEAD)
);

done_testing(5);
