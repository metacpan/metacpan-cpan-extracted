#!perl -T

use Test::More tests => 1;

BEGIN {
    package Something;
    main::use_ok( 'Method::Assert' );
    package main;
}

diag( "Testing Method::Assert $Method::Assert::VERSION, Perl $], $^X" );
