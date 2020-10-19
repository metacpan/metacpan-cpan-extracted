#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;

use Future;
use Future::Queue;

# push before shift
{
   my $queue = Future::Queue->new;

   $queue->push( "ITEM" );

   my $f = $queue->shift;
   ok( $f->is_done, '$queue->shift already ready' );
   is( $f->result, "ITEM", '$queue->shift->result' );
}

# shift before push
{
   my $queue = Future::Queue->new;

   my $f = $queue->shift;
   ok( !$f->is_done, '$queue->shift not yet ready' );

   $queue->push( "ITEM" );

   ok( $f->is_done, '$queue->shift now ready after push' );
   is( $f->result, "ITEM", '$queue->shift->result' );
}

done_testing;
