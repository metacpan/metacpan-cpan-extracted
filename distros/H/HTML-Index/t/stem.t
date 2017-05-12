#!/bin/env perl -w
# vim:filetype=perl

use strict;
use warnings;

use Test::More qw( no_plan );
use lib 'blib/lib';
use HTML::Index::Document;
use HTML::Index::Store::BerkeleyDB;
use lib 't';
use Tests;

@tests = (
    { q => 'stuff', paths => [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html', ] },
    { q => 'differing', paths => [ 'eg/test3.html' ] },
    { q => 'stuffs', paths => [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html', ] },
    { q => 'differs', paths => [ 'eg/test3.html' ] },
);

my $store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', STEM => 'en-uk', REFRESH => 1, VERBOSE => $opt_verbose );
for ( map { HTML::Index::Document->new( path => $_ ) } @test_files )
{
    $store->index_document( $_ );
}
undef $store;
$store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', MODE => 'r', VERBOSE => $opt_verbose );
for ( @tests ) { is_deeply( [ $store->search( $_->{q} ) ], $_->{paths} ); }
