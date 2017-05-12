#! /usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Kaiten::Container' ) || print "Bail out!\n";
}

diag( "Testing Kaiten::Container $Kaiten::Container::VERSION, Perl $], $^X" );
