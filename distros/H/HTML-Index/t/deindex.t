#!/bin/env perl -w
# vim:filetype=perl

use strict;
use warnings;

use Test::More qw( no_plan );
use lib 'blib/lib';
use HTML::Index::Store::BerkeleyDB;
use HTML::Index::Document;
use lib 't';
use Tests;

@test_files = map { "eg/test$_.html" } ( 5, 6 );
my $store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', REFRESH => 1, VERBOSE => $opt_verbose );
for ( map { HTML::Index::Document->new( path => $_ ) } @test_files )
{
    $store->index_document( $_ );
}
undef $store;
$store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', MODE => 'r', VERBOSE => $opt_verbose );
my @r = $store->search( 'simple' );
is_deeply( \@r, [ 'eg/test5.html', 'eg/test6.html' ] );
undef $store;
$store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', VERBOSE => $opt_verbose );
my $doc = HTML::Index::Document->new( path => 'eg/test5.html' );
$store->deindex_document( $doc );
undef $store;
$store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', MODE => 'r', VERBOSE => $opt_verbose );
@r = $store->search( 'simple' );
is_deeply( \@r, [ 'eg/test6.html' ] );
