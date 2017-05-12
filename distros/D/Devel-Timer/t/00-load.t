#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Devel::Timer') || print "Bail out!\n"; }
diag( "Testing Devel::Timer $Devel::Timer::VERSION, Perl $], $^X" );
