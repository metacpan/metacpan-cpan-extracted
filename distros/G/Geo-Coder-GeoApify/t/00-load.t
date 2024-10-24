#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Geo::Coder::GeoApify') || print 'Bail out!';
}

require_ok('Geo::Coder::GeoApify') || print 'Bail out!';

diag("Testing Geo::Coder::GeoApify $Geo::Coder::GeoApify::VERSION, Perl $], $^X");
