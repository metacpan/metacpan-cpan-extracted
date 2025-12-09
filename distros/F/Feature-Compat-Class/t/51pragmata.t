#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

{
   no strict;

   ok( defined eval <<'EOPERL',
      class TestStrict {
         sub x { $def = $def; }
      }

      "ok"
EOPERL
      'class scope does not imply use strict' ) or
      diag( "Failure was: $@" );
}

done_testing;
