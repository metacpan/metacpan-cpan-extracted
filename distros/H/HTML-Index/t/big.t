#!/bin/env perl -w
# vim:filetype=perl

use strict;
use warnings;

use constant ntests => 100;
use constant nwords => 10;

use Test::More tests => ntests * nwords;
use lib 'blib/lib';
use HTML::Index::Store::BerkeleyDB;
use HTML::Index::Document;
use IO::File;
use lib 't';
use Tests;

my $store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', REFRESH => 1, STOP_WORD_FILE => 'eg/stopwords.txt', VERBOSE => $opt_verbose );
my @dict = map { "word$_" } ( 1 .. ntests );
my %index;
my %words;
my %files;
if ( my $fh = IO::File->new( '/usr/dict/words' ) )
{
    @dict = <$fh>;
    chomp( @dict );
    @dict = $store->filter( @dict );
}
srand;
for ( 1 .. ntests )
{
    my @w = 
        map { $dict[$_] } 
        map { int( rand( $#dict ) ) } 
        ( 1 .. nwords )
    ;
    my $name = "file$_";
    my $doc = HTML::Index::Document->new(
        name            => $name,
        contents        => "<html><body><p>@w</p></body></html>",
    );
    $files{$name} = "@w\n";
    for ( @w )
    {
        $words{$_} = 1;
        $index{$_}{$name}++;
    }
    $store->index_document( $doc );
}
undef $store;
$store = HTML::Index::Store::BerkeleyDB->new( DB => 'db', MODE => 'r', VERBOSE => $opt_verbose );
for my $w ( keys %words )
{ 
    my @r1 = sort keys %{$index{$w}};
    my @r2 = sort $store->search( $w );
    my $failed = 0;
    for ( 0 .. $#r1 )
    {
        is( $r1[$_], $r2[$_] ); 
        $failed++ if not defined $r2[$_] or $r1[$_] ne $r2[$_];
    }
    warn "$w : @r1 : @r2\n" if $failed;
}
