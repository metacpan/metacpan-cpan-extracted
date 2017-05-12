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

my $store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', REFRESH => 1, VERBOSE => $opt_verbose );
for ( map { HTML::Index::Document->new( path => $_, parser => 'regex' ) } @test_files )
{
    $store->index_document( $_ );
}
undef $store;
$store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', MODE => 'r', VERBOSE => $opt_verbose );
for ( @tests ) { is_deeply( [ $store->search( $_->{q} ) ], $_->{paths} ); }
