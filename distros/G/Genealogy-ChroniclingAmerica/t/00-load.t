#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Genealogy::ChroniclingAmerica') || print 'Bail out!';
}

require_ok('Genealogy::ChroniclingAmerica') || print 'Bail out!';

diag( "Testing Genealogy::ChroniclingAmerica $Genealogy::ChroniclingAmerica::VERSION, Perl $], $^X" );
