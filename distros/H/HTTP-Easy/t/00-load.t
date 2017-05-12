#!/usr/bin/perl

use strict;
use lib::abs '../lib';
use Test::More tests => 1;

BEGIN {
    use_ok( 'HTTP::Easy' ) || print "Bail out!
";
}

diag( "Testing HTTP::Easy $HTTP::Easy::VERSION, Perl $], $^X" );
