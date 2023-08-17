#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More;

BEGIN {
   plan skip_all => 'set TEST_CONDVAR to enable this test (developer only)!'
      if ( $^O eq 'MSWin32' && $] lt '5.020000' && !$ENV{'TEST_CONDVAR'} );

   use_ok 'MCE::Hobo';
   use_ok 'MCE::Shared';
   use_ok 'MCE::Shared::Condvar';
}

my $cv = MCE::Shared->condvar();

## One must explicitly start the shared-server for condvars and queues.
## Not necessary otherwise when IO::FDPass is available.

MCE::Shared->start() unless $INC{'IO/FDPass.pm'};

## signal - --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

{
   ok( 1, "shared condvar, spawning an asynchronous process" );

   my $proc = MCE::Hobo->new( sub {
      sleep(1) for 1..2;
      $cv->lock;
      $cv->signal;
      1;
   });

   $cv->lock;
   $cv->wait;

   ok( 1, "shared condvar, we've come back from the process" );
   is( $proc->join, 1, 'shared condvar, check if process came back correctly' );
}

## lock, set, get, unlock - --- --- --- --- --- --- --- --- --- --- --- --- ---

{
   my $data = 'beautiful skies, ...';

   $cv->lock;

   my $proc = MCE::Hobo->new( sub {
      $cv->lock;
      $cv->get eq $data;
   });

   $cv->set($data);
   $cv->unlock;

   ok( $proc->join, 'shared condvar, check if process sees the same value' );
}

## timedwait, wait, broadcast - --- --- --- --- --- --- --- --- --- --- --- ---

## the tests relocated to xt/condvar_timedwait in 1.884

## the rest --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

$cv->set(20);

is( $cv->len(), 2, 'shared condvar, check length' );
is( $cv->incr(), 21, 'shared condvar, check incr' );
is( $cv->decr(), 20, 'shared condvar, check decr' );
is( $cv->incrby(4), 24, 'shared condvar, check incrby' );
is( $cv->decrby(4), 20, 'shared condvar, check decrby' );
is( $cv->getincr(), 20, 'shared condvar, check getincr' );
is( $cv->get(), 21, 'shared condvar, check value after getincr' );
is( $cv->getdecr(), 21, 'shared condvar, check getdecr' );
is( $cv->get(), 20, 'shared condvar, check value after getdecr' );
is( $cv->append('ba'), 4, 'shared condvar, check append' );
is( $cv->get(), '20ba', 'shared condvar, check value after append' );
is( $cv->getset('foo'), '20ba', 'shared condvar, check getset' );
is( $cv->get(), 'foo', 'shared condvar, check value after getset' );

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

## https://sacred-texts.com/cla/usappho/sph02.htm (VII)

my $sappho_text =
  "ἔλθε μοι καὶ νῦν, χαλεπᾶν δὲ λῦσον
   ἐκ μερίμναν ὄσσα δέ μοι τέλεσσαι
   θῦμοσ ἰμμέρρει τέλεσον, σὐ δ᾽ αὔτα
   σύμμαχοσ ἔσσο.";

my $translation =
  "Come then, I pray, grant me surcease from sorrow,
   Drive away care, I beseech thee, O goddess
   Fulfil for me what I yearn to accomplish,
   Be thou my ally.";

$cv->set( $sappho_text );
is( $cv->get(), $sappho_text, 'shared scalar, check unicode set' );
is( $cv->len(), length($sappho_text), 'shared scalar, check unicode len' );

my $length = $cv->append("Ǣ");
is( $cv->get(), $sappho_text . "Ǣ", 'shared scalar, check unicode append' );
is( $length, length($sappho_text) + 1, 'shared scalar, check unicode length' );

done_testing;

