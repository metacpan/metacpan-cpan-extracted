#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
unless ( $^O eq 'MSWin32' or $ENV{DISPLAY} ) {
	Test::More->import( skip_all => 'No display' );
} else {
	Test::More->import( tests => 2 );
}
use File::Spec::Functions ':ALL';
use Imager::Search::Screenshot;





#####################################################################
# Trivial Test Files

my $image1 = Imager::Search::Screenshot->new( driver => 'HTML24' );
isa_ok( $image1, 'Imager::Search::Screenshot' );

# Confirm the string is the expected size
my $str_ref  = $image1->string;
my $expected = $image1->width * $image1->height * 7;
is( length($$str_ref), $expected, '->string is the expected length' );
