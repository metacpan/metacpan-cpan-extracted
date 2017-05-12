#!perl -T

use strict;
use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::GooglePlaces') || print 'Bail out!';
}

require_ok('Geo::Coder::GooglePlaces') || print 'Bail out!';

diag( "Testing Geo::Coder::GooglePlaces $Geo::Coder::GooglePlaces::VERSION, Perl $], $^X" );
