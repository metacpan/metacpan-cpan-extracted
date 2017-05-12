#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More tests => 10;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $any_ua  = HTTP::AnyUA->new(ua => 'Mock');
my $backend = $any_ua->backend;

my $url = 'http://acme.tld/';

for my $shortcut (qw{get head put post delete}) {
    my $resp    = $any_ua->$shortcut($url);
    my $request = ($backend->requests)[-1];
    is $request->[0], uc($shortcut), "$shortcut shortcut makes a request with the correct method";
    is $request->[1], $url, "$shortcut shortcut makes a request with the correct URL";
}

