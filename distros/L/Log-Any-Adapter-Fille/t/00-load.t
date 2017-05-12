#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Any::Adapter::Fille' ) || print "Bail out!\n";
}

diag( "Testing Log::Any::Adapter::Fille $Log::Any::Adapter::Fille::VERSION, Perl $], $^X" );
