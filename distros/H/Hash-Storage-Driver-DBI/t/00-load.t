#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hash::Storage::Driver::DBI' ) || print "Bail out!\n";
}

diag( "Testing Hash::Storage::Driver::DBI $Hash::Storage::Driver::DBI::VERSION, Perl $], $^X" );
