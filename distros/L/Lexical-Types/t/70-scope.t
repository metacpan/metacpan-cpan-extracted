#!perl -T

use strict;
use warnings;

use Test::More tests => (1 + 2) + (1 + 4) + (3 + 3);

sub Int::TYPEDSCALAR { join ':', (caller 0)[1, 2] }

our ($x, $y, $z, $t);

use lib 't/lib';

{
 eval 'use Lexical::Types; use Lexical::Types::TestRequired1';
 is $@, '', 'first require test didn\'t croak prematurely';
}

{
 eval 'use Lexical::Types; use Lexical::Types::TestRequired2';
 is $@, '', 'second require test didn\'t croak prematurely';
}

{
 my (@decls, @w);
 sub cb3 { push @decls, $_[0]; @_ }
 {
  no strict 'refs';
  *{"Int3$_\::TYPEDSCALAR"} = \&Int::TYPEDSCALAR for qw<X Y Z>;
 }
 local $SIG{__WARN__} = sub { push @w, join '', 'warn:', @_ };
 eval <<' TESTREQUIRED3';
  {
   package Lexical::Types::TestRequired3Z;
   use Lexical::Types as => \&main::cb3;
   use Lexical::Types::TestRequired3X;
   use Lexical::Types::TestRequired3Y;
   my Int3Z $z;
   ::is($z, __FILE__.':6', 'pragma in use at the end');
  }
 TESTREQUIRED3
 is         $@,     '',  'third require test didn\'t croak prematurely';
 is_deeply \@w,     [ ], 'third require test didn\'t warn';
 is_deeply \@decls, [ map "Int3$_", qw<X Z> ],
                         'third require test propagated in the right scopes';
}
