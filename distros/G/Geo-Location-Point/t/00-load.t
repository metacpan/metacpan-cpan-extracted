#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Location::Point') || print 'Bail out!';
}

require_ok('Geo::Location::Point') || print 'Bail out!';

diag("Testing Geo::Location::Point $Geo::Location::Point::VERSION, Perl $], $^X");
