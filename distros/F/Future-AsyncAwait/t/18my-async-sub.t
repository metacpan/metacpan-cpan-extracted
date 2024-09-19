#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   $^V ge v5.18 or
      plan skip_all => "Lexical subroutines are not supported on Perl version $^V";
}

use Future;

use Future::AsyncAwait;

# my async sub
{
   my async sub return_10 { return 10; }

   my $f = return_10();

   is( scalar $f->get, 10, '$f->get on result of my async sub' );

   ok( !main->can( "return_10" ),
      'my async sub does not appear as a package function' );
}

done_testing;
