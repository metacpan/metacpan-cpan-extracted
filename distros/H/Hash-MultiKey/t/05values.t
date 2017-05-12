# -*- Mode: CPerl -*-

use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;

use Hash::MultiKey;

tie my (%hmk), 'Hash::MultiKey';

my @mk = (["foo"],
          ["foo", "bar", "baz"],
          ["foo", "bar", "baz", "zoo"],
          ["goo"],
          ["goo", "car", "caz"],
          ["goo", "car", "caz", "aoo"],
          ["branch", "with", "no", "bifur$;ations"],);

my @v = (undef,
         1,
         'string',
         ['array', 'ref'],
         {hash => 'ref', with => 'three', keys => undef},
         \7,
         undef,);

# initialize %hmk
$hmk{$mk[$_]} = $v[$_] foreach 0..$#mk;

# values must be returned in the same order as keys reports their
# corresponding keys
my @v_in_keys_order = ();
push @v_in_keys_order, $hmk{$_} foreach keys %hmk;
is_deeply([values %hmk], \@v_in_keys_order, "values - all");

# aliased values?
$_ = 1 foreach values %hmk;
is($_, 1, 'aliased value (1)') foreach values %hmk;

foreach my $v (values %hmk) {
    $v =~ s/1/2/g;
}
is($_, 2, 'aliased value (2)') foreach values %hmk;

# initialize %hmk again
$hmk{$mk[$_]} = $v[$_] foreach 0..$#mk;

foreach my $i (0..$#mk) {
    delete $hmk{$mk[$i]};
    @v_in_keys_order = ();
    push @v_in_keys_order, $hmk{$_} foreach keys %hmk;
    is_deeply([values %hmk], \@v_in_keys_order, 'values - all');
}
