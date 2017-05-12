#!/usr/bin/perl

use Test::NoWarnings;
use Test::More qw(no_plan);
BEGIN { use_ok('List::oo', qw(L)); }
use strict;
use warnings;

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);

{
  my $l = L(@a0)->wrap('a','b');
  isa_ok($l, 'List::oo');
  is_deeply($l, ['a',@a0,'b'], 'wrap');
}
########################################################################
{
  my $l = L(@a0);
  isa_ok($l, 'List::oo');
  my $v = $l->shift;
  is($v, 'abel', 'shift');
  is_deeply($l, [@a0[1..$#a0]], 'shift');
}
{
  my $l = L(@a0);
  isa_ok($l, 'List::oo');
  my $v = $l->ishift;
  isa_ok($v, 'List::oo');
  is_deeply($l, [@a0[1..$#a0]], 'ishift');
  is($l, $v, 'same');
}
########################################################################
{ # pop
  my $l = L(@a0);
  isa_ok($l, 'List::oo');
  my $v = $l->pop;
  is($v, 'golfer', 'pop');
  is_deeply($l, [@a0[0..($#a0-1)]], 'pop');
}
{ # ipop
  my $l = L(@a0);
  isa_ok($l, 'List::oo');
  my $v = $l->ipop;
  isa_ok($v, 'List::oo');
  is_deeply($l, [@a0[0..($#a0-1)]], 'ipop');
  is($l, $v, 'same');
}
########################################################################
{ # unshift
  my $l = L(@a0);
  isa_ok($l, 'List::oo');
  my $v = $l->unshift('foo');
  is($v, scalar(@a0)+1, 'unshift');
  is_deeply($l, ['foo', @a0], 'unshift');
}


# vim:ts=2:sw=2:et:sta:syntax=perl
