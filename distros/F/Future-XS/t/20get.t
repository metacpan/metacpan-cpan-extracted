#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;

use lib qw( t/lib );

use FutureTests;
use Test::Identity;

use Future::XS;

test_future_get( "Future::XS" );

done_testing;
