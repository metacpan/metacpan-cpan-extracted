#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Devel::WatchVars;
sub twice { return 2 * shift  }

my $x = 1;
watch($x, '$x');
say "starting watched value is $x";
$x = 5 + twice(++$x);
say "ending watched value is $x";
unwatch $x;
say "done with program";

__END__
WATCH $x = 1 at examples/simple line 10.
FETCH $x --> 1 at examples/simple line 11.
starting watched value is 1
FETCH $x --> 1 at examples/simple line 12.
STORE $x <-- 2 at examples/simple line 12.
FETCH $x --> 2 at examples/simple line 7.
STORE $x <-- 9 at examples/simple line 12.
FETCH $x --> 9 at examples/simple line 13.
ending watched value is 9
UNWATCH $x = 9 at examples/simple line 14.
done with program
