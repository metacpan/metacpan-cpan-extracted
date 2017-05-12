#!/usr/bin/perl

use IO::Async::LoopTests 0.24;

# We need to force AnyEvent to pick some other implementation than the nested
# AnyEvent::Impl::IOAsync, because there's a bug here that prevents idle from
# working properly. It is known to work on the Glib model, so pick that one.

if( eval { require AnyEvent::Impl::Glib } ) {
   run_tests( 'IO::Async::Loop::AnyEvent', 'idle' );
}
else {
   Test::More::plan skip_all => "No AnyEvent::Impl::Glib";
}
