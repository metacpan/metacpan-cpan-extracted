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

# positive exists
ok(exists $hmk{$mk[$_]}, "exists key $_") foreach 0..$#mk;

# negative exists
my @nmk = (["hoo"],                                     # beginning
           ["foo", "bar"],                              # intermediate
           ["foo", "bar", "baz", "zoo", "none here"],); # end

ok(!exists $hmk{$nmk[$_]}, "! exists key $_") foreach 0..$#nmk;
