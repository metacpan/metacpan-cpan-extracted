#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl;

use Future::IO;
use Future::IO::Impl::Tickit;

use Tickit;
use Tickit::Test::MockTerm;

Future::IO::Impl::Tickit->set_tickit( Tickit->new(
   # Use the mock terminal, so libtickit doesn't splat terminal sequences onto
   # the real STDOUT and upset the TAP parser
   term => Tickit::Test::MockTerm->new,
) );

run_tests 'connect';

done_testing;
