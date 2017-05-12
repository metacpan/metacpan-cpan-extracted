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

# positive exists
ok(exists $hmk{[join $;, @{$mk[$_]}]}, "exists key $_") foreach 0..$#mk;

# negative exists
my @nmk = (["hoo"],                                     # beginning
           ["foo", "bar"],                              # intermediate
           ["foo", "bar", "baz", "zoo", "none here"],); # end

ok(!exists $hmk{[join $;, @{$nmk[$_]}]}, "! exists key $_") foreach 0..$#nmk;
