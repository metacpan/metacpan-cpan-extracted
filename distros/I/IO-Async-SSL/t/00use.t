#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use_ok( 'IO::Async::SSL' );
use_ok( 'IO::Async::SSLStream' );

done_testing;
