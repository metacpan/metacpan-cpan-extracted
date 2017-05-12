#!perl -T

use strict;
use warnings;

use Test::More tests => 14 + 6;

{
 package Lexical::Types::Test::LTT;

 sub TYPEDSCALAR {
  $_[1] = (caller(0))[2];
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::is($_[2], 'LTT', 'original type is ok');
  ();
 }

 no warnings 'once';
 *TS = \&TYPEDSCALAR;
}

{
 package Lexical::Types::Test::LTT2;

 sub TYPEDSCALAR { 1 .. 2 }
}

{
 package Lexical::Types::Test::LTT3;

 sub TYPEDSCALAR { die 'coconut' }
}

{
 package LTT;

 no warnings 'once';
 *ts = \&Lexical::Types::Test::LTT::TYPEDSCALAR
}

{
 use Lexical::Types as => 'Lexical::Types::Test';
 my LTT $x;
 is $x, __LINE__-1, 'as => string, without trailing ::';

 no Lexical::Types;
 my LTT $y;
 is $y, undef, 'after no';
}

{
 use Lexical::Types as => 'Lexical::Types::Test::';
 my LTT $x;
 is $x, __LINE__-1, 'as => string, with trailing ::';
}

{
 use Lexical::Types as => sub { return };
 my LTT $x;
 is $x, undef, 'as => code, returning nothing';
}

{
 use Lexical::Types as => sub { 'Lexical::Types::Test::LTT' };
 my LTT $x;
 is $x, __LINE__-1, 'as => code, returning package name';
}

{
 use Lexical::Types as => sub { 'Lexical::Types::Test::LTT', undef };
 my LTT $x;
 is $x, __LINE__-1, 'as => code, returning package name and undef';
}

{
 use Lexical::Types as => sub { undef, 'ts' };
 my LTT $x;
 is $x, __LINE__-1, 'as => code, returning undef and method name';
}

{
 use Lexical::Types as => sub { 'Lexical::Types::Test::LTT', 'TS' };
 my LTT $x;
 is $x, __LINE__-1, 'as => code, returning package and method name';
}

{
 my $expect = qr/^Invalid ARRAY reference/;
 local $@;
 eval q[
  use Lexical::Types as => [ qw<a b c> ];
  my LTT $x;
 ];
 like $@, $expect, 'as => array';
}

{
 my $expect = qr/^Lexical::Types mangler should return zero, one or two scalars, but got 3/;
 diag 'This will throw two warnings' if "$]" >= 5.008_008 and "$]" < 5.009;
 local $@;
 eval q[
  use Lexical::Types as => sub { qw<a b c> };
  my LTT $x;
 ];
 like $@, $expect, 'as => code, returning three scalars';
}

{
 my $expect = qr/^Typed scalar initializer method should return zero or one scalar, but got 2/;
 local $@;
 eval q[
  use Lexical::Types as => sub { 'Lexical::Types::Test::LTT2' };
  my LTT $x;
 ];
 like $@, $expect, 'as => code, initializing by returning two scalars';
}

{
 my $expect = qr/^banana at \(eval \d+\) line 2/;
 diag 'This will throw two more warnings' if "$]" >= 5.008_008 and "$]" < 5.009;
 local $@;
 eval q[
  use Lexical::Types as => sub { die 'banana' };
  my LTT $x;
 ];
 like $@, $expect, 'as => sub { die }';
}

{
 my $expect = qr/^coconut at \Q$0\E line 31/;
 local $@;
 eval q[
  use Lexical::Types;
  my Lexical::Types::Test::LTT3 $x;
 ];
 like $@, $expect, 'die in TYPEDSCALAR';
}

my LTT $x;
is $x, undef, 'out of scope';
