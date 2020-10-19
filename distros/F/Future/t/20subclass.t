#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Identity;

# subclass->...
{
   my $f = t::Future::Subclass->new;
   my @seq;

   isa_ok( $seq[@seq] = $f->then( sub {} ),
           "t::Future::Subclass",
           '$f->then' );

   isa_ok( $seq[@seq] = $f->else( sub {} ),
           "t::Future::Subclass",
           '$f->and_then' );

   isa_ok( $seq[@seq] = $f->then_with_f( sub {} ),
           "t::Future::Subclass",
           '$f->then_with_f' );

   isa_ok( $seq[@seq] = $f->else_with_f( sub {} ),
           "t::Future::Subclass",
           '$f->else_with_f' );

   isa_ok( $seq[@seq] = $f->followed_by( sub {} ),
           "t::Future::Subclass",
           '$f->followed_by' );

   isa_ok( $seq[@seq] = $f->transform(),
           "t::Future::Subclass",
           '$f->transform' );

   $_->cancel for @seq;
}

# immediate subclass->...
{
   my $fdone = t::Future::Subclass->new->done;
   my $ffail = t::Future::Subclass->new->fail( "Oop\n" );

   isa_ok( $fdone->then( sub { 1 } ),
           "t::Future::Subclass",
           'immediate $f->then' );

   isa_ok( $ffail->else( sub { 1 } ),
           "t::Future::Subclass",
           'immediate $f->else' );

   isa_ok( $fdone->then_with_f( sub {} ),
           "t::Future::Subclass",
           'immediate $f->then_with_f' );

   isa_ok( $ffail->else_with_f( sub {} ),
           "t::Future::Subclass",
           'immediate $f->else_with_f' );

   isa_ok( $fdone->followed_by( sub {} ),
           "t::Future::Subclass",
           '$f->followed_by' );
}

# immediate->followed_by( sub { subclass } )
{
   my $f = t::Future::Subclass->new;
   my $seq;

   isa_ok( $seq = Future->done->followed_by( sub { $f } ),
           "t::Future::Subclass",
           'imm->followed_by $f' );

   $seq->cancel;
}

# convergents
{
   my $f = t::Future::Subclass->new;
   my @seq;

   isa_ok( $seq[@seq] = Future->wait_all( $f ),
           "t::Future::Subclass",
           'Future->wait_all( $f )' );

   isa_ok( $seq[@seq] = Future->wait_any( $f ),
           "t::Future::Subclass",
           'Future->wait_any( $f )' );

   isa_ok( $seq[@seq] = Future->needs_all( $f ),
           "t::Future::Subclass",
           'Future->needs_all( $f )' );

   isa_ok( $seq[@seq] = Future->needs_any( $f ),
           "t::Future::Subclass",
           'Future->needs_any( $f )' );

   my $imm = Future->done;

   isa_ok( $seq[@seq] = Future->wait_all( $imm, $f ),
           "t::Future::Subclass",
           'Future->wait_all( $imm, $f )' );

   # Pick the more derived subclass even if all are pending

   isa_ok( $seq[@seq] = Future->wait_all( Future->new, $f ),
           "t::Future::Subclass",
           'Future->wait_all( Future->new, $f' );

   $_->cancel for @seq;
}

# empty convergents (RT97537)
{
   my $f;

   isa_ok( $f = t::Future::Subclass->wait_all(),
           "t::Future::Subclass",
           'subclass ->wait_all' );

   isa_ok( $f = t::Future::Subclass->wait_any(),
           "t::Future::Subclass",
           'subclass ->wait_any' );
   $f->failure;

   isa_ok( $f = t::Future::Subclass->needs_all(),
           "t::Future::Subclass",
           'subclass ->needs_all' );

   isa_ok( $f = t::Future::Subclass->needs_any(),
           "t::Future::Subclass",
           'subclass ->needs_any' );
   $f->failure;
}

# ->get calls the correct await
{
   my $f = t::Future::Subclass->new;

   my $called;
   no warnings 'once';
   local *t::Future::Subclass::await = sub {
      $called++;
      identical( $_[0], $f, '->await is called on $f' );
      $_[0]->done( "Result here" );
   };

   is_deeply( [ $f->get ],
              [ "Result here" ],
              'Result from ->get' );

   ok( $called, '$f->await called' );
}

done_testing;

package t::Future::Subclass;
use base qw( Future );
