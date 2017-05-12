#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Markup::Unified' ) || print "Bail out!
";
}

diag( "Testing Markup::Unified $Markup::Unified::VERSION, Perl $], $^X" );
