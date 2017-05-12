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

# fetch
eval { my $dummy = $hmk{[]} };
ok($@, 'fetch');

# store
eval { $hmk{[]} = 0 };
ok($@, 'store');

# delete
eval { delete $hmk{[]} };
ok($@, 'delete');

# exists
eval { exists $hmk{[]} };
ok($@, 'exists');


