#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Refcount;

use Future;
use Future::Utils qw( call_with_escape );

# call_with_escape normal return
{
   my $ret_f;
   my $f = call_with_escape {
      return $ret_f = Future->new;
   };

   $ret_f->done( "result" );

   ok( $f->is_ready, 'call_with_escape ready after returned future ready' );
   is( scalar $f->result, "result", 'result of call_with_escape' );

   $f = call_with_escape {
      return $ret_f = Future->new;
   };

   $ret_f->fail( "failure" );

   ok( $f->is_ready, 'call_with_escape ready after returned future ready' );
   is( scalar $f->failure, "failure", 'result of call_with_escape' );

   undef $ret_f;
   is_oneref( $f, 'call_with_escape has refcount 1 before EOF' );
}

# call_with_escape synchronous escape
{
   my $f = call_with_escape {
      my $escape = shift;
      $escape->done( "escaped" );
   };

   ok( $f->is_ready, 'call_with_escape ready after synchronous escape' );
   is( scalar $f->result, "escaped", 'result of call_with_escape' );
}

# call_with_escape delayed escape
{
   my $ret_f = Future->new;
   my $inner_f;

   my $f = call_with_escape {
      my $escape = shift;
      return $inner_f = $ret_f->then( sub {
         return $escape->done( "later escape" );
      });
   };

   ok( !$f->is_ready, 'call_with_escape not yet ready before deferral' );

   $ret_f->done;

   ok( $f->is_ready, 'call_with_escape ready after deferral' );
   is( scalar $f->result, "later escape", 'result of call_with_escape' );

   ok( $inner_f->is_cancelled, 'code-returned future cancelled after escape' );
}

done_testing;
