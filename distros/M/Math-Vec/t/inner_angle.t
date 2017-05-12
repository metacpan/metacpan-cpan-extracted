#!/usr/bin/perl

# http://rt.cpan.org/Public/Bug/Display.html?id=25373

use strict;
use warnings;

use Test::More qw(no_plan);

use Math::Vec qw();

my $pi = 4*atan2(1,1);

is(Math::Vec::Support::acos(1.00000000000001), 0,    'acos(1)');
is(Math::Vec::Support::acos(-1.00000000000001), $pi, 'acos(-1)');

my ($x1, $y1, $x2, $y2, $x3, $y3) = (
  184.818732905007, 1.88127517013888,
  183.75578943, 1.9146946049724,
  182.742125596, 1.94656466818785,
);
 
my $v1 = Math::Vec->new($x2-$x1, $y2-$y1);
my $v2 = Math::Vec->new($x2-$x3, $y2-$y3);

my $angle = $v1->InnerAngle($v2);
ok(abs($angle - $pi) < 0.1, 'roughly pi');
ok(! ref($angle));

# vim:ts=2:sw=2:et:sta
