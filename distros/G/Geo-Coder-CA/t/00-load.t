#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::CA') || print 'Bail out!';
}

require_ok('Geo::Coder::CA') || print 'Bail out!';

diag( "Testing Geo::Coder::CA $Geo::Coder::CA::VERSION, Perl $], $^X" );
