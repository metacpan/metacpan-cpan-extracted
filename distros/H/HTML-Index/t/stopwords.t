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
    { q => 'some', paths => [ ] },
    { q => 'some AND NOT some', paths => [ ] },
    { q => 'some OR stuff', paths => [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html', ] },
    { q => 'some OR ( stuff AND NOT more )', paths => [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html', ] },
    { q => 'some OR ( stuff AND NOT sample )', paths => [ 'eg/test2.html' ] },
    { q => '( more OR stuff ) OR ( sample AND stuff )', paths => [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html', ] },
    { q => 'different', paths => [ 'eg/test3.html' ] },
);

my $store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', REFRESH => 1, STOP_WORD_FILE => 'eg/stopwords.txt', VERBOSE => $opt_verbose );
for ( map { HTML::Index::Document->new( path => $_ ) } @test_files )
{
    $store->index_document( $_ );
}
undef $store;
$store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', MODE => 'r', VERBOSE => $opt_verbose );
for ( @tests ) { is_deeply( [ $store->search( $_->{q} ) ], $_->{paths} ); }

