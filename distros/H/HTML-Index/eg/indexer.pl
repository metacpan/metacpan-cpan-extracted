#!/usr/bin/perl -w

use strict;

require HTML::Index::Store::BerkeleyDB;
require HTML::Index::Document;
use Getopt::Long;

use vars qw( 
    $opt_parser 
    $opt_refresh 
    $opt_block 
    $opt_db 
    $opt_compress 
    $opt_stopword 
);
die "Usage: $0 [-parser <regex|html>] [-stopword <stopword_file>] [-block <8|16|32>] [-refresh] [-db <db_dir>] [-compress]\n" 
    unless GetOptions qw( stopword=s db=s block=i refresh compress parser=s )
;
my $store = HTML::Index::Store::BerkeleyDB->new(
    VERBOSE             => 1,
    PARSER              => $opt_parser || 'html',
    DB                  => $opt_db,
    STOP_WORD_FILE      => $opt_stopword,
    COMPRESS            => $opt_compress,
    REFRESH             => $opt_refresh,
);

my $i = 0;
my $t0 = time;

for my $file ( @ARGV )
{
    my $doc = HTML::Index::Document->new( path => $file );
    $store->index_document( $doc );
    $i++;
}

my $dt = time - $t0;
my $fps = $dt ? $i / $dt : ">" . $i;
print "$i files indexed in $dt seconds ($fps files per second)\n";
