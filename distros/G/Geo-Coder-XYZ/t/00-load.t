#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::XYZ') || print 'Bail out!';
}

require_ok('Geo::Coder::XYZ') || print 'Bail out!';

diag( "Testing Geo::Coder::XYZ $Geo::Coder::XYZ::VERSION, Perl $], $^X" );
