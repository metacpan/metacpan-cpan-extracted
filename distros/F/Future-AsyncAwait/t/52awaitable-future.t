#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Test::Future::AsyncAwait::Awaitable qw( test_awaitable );

use Future;
use Future::AsyncAwait; # for the back-compat shim

test_awaitable "Future",
   class  => "Future",
   cancel => sub { shift->cancel };

done_testing;
