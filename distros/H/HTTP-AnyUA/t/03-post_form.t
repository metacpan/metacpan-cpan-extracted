#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More tests => 4;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $any_ua  = HTTP::AnyUA->new(ua => 'Mock');
my $backend = $any_ua->backend;

my $url = 'http://acme.tld/';
my $form = {
    foo => 'bar',
    baz => 42,
};
my $resp = $any_ua->post_form($url, $form);

my $request = ($backend->requests)[-1];

is $request->[0], 'POST', 'post_form request method is POST';
is $request->[1], $url, 'post_form request URL is correct';
is $request->[2]{content}, 'baz=42&foo=bar', 'post_form request body is correct';
is $request->[2]{headers}{'content-type'}, 'application/x-www-form-urlencoded', 'post_form request content-type header is correct';

