#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;

ok( $] >= 5.006, 'Perl version is new enough' );

use_ok( 'Imager::Search'                    );
use_ok( 'Imager::Search::Pattern'           );
use_ok( 'Imager::Search::Image'             );
use_ok( 'Imager::Search::Screenshot' );
use_ok( 'Imager::Search::Driver::HTML24'    );
use_ok( 'Imager::Search::Driver::BMP24'     );
