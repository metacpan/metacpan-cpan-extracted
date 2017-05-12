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

my $store = HTML::Index::Store->new( VERBOSE => $opt_verbose );
for ( map { HTML::Index::Document->new( path => $_ ) } @test_files )
{
    $store->index_document( $_ );
}
for ( @tests ) { is_deeply( [ $store->search( $_->{q} ) ], $_->{paths} ); }
