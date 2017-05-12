#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::CookieMonster qw( cookies );
use URI::Heuristic qw(uf_uristr);
use WWW::Mechanize;

die "usage perl examples/read_cookies.pl http://www.nytimes.com" if !@ARGV;
my $url = uf_uristr( shift @ARGV );

my $mech = WWW::Mechanize->new;
$mech->get( $url );

my @cookies = cookies( $mech->cookie_jar );

foreach my $cookie ( @cookies ) {
    printf( "name: %s\tvalue: %s\n", $cookie->key, $cookie->val );
}
