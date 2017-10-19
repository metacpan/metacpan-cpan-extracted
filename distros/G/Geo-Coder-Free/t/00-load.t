#!perl -T

use strict;
use lib './lib';

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::Free') || print 'Bail out!';
}

require_ok('Geo::Coder::Free') || print 'Bail out!';

diag( "Testing Geo::Coder::Free $Geo::Coder::Free::VERSION, Perl $], $^X" );
