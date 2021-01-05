#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Devel::WatchVars;
sub treble { $_ *= 3 for @_ }

my @nums = (0 .. 4);
watch $nums[2], "element[2] of array";

say "initial array is @nums";
treble(@nums);

say "final array is @nums";

unwatch $nums[2];
say "done with program";

__END__
WATCH element[2] of array = 2 at examples/array line 10.
FETCH element[2] of array --> 2 at examples/array line 12.
initial array is 0 1 2 3 4
FETCH element[2] of array --> 2 at examples/array line 7.
STORE element[2] of array <-- 6 at examples/array line 7.
FETCH element[2] of array --> 6 at examples/array line 15.
final array is 0 3 6 9 12
UNWATCH element[2] of array = 6 at examples/array line 17.
done with program
