#!perl -T

use strict;
use warnings;

use Test::More tests => 2 + 3 * 4 + 5 * 2
                      + 2 + 3 * 2 + 5 * 2
                      + 2 + 3 * 4 + 5 * 2;

our $calls;

sub Int::TYPEDSCALAR { ++$calls; (caller(0))[2] }

{
 use Lexical::Types;

 {
  my $desc = 'single uninit';
  local $calls = 0;
  my Int $x;
  is $calls, 1,          "$desc: correct number of calls";
  is $x,     __LINE__-2, "$desc: initialized correctly";
 }

 {
  my $desc = 'double uninit';
  local $calls = 0;
  my Int ($x, $y);
  is $calls, 2,      "$desc: correct number of calls";
  is $x, __LINE__-2, "$desc: initialized \$x correctly";
  is $y, __LINE__-3, "$desc: initialized \$y correctly";
 }

 {
  my $desc = 'double uninit with undef begin';
  local $calls = 0;
  my Int (undef, $x, $y);
  is $calls, 2,      "$desc: correct number of calls";
  is $x, __LINE__-2, "$desc: initialized \$x correctly";
  is $y, __LINE__-3, "$desc: initialized \$y correctly";
 }

 {
  my $desc = 'double uninit with undef middle';
  local $calls = 0;
  my Int ($x, undef, $y);
  is $calls, 2,      "$desc: correct number of calls";
  is $x, __LINE__-2, "$desc: initialized \$x correctly";
  is $y, __LINE__-3, "$desc: initialized \$y correctly";
 }

 {
  my $desc = 'double uninit with undef end';
  local $calls = 0;
  my Int ($x, undef, $y);
  is $calls, 2,      "$desc: correct number of calls";
  is $x, __LINE__-2, "$desc: initialized \$x correctly";
  is $y, __LINE__-3, "$desc: initialized \$y correctly";
 }

 {
  my $desc = 'quadruple uninit with parens';
  local $calls = 0;
  my Int ($x, ($y, $z), $t);
  is $calls, 4,      "$desc: correct number of calls";
  is $x, __LINE__-2, "$desc: initialized \$x correctly";
  is $y, __LINE__-3, "$desc: initialized \$y correctly";
  is $z, __LINE__-4, "$desc: initialized \$z correctly";
  is $t, __LINE__-5, "$desc: initialized \$t correctly";
 }

 {
  my $desc = 'quadruple uninit with parens and undef';
  local $calls = 0;
  my Int ($x, undef, ($y, undef, $z), undef, $t);
  is $calls, 4,      "$desc: correct number of calls";
  is $x, __LINE__-2, "$desc: initialized \$x correctly";
  is $y, __LINE__-3, "$desc: initialized \$y correctly";
  is $z, __LINE__-4, "$desc: initialized \$z correctly";
  is $t, __LINE__-5, "$desc: initialized \$t correctly";
 }

 {
  my $desc = 'single init';
  local $calls = 0;
  my Int $x = 'x';
  is $calls, 1,   "$desc: correct number of calls";
  is $x,     'x', "$desc: initialized correctly";
 }

 {
  my $desc = 'double init';
  local $calls = 0;
  my Int ($x, $y) = ('x', 'y');
  is $calls, 2,   "$desc: correct number of calls";
  is $x,     'x', "$desc: initialized \$x correctly";
  is $y,     'y', "$desc: initialized \$y correctly";
 }

 {
  my $desc = 'double partial init';
  local $calls = 0;
  my Int ($x, undef, $y) = ('x');
  is $calls, 2,     "$desc: correct number of calls";
  is $x,     'x',   "$desc: initialized \$x correctly";
  is $y,     undef, "$desc: initialized \$y correctly";
 }

 {
  my $desc = 'quadruple init with parens';
  local $calls = 0;
  my Int ($x, ($y, $z), $t) = ('x', 'y');
  is $calls, 4,      "$desc: correct number of calls";
  is $x, 'x',   "$desc: initialized \$x correctly";
  is $y, 'y',   "$desc: initialized \$y correctly";
  is $z, undef, "$desc: initialized \$z correctly";
  is $t, undef, "$desc: initialized \$t correctly";
 }

 {
  my $desc = 'quadruple init with parens and undef';
  local $calls = 0;
  my Int ($x, ($y, undef, $z), $t) = ('x', 'y');
  is $calls, 4,      "$desc: correct number of calls";
  is $x, 'x',   "$desc: initialized \$x correctly";
  is $y, 'y',   "$desc: initialized \$y correctly";
  is $z, undef, "$desc: initialized \$z correctly";
  is $t, undef, "$desc: initialized \$t correctly";
 }

 {
  my $desc = 'for';
  local $calls = 0;
  for my Int $x (0) {
   is $calls, 0, "$desc: correct number of calls";
   is $x,     0, "$desc: initialized correctly";
  }
 }

 {
  my $desc = 'argument list';
  local $calls = 0;
  sub {
   my Int ($x, $y) = @_;
   is $calls, 2,   "$desc: correct number of calls";
   is $x,     'x', "$desc: initialized \$x correctly";
   is $y,     'y', "$desc: initialized \$y correctly";
  }->('x', 'y');
 }

 {
  my $desc = 'argument list with undef begin';
  local $calls = 0;
  sub {
   my Int (undef, $x, $y) = @_;
   is $calls, 2,     "$desc: correct number of calls";
   is $x,     'y',   "$desc: initialized \$x correctly";
   is $y,     undef, "$desc: initialized \$y correctly";
  }->('x', 'y');
 }

 {
  my $desc = 'argument list with undef middle';
  local $calls = 0;
  sub {
   my Int ($x, undef, $y) = @_;
   is $calls, 2,     "$desc: correct number of calls";
   is $x,     'x',   "$desc: initialized \$x correctly";
   is $y,     undef, "$desc: initialized \$y correctly";
  }->('x', 'y');
 }

 {
  my $desc = 'argument list with undef end';
  local $calls = 0;
  sub {
   my Int ($x, $y, undef) = @_;
   is $calls, 2,   "$desc: correct number of calls";
   is $x,     'x', "$desc: initialized \$x correctly";
   is $y,     'y', "$desc: initialized \$y correctly";
  }->('x', 'y');
 }

 {
  my $desc = 'argument list with parens';
  local $calls = 0;
  sub {
   my Int ($x, ($y, $z), $t) = @_;
   is $calls, 4,   "$desc: correct number of calls";
   is $x,     'x', "$desc: initialized \$x correctly";
   is $y,     'y', "$desc: initialized \$y correctly";
   is $z,     'z', "$desc: initialized \$z correctly";
   is $t,     't', "$desc: initialized \$t correctly";
  }->('x', 'y', 'z', 't');
 }

 {
  my $desc = 'argument list with parens';
  local $calls = 0;
  sub {
   my Int ($x, ($y, undef, $z), $t) = @_;
   is $calls, 4,     "$desc: correct number of calls";
   is $x,     'x',   "$desc: initialized \$x correctly";
   is $y,     'y',   "$desc: initialized \$y correctly";
   is $z,     'z',   "$desc: initialized \$z correctly";
   is $t,     undef, "$desc: initialized \$t correctly";
  }->('x', 'y', 'foo', 'z');
 }
}
