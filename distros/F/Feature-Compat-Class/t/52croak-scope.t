#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Feature::Compat::Class;

# This test checks that various error conditions result in exceptions being
# thrown. While the core implementation is still being developed we won't
# assert on the exact message text.

{
   ok( !eval <<'EOPERL',
      field $field;
EOPERL
      'field outside class fails' );
}

{
   ok( !eval <<'EOPERL',
      class AClass { }
      field $field;
EOPERL
      'field after closed class block fails' );
}

{
   ok( !eval <<'EOPERL',
      method m() { }
EOPERL
      'method outside class fails' );
}

done_testing;
