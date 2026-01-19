#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl 0.15;

use Future::IO 0.17;
use Future::IO::Impl::Tickit;

use Tickit;
use Tickit::Test::MockTerm;

Future::IO::Impl::Tickit->set_tickit( Tickit->new(
   # Use the mock terminal, so libtickit doesn't splat terminal sequences onto
   # the real STDOUT and upset the TAP parser
   term => Tickit::Test::MockTerm->new,
) );

run_tests 'recv';
run_tests 'recvfrom';

done_testing;
