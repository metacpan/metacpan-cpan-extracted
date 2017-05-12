# -*- Mode: CPerl -*-

use strict;
use warnings;

use Test::More 'no_plan';

use Hash::MultiKey;

tie my (%hmk), 'Hash::MultiKey';

my @mk = (["foo"],
          ["foo", "bar", "baz"],
          ["foo", "bar", "baz", "zoo"],
          ["goo"],
          ["goo", "car", "caz"],
          ["goo", "car", "caz", "aoo"],);

my @v = (undef,
         1,
         'string',
         ['array', 'ref'],
         {hash => 'ref', with => 'three', keys => undef},
         \7,);

# initialize %hmk
$hmk{[join $;, @{$mk[$_]}]} = $v[$_] foreach 0..$#mk;

# each in list context
while (my ($mk, $v) = each %hmk) {
    is_deeply($hmk{$mk}, $v, "each all: list context");
}

# each in scalar context
my $i = 0;
while (my $mk = each %hmk) {
    ++$i;
    ok(exists $hmk{$mk}, 'each all: scalar context');
}
is(scalar(keys %hmk), $i, 'each all: number of iterations');

foreach my $i (0..$#mk) {
    delete $hmk{[join $;, @{$mk[$i]}]};
    while (my ($mk, $v) = each %hmk) {
        is_deeply($hmk{$mk}, $v, "each $i: @$mk");
    }
}

# deletion of the last element must be safe
while (my ($mk, $v) = each %hmk) {
    is_deeply(delete $hmk{$mk}, $v, 'deletion in each');
}
