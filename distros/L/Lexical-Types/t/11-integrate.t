#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 4;

{
 package MyTypes;

 BEGIN { require Lexical::Types; }

 sub import {
  eval 'package Str; package Int';
  Lexical::Types->import(
   as => sub { __PACKAGE__, 'new_' . lc($_[0]) }
  );
 }

 sub unimport {
  Lexical::Types->unimport;
 }

 sub new_str {
  $_[1] = 'str:' . (caller(0))[2];
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::is($_[2], 'Str', 'original type is correct');
  ();
 }

 sub new_int {
  $_[1] = (caller(0))[2];
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::is($_[2], 'Int', 'original type is correct');
  ();
 }
}

{
 BEGIN { MyTypes->import }
 my Str $x;
 is $x, 'str:' . (__LINE__-1), 'MyTypes->new_str 1';
 {
  BEGIN { MyTypes->unimport }
  my Str $y;
  is $y, undef, 'pragma not in use';
  {
   BEGIN { MyTypes->import }
   my Int $z;
   is $z, __LINE__-1, 'MyTypes->new_int 1';
  }
 }
 my Str $y;
 is $y, 'str:' . (__LINE__-1), 'MyTypes->new_str 2';
 my Int $z;
 is $z, __LINE__-1, 'MyTypes->new_int 2';
}
