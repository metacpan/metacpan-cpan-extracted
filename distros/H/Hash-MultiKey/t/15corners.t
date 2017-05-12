# -*- Mode: CPerl -*-

use strict;
use warnings;

use Test::More 'no_plan';

use Hash::MultiKey;

tie my (%hmk), 'Hash::MultiKey';

my @mk = ([""],
          ["", "", ""],
          ["", "", "", ""],
          ["", "", "", "", "", ""],);

my @v = (undef,
         1,
         'string',
         ['array', 'ref'],);

# initialize %hmk
$hmk{$mk[$_]} = $v[$_] foreach 0..$#mk;

# fetch values
is_deeply($hmk{$mk[$_]}, $v[$_], "fetch key $_") foreach 0..$#mk;

# delete all
foreach my $i (0..$#mk) {
    is_deeply(delete $hmk{$mk[$i]}, $v[$i], "delete key $i");
    ok(!exists $hmk{$mk[$i]}, "! exists key $i");
}

ok(!scalar(%hmk), 'scalar empty %hmk')
