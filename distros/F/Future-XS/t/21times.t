#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;

use lib qw( t/lib );

use FutureTests;

BEGIN {
   $ENV{PERL_FUTURE_TIMES} = 1;
}

use Future::XS;

test_future_times( "Future::XS" );

done_testing;
