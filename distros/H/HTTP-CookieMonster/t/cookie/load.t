#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::CookieMonster::Cookie ();
use Test::More;

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

isa_ok( $cookie, 'HTTP::CookieMonster::Cookie' );

done_testing();
