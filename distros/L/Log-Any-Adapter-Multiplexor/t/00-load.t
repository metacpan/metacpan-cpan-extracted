#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

BEGIN {
        use_ok( 'Log::Any::Adapter::Multiplexor' ) || print "Bail out!\n";
    }
     
diag( "Testing Log::Any::Adapter::Multiplexor $Log::Any::Adapter::Multiplexor::VERSION, Perl $], $^X" );
