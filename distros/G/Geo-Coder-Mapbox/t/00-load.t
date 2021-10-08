#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Geo::Coder::Mapbox') || print 'Bail out!';
}

require_ok('Geo::Coder::Mapbox') || print 'Bail out!';

diag("Testing Geo::Coder::Mapbox $Geo::Coder::Mapbox::VERSION, Perl $], $^X");
