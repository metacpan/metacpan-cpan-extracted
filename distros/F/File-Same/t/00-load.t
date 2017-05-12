#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('File::Same') || print "Bail out!\n"; }
diag( "Testing File::Same $File::Same::VERSION, Perl $], $^X" );
