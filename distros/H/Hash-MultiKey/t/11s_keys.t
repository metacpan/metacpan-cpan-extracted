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

# all returned keys exists
ok(exists $hmk{$_}, "exists - all keys") foreach keys %hmk;

# in scalar context we get the number of keys
is(scalar(keys %hmk), scalar(@mk), "number of keys - all keys");

foreach my $i (0..$#mk) {
    delete $hmk{[join $;, @{$mk[$i]}]};
    ok(exists $hmk{$_}, "exists - $i") foreach keys %hmk;
    is(scalar(keys %hmk), $#mk - $i, "number of keys - $i");
}
