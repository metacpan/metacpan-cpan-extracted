#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use UV; # avoid CHECK warning

use_ok( "IO::Async::Loop::UV" );

done_testing;
