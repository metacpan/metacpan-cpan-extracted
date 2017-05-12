#!/usr/bin/env perl

# For more info on why these tests are important, see RT #56757 and RT #5705

use strict;
use warnings;
use lib 't';

use Find::Lib;
use File::Spec;
use Test::More tests => 64;
use TestCache;

BEGIN {
    use_ok('LWPx::UserAgent::Cached');
}

my $cache = TestCache->new();
isa_ok( $cache, 'TestCache' );

my $mech = LWPx::UserAgent::Cached->new( cache => $cache );
isa_ok( $mech, 'LWPx::UserAgent::Cached' );

ok( !$mech->ref_in_cache_key,
    "Referring URLs in cache key disabled by default" );

my @iter = ( 1 .. 10 );
foreach my $i (@iter) {
    my $response = $mech->get( page_url($i) );
    cmp_ok( $response->content, '==', $i, "page $i has correct content" );
    ok( !$mech->is_cached, "page $i NOT in cache" );
}

check_cache(@iter);

note 'reversing page order';

check_cache( reverse @iter );

sub check_cache {

    my @pages = @_;
    foreach my $i (@pages) {
        my $response = $mech->get( page_url($i) );
        cmp_ok( $response->content, 'eq', 'DUMMY',
            "page $i has correct content" );
        ok( $mech->is_cached, "page $i IS in cache" );
    }
}

sub page_url {

    my $i      = shift;
    my $prefix = 'file://';
    $prefix .= '/' if $^O =~ m{Win};
    return $prefix
        . File::Spec->catfile( Find::Lib::base(), 'pages', "$i.html" );

}

