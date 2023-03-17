#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "signatures are not availble"
      unless $] >= 5.026;
}

use feature 'signatures';
no warnings 'experimental::signatures';

BEGIN {
   plan skip_all => "Future is not available"
      unless eval { require Future };
   plan skip_all => "Future::AsyncAwait >= 0.55 is not available"
      unless eval { require Future::AsyncAwait;
                    Future::AsyncAwait->VERSION( '0.55' ) };
   plan skip_all => "Syntax::Keyword::MultiSub >= 0.01 is not available"
      unless eval { require Syntax::Keyword::MultiSub;
                    Syntax::Keyword::MultiSub->VERSION( '0.01' ) };

   Future::AsyncAwait->import;
   Syntax::Keyword::MultiSub->import;

   diag( "Future::AsyncAwait $Future::AsyncAwait::VERSION, " .
         "Syntax::Keyword::MultiSub $Syntax::Keyword::MultiSub::VERSION" );
}

async multi sub f ()     { return "null"; }
async multi sub f ( $x ) { return "un($x)"; }

is( await f(),    "null",  'f() on zero args' );
is( await f( 1 ), "un(1)", 'f() on one arg' );

# Ordering shouldn't matter

multi async sub g ()     { return "also-null"; }
multi async sub g ( $x ) { return "also-un($x)"; }

is( await g(), "also-null", 'g() on zero args' );

done_testing;
