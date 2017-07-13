#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future::AsyncAwait;

# await in non-async sub is forbidden
{
   my $ok = !eval 'sub { await $_[0] }';
   my $e = $@;

   ok( $ok, 'await in non-async sub fails to compile' );
   $ok and like( $e, qr/Cannot 'await' outside of an 'async sub' at /, '' );
}

{
   my $ok = !eval 'async sub { my $c = sub { await $_[0] } }';

   ok( $ok, 'await in non-async sub inside async sub fails to compile' );
}

done_testing;
