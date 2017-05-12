#!/usr/bin/env perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Gerrit::Client' ) || print "Bail out!\n";
}

diag( "Testing Gerrit::Client $Gerrit::Client::VERSION, Perl $], $^X" );
