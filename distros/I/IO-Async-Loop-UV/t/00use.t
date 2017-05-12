#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use UV; # avoid CHECK warning

use_ok( "IO::Async::Loop::UV" );
