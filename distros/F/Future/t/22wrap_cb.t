#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;

use Future;

our $VAR = "";
# around Future::wrap_cb => sub { ... }
{
   my $orig = Future->can( 'wrap_cb' );
   no warnings 'redefine';
   *Future::wrap_cb = sub {
      my $cb = $orig->(@_);
      my $saved_VAR = $VAR;

      return sub {
         local $VAR = $saved_VAR;
         $cb->(@_);
      };
   };
}

# on_ready
{
   my $result;
   my $f = Future->new;

   {
      local $VAR = "inner";
      $f->on_ready( sub { $result = $VAR } );
   }

   $f->done;

   is( $result, "inner", 'on_ready wraps CB' );
}

# on_done
{
   my $result;
   my $f = Future->new;

   {
      local $VAR = "inner";
      $f->on_done( sub { $result = $VAR } );
   }

   $f->done;

   is( $result, "inner", 'on_done wraps CB' );
}

# on_fail
{
   my $result;
   my $f = Future->new;

   {
      local $VAR = "inner";
      $f->on_fail( sub { $result = $VAR } );
   }

   $f->fail( "Failed" );

   is( $result, "inner", 'on_fail wraps CB' );
}

# then
{
   my $result;
   my $f = Future->new;

   my $f2;
   {
      local $VAR = "inner";
      $f2 = $f->then( sub { $result = $VAR; Future->done } );
   }

   $f->done;

   is( $result, "inner", 'then wraps CB' );
}

# else
{
   my $result;
   my $f = Future->new;

   my $f2;
   {
      local $VAR = "inner";
      $f2 = $f->else( sub { $result = $VAR; Future->done } );
   }

   $f->fail( "Failed" );

   is( $result, "inner", 'else wraps CB' );
}

# Other sequence methods all use the same ->_sequence so all should be fine

done_testing;
