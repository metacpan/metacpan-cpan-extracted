#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use Imager::Search::Image ();

my $file1 = catfile( 't', 'data', 'basic', 'big2.bmp');
ok( -f $file1, 'Test file 1 exists' );





#####################################################################
# Trivial Test Files

my $image1 = Imager::Search::Image->new(
	driver => 'Imager::Search::Driver::HTML24',
	file   => $file1,
);
isa_ok( $image1, 'Imager::Search::Image' );
