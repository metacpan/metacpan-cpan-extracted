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

# fetch values, check the value returned by STORE as well
is_deeply($hmk{[join $;, @{$mk[$_]}]}, $v[$_], "fetch key $_") foreach 0..$#mk;
