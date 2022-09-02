#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Devel::MAT::Dumper;
use Devel::MAT;

use Future;

my $DUMPFILE = "test.pmat";

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE };

my $pmat = Devel::MAT->load( $DUMPFILE );
my $df = $pmat->dumpfile;

$pmat->available_tools;
my $tool = $pmat->load_tool( "Future" );

BEGIN { our $FUTURE = Future->new }
{
   ok( $tool->class_is_future( $pmat->find_symbol( '%Future::' ) ),
      'Future stash is a Future class' );
   ok( !$tool->class_is_future( $pmat->find_symbol( '%IO::Handle::' ) ),
      'IO::Handle stash is not a Future class' );

   ok( $tool->class_is_future( $pmat->find_symbol( '%MyFuture::' ) ),
      'MyFuture subclass is a Future class' );

   ok( $tool->class_is_future( "Future" ), '"Future" is a Future class' );

   ok( $pmat->find_symbol( '$FUTURE' )->rv->is_future,
      '$FUTURE isa Future ref' );
   ok( !$df->main_cv->is_future,
      'maincv is not a Future' );
}

BEGIN {
   our %FUTURES = (
      pending   => Future->new,
      done      => Future->new->done( 1, 2, 3 ),
      failed    => Future->new->fail( "oops" ),
      cancelled => Future->new,
   );

   $FUTURES{cancelled}->cancel;
}
{
   my $futureshv = $pmat->find_symbol( '%FUTURES' );

   foreach (qw( pending done failed cancelled )) {
      my $sv = $futureshv->value( $_ )->rv;

      is( $sv->future_state, $_, "$_ Future is $_" );
   }
}

done_testing;

package MyFuture;
use base qw( Future );

1;
