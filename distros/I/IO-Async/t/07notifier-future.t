#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Refcount;

use IO::Async::Notifier;
use Future;

my ( $err, $name, @detail );
my $notifier = IO::Async::Notifier->new(
   on_error => sub {
      ( undef, $err, $name, @detail ) = @_;
   },
);

# done
{
   my $f = Future->new;

   $notifier->adopt_future( $f );

   is_refcount( $f, 2, '$f has refcount 2 after ->adopt_future' );
   is_oneref( $notifier, '$notifier still has refcount 1 after ->adopt_future' );

   $f->done( "result" );

   is_refcount( $f, 1, '$f has refcount 1 after $f->done' );
}

# fail
{
   my $f = Future->new;

   $notifier->adopt_future( $f );

   $f->fail( "It failed", name => 1, 2, 3 );

   is( $err, "It failed", '$err after $f->fail' );
   is( $name, "name",     '$name after $f->fail' );
   is_deeply( \@detail, [ 1, 2, 3 ], '@detail after $f->fail' );

   is_refcount( $f, 1, '$f has refcount 1 after $f->fail' );

   undef $err;

   $f = Future->new;
   $notifier->adopt_future( $f->else_done() );

   $f->fail( "Not captured" );

   ok( !defined $err, '$err not defined after ->else_done suppressed failure' );
}

done_testing;
