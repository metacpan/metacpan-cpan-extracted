#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

use Devel::TraceDeps::Scan;
my $s = 'Devel::TraceDeps::Scan';

{
  my $got = $s->scan(file => './samples/nothing.pl');
  is(scalar($got->items), 0);
}
{
  my $got = $s->scan(file => './samples/fail_eval.pl');
  #die join("\n", $got->callers, '--', keys(%{$got->{store}}));
  my @list = $got->items_for('main');
  is(scalar(@list), 3);
  is($list[0]->req, 'File::Spec');
  is($list[1]->req, 'bLRo::sauz::cghloeu8912');
  ok($list[1]->fail, 'eval scanned');
  like($list[1]->err, qr/^Can't locate bLRo/);
  is($list[2]->req, 'bLRo::sauz::cghloeu8913');
  ok($list[2]->fail, 'eval scanned');
}
{
  # hmm, if your code dies, I guess that's just too bad
  # but I can't be expecting to find empty modules, etc so... 
  my $got = $s->scan(code =>
    '$SIG{__DIE__} = sub {exit}; require bLRo::thbbt');
  my @list = $got->items;
  is(scalar(@list), 1);
  ok($list[0]->fail, 'scanned');
  is($list[0]->err, undef);
}
{
  my $got = $s->scan(code => 'require 5.005');
  my @list = $got->items;
  is(scalar(@list), 1);
  is($list[0]->ver, '5.005');
}
{
  my $got = $s->scan(file => 'samples/returns_list.pl');
  is(scalar($got->items), 1);
  ok(! ($got->items)[0]->fail, 'return');
}

# vim:ts=2:sw=2:et:sta
