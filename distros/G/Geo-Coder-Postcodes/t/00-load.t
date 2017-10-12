#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::Postcodes') || print 'Bail out!';
}

require_ok('Geo::Coder::Postcodes') || print 'Bail out!';

diag( "Testing Geo::Coder::Postcodes $Geo::Coder::Postcodes::VERSION, Perl $], $^X" );
