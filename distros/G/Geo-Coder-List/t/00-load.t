#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::List') || print 'Bail out!';
}

require_ok('Geo::Coder::List') || print 'Bail out!';

diag( "Testing Geo::Coder::List $Geo::Coder::List::VERSION, Perl $], $^X" );
