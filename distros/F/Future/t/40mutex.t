#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;
use Future::Mutex;

# done
{
   my $mutex = Future::Mutex->new;

   my $f;
   my $lf = $mutex->enter( sub { $f = Future->new } );

   ok( defined $lf, '->enter returns Future' );
   ok( defined $f, '->enter on new Mutex runs code' );

   ok( !$lf->is_ready, 'locked future not yet ready' );

   $f->done;
   ok( $lf->is_ready, 'locked future ready after $f->done' );
}

# done chaining
{
   my $mutex = Future::Mutex->new;

   my $f1;
   my $lf1 = $mutex->enter( sub { $f1 = Future->new } );

   my $f2;
   my $lf2 = $mutex->enter( sub { $f2 = Future->new } );

   ok( !defined $f2, 'second enter not invoked while locked' );

   $f1->done;
   ok( defined $f2, 'second enter invoked after $f1->done' );

   $f2->done;
   ok( $lf2->is_ready, 'second locked future ready after $f2->done' );
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
}

# immediately done
{
   my $mutex = Future::Mutex->new;

   is( $mutex->enter( sub { Future->done( "result" ) } )->get,
       "result",
       '$mutex->enter returns immediate result' );
}

# immediately fail
{
   my $mutex = Future::Mutex->new;

   is( $mutex->enter( sub { Future->fail( "oops" ) } )->failure,
       "oops",
       '$mutex->enter returns immediate failure' );
}

# code dies
{
   my $mutex = Future::Mutex->new;

   is( $mutex->enter( sub { die "oopsie\n" } )->failure,
       "oopsie\n",
       '$mutex->enter returns immediate failure on exception' );

   is( $mutex->enter( sub { Future->done( "unlocked" ) } )->get,
       "unlocked",
       '$mutex remains unlocked after exception' );
}

done_testing;
