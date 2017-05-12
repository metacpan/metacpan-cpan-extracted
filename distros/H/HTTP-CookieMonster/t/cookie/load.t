#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use HTTP::CookieMonster::Cookie;

my $cookie = HTTP::CookieMonster::Cookie->new(
    version   => 0,
    key       => 'foo',
    val       => 'bar',
    path      => '/',
    domain    => '.metacpan.org',
    port      => 80,
    path_spec => 1,
    secure    => 1,
    expires   => 1376081877,
    discard   => undef,
    hash      => {},
);

isa_ok( $cookie, "HTTP::CookieMonster::Cookie" );

diag "val: " . $cookie->val;
diag "key: " . $cookie->key;

done_testing();
