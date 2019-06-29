#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount 0.09 import => [qw( is_refcount refcount )];

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

my $errgv_ref = \*@;

# $@ can be localized
#   For some odd reason, SvREFCNT(PL_errgv) increases by 1 the first time
#   this code is run, but is stable thereafter. So only test it the second
#   time. Perhaps something somewhere needs to get lazily created?
foreach my $idx ( 1, 2 )
{
   my $errsv_refcount = refcount(\$@);
   my $errgv_refcount = refcount($errgv_ref);

   my $f1 = Future->new;
   my $fret = (async sub {
      local $@ = "inside";
      await $f1;
      return $@;
   })->();

   $@ = "OUTSIDE";
   $f1->done;
   is( scalar $fret->get, "inside", 'result from async sub with local $@' );

   is_refcount( \$@, $errsv_refcount, '$@ refcount preserved' );
   is_refcount( $errgv_ref, $errgv_refcount, '*@ refcount preserved' ) if $idx > 1;
}

# localised $@ plays nicely with eval{}
{
   my $errsv_refcount = refcount(\$@);
   my $errgv_refcount = refcount($errgv_ref);

   my $f1 = Future->new;
   my $fret = (async sub {
      local $@ = "inside";
      await $f1;
      eval {
         die "oopsie\n";
      };
      return $@;
   })->();

   $@ = "OUTSIDE";
   $f1->done;
   is( scalar $fret->get, "oopsie\n", 'result from eval { die }' );

   is_refcount( \$@, $errsv_refcount, '$@ refcount preserved' );
   is_refcount( $errgv_ref, $errgv_refcount, '*@ refcount preserved' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;
