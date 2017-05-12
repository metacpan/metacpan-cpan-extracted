#!/usr/bin/perl
#
# $Id: 01basic.t,v 1.1 2004/03/05 14:59:36 nik Exp $

use strict;
use warnings;
use Test::More tests => 13;

if(eval "require Test::Differences") {
  no warnings 'redefine';
  *is_deeply = \&Test::Differences::eq_or_diff;
}

BEGIN {
  use_ok('List::PowerSet', qw(powerset powerset_lazy));
}

my $ps = powerset(qw(1 2 3));

is(ref $ps, 'ARRAY', 'powerset() returned an array ref');
is(scalar @$ps, 8, '  with the right number of elements');

my $expected = [ [1, 2, 3], [2, 3], [1, 3], [3], [1, 2], [2], [1], [] ];

is_deeply($ps, $expected, '  and they\'re the expected elements');

$ps = powerset_lazy(1..3);

is(ref $ps, 'CODE', 'powerset_lazy() returned a code ref');

# Make sure that the results from powerset_lazy() match up with the
# expected results
my $i = 0;
while(my $set = $ps->()) {
  is_deeply($set, $expected->[$i], "  element $i matches");
  $i++;
}
