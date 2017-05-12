#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Log::Any::For::Std' ) || print "Bail out!\n";
}

diag( "Testing Log::Any::For::Std $Log::Any::For::Std::VERSION, Perl $], $^X" );
