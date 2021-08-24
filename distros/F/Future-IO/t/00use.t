#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Future::IO" );
use_ok( "Future::IO::ImplBase" );

use_ok( "Test::Future::IO::Impl" );

done_testing;
