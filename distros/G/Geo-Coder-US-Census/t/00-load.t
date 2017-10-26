#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::US::Census') || print 'Bail out!';
}

require_ok('Geo::Coder::US::Census') || print 'Bail out!';

diag( "Testing Geo::Coder::US::Census $Geo::Coder::US::Census::VERSION, Perl $], $^X" );
