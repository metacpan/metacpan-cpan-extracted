#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('List::oo', qw(L)); }
use strict;
use warnings;
use Data::Dumper;

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);
my @a2 = qw(baker camera delta baker delta edward abel hilton);

{
  my ($l, $r) = L(@a0)->part(sub {m/^a/});
  isa_ok($_, 'List::oo') for($l,$r);
  is_deeply($l, [qw(baker camera delta edward fargo golfer)], 'left');
  is_deeply($r, [qw(abel abel)], 'right');
}
{
  my ($A,$B,$O) = L(@a2)->part(sub {m/^a/ ? 0 : (m/^b/ ? 1 : 2)});
  isa_ok($_, 'List::oo') for($A,$B,$O);
  is_deeply($A, [qw(abel)], 'A');
  is_deeply($B, [qw(baker baker)], 'B');
  is_deeply($O, [qw(camera delta delta edward hilton)], 'O');
}
{
  my ($A,$B,$D,$O) = L(@a2)->
    part(sub {m/^a/ ? 0 : (m/^b/ ? 1 : (m/^d/ ? 2 : 3))});
  isa_ok($_, 'List::oo') for($A,$B,$O);
  is_deeply($A, [qw(abel)], 'A');
  is_deeply($B, [qw(baker baker)], 'B');
  is_deeply($D, [qw(delta delta)], 'D');
  is_deeply($O, [qw(camera edward hilton)], 'O');
}
{ # mesh
  my $x = L(qw(a b c d));
  my @y = qw(1 2 3 4);
  my $z = $x->mesh(@y);
  is_deeply($z, [qw(a 1 b 2 c 3 d 4)], 'mesh');
}
{ # mmesh
  my $a = L('x');
  my @b = ('1', '2');
  my @c = qw(zip zap zot);
  my $d = $a->mmesh(\@b, \@c);
  my @want = ('x', '1', 'zip', undef, '2', 'zap', undef, undef, 'zot');
  is_deeply($d, [@want], 'mmesh');
}
{ # each_array
  my $l1 = L(qw(a b c));
  my $l2 = L(qw(A B C));
  my $it = $l1->each_array(@$l2);
  my @ans;
  while(my @said = $it->()) {
    push(@ans, [@said]);
  }
  my @expect = map({[$l1->[$_], $l2->[$_]]} 0..2);
  is_deeply(\@ans, \@expect, 'each_array');
}
{ # meach_array
  my $l1 = L(qw(a b c));
  my $l2 = L(qw(A B C));
  my $l3 = L(qw(1 2 3));
  my $it = $l1->meach_array($l2, $l3);
  my @ans;
  while(my @said = $it->()) {
    push(@ans, [@said]);
  }
  my @expect = map({[$l1->[$_], $l2->[$_], $l3->[$_]]} 0..2);
  is_deeply(\@ans, \@expect, 'meach_array');
}

# vim:ts=2:sw=2:et:sta:syntax=perl
