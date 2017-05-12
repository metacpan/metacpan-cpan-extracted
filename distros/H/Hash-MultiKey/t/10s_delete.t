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

# delete all
foreach my $i (0..$#mk) {
    # delete must return the element being removed if it exists
    is_deeply(delete $hmk{[join $;, @{$mk[$i]}]}, $v[$i], "delete key $i");
    ok(!exists $hmk{[join $;, @{$mk[$i]}]}, "! exists key $i");
}

# delete must return undef on non-existent entries
ok(!defined $hmk{'zoo'}, 'delete non-existent entries');
