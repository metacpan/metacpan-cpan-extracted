#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use Imager::Search                ();
use Imager::Search::Image         ();
use Imager::Search::Pattern       ();
use Imager::Search::Driver::BMP24 ();

my $small = catfile( 't', 'data', 'basic', 'small1.bmp' );
ok( -f $small, 'Found small file' );

my $big = catfile( 't', 'data', 'basic', 'big1.bmp' );
ok( -f $big, 'Found big file' );





#####################################################################
# Execute the search

my $pattern = Imager::Search::Pattern->new(
	driver => 'Imager::Search::Driver::BMP24',
	file   => $small,
);
isa_ok( $pattern, 'Imager::Search::Pattern' );

my $target = Imager::Search::Image->new(
	driver => 'Imager::Search::Driver::BMP24',
	file   => $big,
);
isa_ok( $target, 'Imager::Search::Image' );

my @matches = $target->find( $pattern );
my $boolean = $target->find_any( $pattern );




#####################################################################
# Check the results

is( scalar(@matches), 2, 'Found 2 matches' );
is( $boolean, 1, 'find_any ok' );
