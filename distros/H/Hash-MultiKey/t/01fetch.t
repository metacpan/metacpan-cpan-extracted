# -*- Mode: CPerl -*-

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Hash::MultiKey') }

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

# initialize %hmk, check value returned by STORE as well
is_deeply($hmk{$mk[$_]} = $v[$_], $v[$_], 'storing') foreach 0..$#mk;

# fetch values
is_deeply($hmk{$mk[$_]}, $v[$_], "fetch key $_") foreach 0..$#mk;


