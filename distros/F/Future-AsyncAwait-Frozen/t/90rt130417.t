#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

ok( !defined eval q'
   package segfault;
   use strict;
   use warnings;

   use Future::AsyncAwait::Frozen;

   async sub example {
      $x
   }
   ',
   'strict-failing code fails to compile' );

like( "$@", qr/^Global symbol "\$x" requires explicit package name/,
   'Failure message complains about undeclared $x' );

done_testing;
