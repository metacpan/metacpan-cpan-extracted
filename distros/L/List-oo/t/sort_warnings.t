#!/usr/bin/perl

use Test::NoWarnings;
use Test::More qw(no_plan);
BEGIN { use_ok('List::oo', qw(L $a $b)); }
use strict;
use warnings;

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);

{
  my $l = L(reverse(@a0))->sort(sub {$a cmp $b});
  isa_ok($l, 'List::oo');
  is_deeply($l, [@a0], 'emulate default');
}

# vim:ts=2:sw=2:et:sta:syntax=perl
