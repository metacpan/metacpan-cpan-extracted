#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Lingua::IND::Numbers') || print "Bail out!"; }
diag( "Testing Lingua::IND::Numbers $Lingua::IND::Numbers::VERSION, Perl $], $^X" );
