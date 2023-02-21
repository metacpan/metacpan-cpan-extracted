#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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

   is( \@impl_args, [ 5 ], '->sleep args' );
   ref_is( $f, $impl_f, '->sleep return' );

   $f->cancel;
}

# sysread
{
   $impl_f = Future->new;

   my $f = Future::IO->sysread( "FH", 1024 );

   is( \@impl_args, [ "FH", 1024 ], '->sysread args' );
   ref_is( $f, $impl_f, '->sysread return' );

   $f->cancel;
}

done_testing;
