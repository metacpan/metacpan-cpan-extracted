#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Future::IO;

my @impl_args;
my $impl_f;
{
   package TestImplementation;
   sub sleep {
      shift;
      @impl_args = @_;
      return $impl_f;
   }
   sub sysread {
      shift;
      @impl_args = @_;
      return $impl_f;
   }
}

Future::IO->override_impl( "TestImplementation" );

# sleep
{
   $impl_f = Future->new;

   my $f = Future::IO->sleep( 5 );

   is_deeply( \@impl_args, [ 5 ], '->sleep args' );
   identical( $f, $impl_f, '->sleep return' );

   $f->cancel;
}

# sysread
{
   $impl_f = Future->new;

   my $f = Future::IO->sysread( "FH", 1024 );

   is_deeply( \@impl_args, [ "FH", 1024 ], '->sysread args' );
   identical( $f, $impl_f, '->sysread return' );

   $f->cancel;
}

done_testing;
