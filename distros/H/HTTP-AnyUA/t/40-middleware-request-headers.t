#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More tests => 5;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $any_ua  = HTTP::AnyUA->new(ua => 'Mock');
my $backend = $any_ua->backend;

$any_ua->apply_middleware('RequestHeaders',
    headers => {
        whatever => 'meh',
        Foo      => 'bar',
    },
);

my $url     = 'http://acme.tld/';

$any_ua->get($url, {headers => {baz => 'qux'}});
my $headers = ($backend->requests)[-1][2]{headers};
is $headers->{whatever}, 'meh', 'custom header with GET';
is $headers->{foo}, 'bar', 'normalized header';
is $headers->{baz}, 'qux', 'request header left intact';

$any_ua->get($url, {headers => {baz => 'qux', foo => 'moof'}});
$headers = ($backend->requests)[-1][2]{headers};
is $headers->{foo}, 'moof', 'request header takes precedence';

$any_ua  = HTTP::AnyUA->new(ua => 'Mock');
$backend = $any_ua->backend;

$any_ua->apply_middleware('RequestHeaders',
    headers => {
        Foo => 'bar',
    },
    override => 1,
);

$any_ua->get($url, {headers => {foo => 'moof'}});
$headers = ($backend->requests)[-1][2]{headers};
is $headers->{foo}, 'bar', 'custom header takes precedence if override on';

