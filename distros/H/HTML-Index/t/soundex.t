#!/bin/env perl -w
# vim:filetype=perl

use strict;
use warnings;

use Test::More qw( no_plan );
use lib 'blib/lib';
use HTML::Index::Document;
use HTML::Index::Store::DataDumper;
use lib 't';
use Tests;

my $store = HTML::Index::Store::DataDumper->new( DB => 'db', REFRESH => 1, SOUNDEX => 1, VERBOSE => $opt_verbose );
for ( map { HTML::Index::Document->new( path => $_ ) } @test_files )
{
    $store->index_document( $_ );
}
undef $store;
$store = HTML::Index::Store::DataDumper->new( DB => 'db', MODE => 'r', VERBOSE => $opt_verbose );
is_deeply( [ $store->search( 'stuff', SOUNDEX => 1 ) ], [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html' ] );
is_deeply( [ $store->search( 'stuf', SOUNDEX => 1 ) ], [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html' ] );
is_deeply( [ $store->search( 'stuf', SOUNDEX => 0 ) ], [ ] );
