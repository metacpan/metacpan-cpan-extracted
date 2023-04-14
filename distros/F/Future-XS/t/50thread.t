#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Future::XS;

eval { require Config && $Config::Config{useithreads} } or
   plan skip_all => "This perl does not support threads";

require threads;

# Just to keep the in-dist unit tests happy; when loaded via Future.pm the
# one provided there takes precedence
sub Future::XS::wrap_cb
{
   my $self = shift;
   my ( $name, $cb ) = @_;
   return $cb;
}

# future outside of thread
{
    my $f1 = Future::XS->new;
    my $f2 = $f1->then( sub { Future::XS->done( "result" ) } );

    threads->create(sub {
        return "dummy";
    })->join;

    $f1->done;
    is( $f2->get, "result", 'Result of Future::XS entirely ouside of sidecar thread' );
}

# future inside thread
{
   my $ret = threads->create(sub {
      my $f1 = Future::XS->new;
      my $f2 = $f1->then( sub { Future::XS->done( "result" ) } );
      $f1->done;
      return $f2->get;
   })->join;
   is( $ret, "result", 'Result of Future::XS entirely within thread' );
}

done_testing;
