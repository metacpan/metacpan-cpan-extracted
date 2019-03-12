#!perl

use warnings;
use strict;

use lib 't/lib';

use Future;
use HTTP::AnyUA;
use Test::More tests => 2;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $any_ua  = HTTP::AnyUA->new(ua => 'Mock');
my $backend = $any_ua->backend;

$any_ua->apply_middleware('Runtime');

my $url = 'http://acme.tld/';
my $mock_response = {
    success => 1,
    status  => 200,
    reason  => 'OK',
    content => 'whatever',
};

$backend->response({%$mock_response});
my $resp = $any_ua->get($url);
note explain $resp;
isnt $resp->{runtime}, undef, 'runtime is defined';

$backend->response(Future->done({%$mock_response}));
$resp = $any_ua->get($url);
$resp->on_done(sub {
    my $resp = shift;
    note explain $resp;
    isnt $resp->{runtime}, undef, 'runtime is defined when response is future';
});

