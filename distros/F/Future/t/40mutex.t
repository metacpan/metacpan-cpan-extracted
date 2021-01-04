#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Refcount;

use Future;
use Future::Mutex;

# done
{
   my $mutex = Future::Mutex->new;

   ok( $mutex->available, 'Mutex is available' );

   my $f;
   my $lf = $mutex->enter( sub { $f = t::Future::Subclass->new } );

   ok( defined $lf, '->enter returns Future' );
   ok( defined $f, '->enter on new Mutex runs code' );

   isa_ok( $lf, "t::Future::Subclass", '$lf' );

   ok( !$mutex->available, 'Mutex is unavailable' );

   ok( !$lf->is_ready, 'locked future not yet ready' );

   $f->done;
   ok( $lf->is_ready, 'locked future ready after $f->done' );
   ok( $mutex->available, 'Mutex is available again' );

   undef $f;
   is_oneref( $lf, '$lf has one ref at EOT' );
}

# done chaining
{
   my $mutex = Future::Mutex->new;

   my $f1;
   my $lf1 = $mutex->enter( sub { $f1 = t::Future::Subclass->new } );

   my $f2;
   my $lf2 = $mutex->enter( sub { $f2 = t::Future::Subclass->new } );

   isa_ok( $lf1, "t::Future::Subclass", '$lf1' );
   isa_ok( $lf2, "t::Future::Subclass", '$lf2' );

   is_oneref( $lf2, '$lf2 has one ref' );

   ok( !defined $f2, 'second enter not invoked while locked' );

   $f1->done;
   ok( defined $f2, 'second enter invoked after $f1->done' );

   $f2->done;
   ok( $lf2->is_ready, 'second locked future ready after $f2->done' );
   ok( $mutex->available, 'Mutex is available again' );

   undef $f1;
   undef $f2;

   is_oneref( $lf1, '$lf1 has one ref at EOT' );
   is_oneref( $lf2, '$lf2 has one ref at EOT' );
}

# fail chaining
{
   my $mutex = Future::Mutex->new;

   my $f1;
   my $lf1 = $mutex->enter( sub { $f1 = Future->new } );

   my $f2;
   my $lf2 = $mutex->enter( sub { $f2 = Future->new } );

   ok( !defined $f2, 'second enter not invoked while locked' );

   $f1->fail( "oops" );
   ok( defined $f2, 'second enter invoked after $f1->fail' );
   ok( $lf1->failure, 'first locked future fails after $f1->fail' );

   $f2->done;
   ok( $lf2->is_ready, 'second locked future ready after $f2->done' );
   ok( $mutex->available, 'Mutex is available again' );
}

# immediately done
{
   my $mutex = Future::Mutex->new;

   is( $mutex->enter( sub { Future->done( "result" ) } )->result,
       "result",
       '$mutex->enter returns immediate result' );

   ok( $mutex->available, 'Mutex is available again' );
}

# immediately fail
{
   my $mutex = Future::Mutex->new;

   is( $mutex->enter( sub { Future->fail( "oops" ) } )->failure,
       "oops",
       '$mutex->enter returns immediate failure' );

   ok( $mutex->available, 'Mutex is available again' );
}

# code dies
{
   my $mutex = Future::Mutex->new;

   is( $mutex->enter( sub { die "oopsie\n" } )->failure,
       "oopsie\n",
       '$mutex->enter returns immediate failure on exception' );

   ok( $mutex->available, 'Mutex is available again' );
}

# cancellation
{
   my $mutex = Future::Mutex->new;

   my $f = $mutex->enter( sub { Future->new } );
   $f->cancel;

   ok( $mutex->available, 'Mutex is available after cancel' );
}

# queueing
{
   my $mutex = Future::Mutex->new;

   my ( $f1, $f2, $f3 );
   my $f = Future->needs_all(
      $mutex->enter( sub { $f1 = t::Future::Subclass->new } ),
      $mutex->enter( sub { $f2 = t::Future::Subclass->new } ),
      $mutex->enter( sub { $f3 = t::Future::Subclass->new } ),
   );

   isa_ok( $f, "t::Future::Subclass", '$f' );

   ok( defined $f1, '$f1 defined' );
   $f1->done;

   ok( defined $f2, '$f2 defined' );
   $f2->done;

   ok( defined $f3, '$f3 defined' );
   $f3->done;

   ok( $f->is_done, 'Chain is done' );
   ok( $mutex->available, 'Mutex is available after chain done' );
}

# queueing with weakly held intermediates
{
   my $mutex = Future::Mutex->new;

   my ( $f1, $f2, $f3, $f4 );
   my $f = Future->needs_all(
      $mutex->enter( sub { ( $f1 = Future->new )->then( sub { $f2 = Future->new } ) } ),
      $mutex->enter( sub { ( $f3 = Future->new )->then( sub { $f4 = Future->new } ) } ),
   );

   $f1->done;
   $f2->done;
   $f3->done;
   $f4->done;

   ok( $f->is_done, 'Chain is done' );
}

# counting
{
   my $mutex = Future::Mutex->new( count => 2 );

   is( $mutex->available, 2, 'Mutex has 2 counts available' );

   my ( $f1, $f2, $f3 );
   my $f = Future->needs_all(
      $mutex->enter( sub { $f1 = Future->new } ),
      $mutex->enter( sub { $f2 = Future->new } ),
      $mutex->enter( sub { $f3 = Future->new } ),
   );

   ok( defined $f1 && defined $f2, '$f1 and $f2 defined with count 2' );

   $f1->done;
   ok( defined $f3, '$f3 defined after $f1 done' );

   $f2->done;
   $f3->done;

   ok( $f->is_done, 'Chain is done' );
   ok( $mutex->available, 'Mutex is available after chain done' );
}

done_testing;

package t::Future::Subclass;
use base qw( Future );
