#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future::AsyncAwait;

use constant HAVE_XPK_0_09 => ( $XS::Parse::Keyword::VERSION >= 0.09 );

# All of these should fail to compile but not SEGV. If we get to the end of
# the script without segfaulting, we've passed.

# RT129987
ok( !defined eval q'
   async sub foo {
   ',
   'RT129987 test case 1 does not segfault' );

SKIP: {
   eval { require Syntax::Keyword::Try } or skip "No Syntax::Keyword::Try", 1;

   ok( !defined eval q'
      use Syntax::Keyword::Try;

      my $pending = Future->new;
      my $pending2 = Future->new;
      my $final = (async sub {
         my ($f) = @_;
         try {
            await $f;
            my $nested = async sub {
               await shift;
            })->($pending2);
            return await $nested;
         } catch {
         }
      })->($pending);
      ',
      'RT129987 test case 2 does not segfault' );
}

# RT129987
ok( !defined eval q'
   (async sub { my $x = async sub { await 1; })
   ',
   'RT129987 test case 3 does not segfault' );

# RT130417
{
   local $@;

   ok( !defined eval q'
      package segfault;
      use strict;
      use warnings;

      use Future::AsyncAwait;

      async sub example {
         $x
      }
      ',
      'RT130417 strict-failing code fails to compile' );
   like( "$@", qr/^Global symbol "\$x" requires explicit package name/,
      'Failure message complains about undeclared $x' );
}

# RT131487
{
   local $@;

   my $err = HAVE_XPK_0_09 ?
      qr/^parse failed--compilation aborted / :
      qr/^Global symbol "\$api" requires explicit package name/;

   ok( !defined eval q'
      package segfault;
      use strict;
      use warnings;

      use Future::AsyncAwait;
      (async sub {
         for my $i (1..5) {
            await $api->method;
         }
      })->()->get;
      ',
      'RT131487 strict-failing code fails to compile' );
   like( "$@", $err, 'Failure message complains about undeclared $api' );
}

done_testing;
