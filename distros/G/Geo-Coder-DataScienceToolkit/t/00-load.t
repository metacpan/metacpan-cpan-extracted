#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::DataScienceToolkit') || print 'Bail out!';
}

require_ok('Geo::Coder::DataScienceToolkit') || print 'Bail out!';

diag( "Testing Geo::Coder::DataScienceToolkit $Geo::Coder::DataScienceToolkit::VERSION, Perl $], $^X" );
