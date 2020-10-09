#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait qw( :experimental(cancel) );

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

# CANCEL before await
{
   my $cancelled;

   my $f1 = Future->new;
   my $fret = (async sub {
      CANCEL { $cancelled++; }
      await $f1;
   })->();

   $fret->get if $fret->is_failed; # report errors

   $fret->cancel;
   $f1->done;

   ok( $cancelled, 'cancelled async sub invokes CANCEL blocks' );
}

# CANCEL after await
{
   my $cancelled;

   my $f1 = Future->new;
   my $f2 = Future->new;
   my $fret = (async sub {
      await $f1;
      CANCEL { $cancelled++; }
      await $f2;
   })->();

   $f1->done;
   $fret->get if $fret->is_failed; # report errors
   $fret->cancel;

   $f2->done;

   ok( $cancelled, 'cancelled async sub invokes CANCEL blocks after first await' );
}

# Not cancelled for done
{
   my $cancelled;

   my $f1 = Future->new;
   my $fret = (async sub {
      CANCEL { $cancelled++; }
      await $f1;
      return "OK";
   })->();

   $fret->get if $fret->is_failed; # report errors

   $f1->done;
   $fret->get;

   ok( !$cancelled, 'no CANCEL block for done sub' );
}

# Not cancelled for failure
{
   my $cancelled;

   my $f1 = Future->new;
   my $fret = (async sub {
      CANCEL { $cancelled++; }
      await $f1;
      die "Oops!\n";
   })->();

   $fret->get if $fret->is_failed; # report errors

   $f1->done;

   ok( $fret->is_failed, '$fret failed' );
   ok( !$cancelled, 'no CANCEL block for failed sub' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;
