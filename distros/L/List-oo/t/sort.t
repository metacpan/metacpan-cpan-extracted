#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('List::oo', qw(L)); }
use strict;
use warnings;

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);

{
  my $l = L(@a0)->sort;
  isa_ok($l, 'List::oo');
  is_deeply($l, [@a0], 'default');
}
{
  my $l = L(reverse(@a0))->sort;
  isa_ok($l, 'List::oo');
  is_deeply($l, [@a0], 'unreverse');
}
{
  my $l = L(reverse(@a0))->sort(sub {$a cmp $b});
  isa_ok($l, 'List::oo');
  is_deeply($l, [@a0], 'emulate default');
}
{
  my $l = L(@a0)->sort(sub {$a cmp $b});
  isa_ok($l, 'List::oo');
  is_deeply($l, [@a0], 'emulate default');
}

# vim:ts=2:sw=2:et:sta:syntax=perl
