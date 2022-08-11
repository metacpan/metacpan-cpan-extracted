#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;

use lib qw( t/lib );

use FutureTests;

use Future::XS;

test_future_done( "Future::XS" );

test_future_fail( "Future::XS" );

done_testing;
