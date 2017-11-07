#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More tests => 1;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $any_ua  = HTTP::AnyUA->new(ua => 'Mock');
my $backend = $any_ua->backend;

$any_ua->apply_middleware('Runtime');

my $url = 'http://acme.tld/';

my $resp = $any_ua->get($url);
note explain $resp;
isnt $resp->{runtime}, undef, 'runtime is defined';

