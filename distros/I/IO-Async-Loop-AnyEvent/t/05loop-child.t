#!/usr/bin/perl

BEGIN { $^W = 0 } # disable the warnings that Build has enabled

use IO::Async::LoopTests 0.24;

# About the only AnyEvent::Impl module we know actually passes these tests is
# AnyEvent::Impl::IOAsync. Don't worry about the circular dependency; the way
# IO::Async::LoopTests works means it comes out OK. Honest...
BEGIN { $ENV{PERL_ANYEVENT_MODEL} = "IOAsync" };
use IO::Async::Loop::AnyEvent;
undef $IO::Async::Loop::ONE_TRUE_LOOP;

run_tests( 'IO::Async::Loop::AnyEvent', 'child' );
