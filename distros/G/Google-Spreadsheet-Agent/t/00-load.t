#!perl -T
use strict;
use Test::More tests => 3;

BEGIN {
    use_ok( 'Google::Spreadsheet::Agent::DB' );
    use_ok( 'Google::Spreadsheet::Agent' );
    use_ok( 'Google::Spreadsheet::Agent::Runner' );
}

diag( "Testing Google::Spreadsheet::Agent $Google::Spreadsheet::Agent::VERSION, Perl $], $^X" );
