#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future::AsyncAwait::Frozen;

# All of these should fail to compile but not SEGV. If we get to the end of
# the script without segfaulting, we've passed.

ok( !defined eval q'
   async sub foo {
   ',
   'Test case 1 does not segfault' );

ok( !defined eval q'
   (async sub { my $x = async sub { await 1; })
   ',
   'Test case 3 does not segfault' );

done_testing;
