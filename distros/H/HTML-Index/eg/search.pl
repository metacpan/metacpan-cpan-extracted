#!/usr/bin/perl -w

use strict;

require HTML::Index::Store::BerkeleyDB;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

use vars qw( $opt_db );
die "Usage: $0 [-db <db dir>]\n" unless GetOptions qw( db=s );

my $q = join( ' ', @ARGV );
my $t0 = gettimeofday;
my $store = HTML::Index::Store::BerkeleyDB->new( DB => $opt_db );
my @results = $store->search( $q );
my $dt = gettimeofday - $t0;
print map { "$_\n" } @results;
printf "%d results for $q returned in %0.3f secs\n", scalar( @results ), $dt;
