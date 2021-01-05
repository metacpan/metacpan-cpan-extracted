#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Devel::WatchVars;
sub twice { return 2 * shift  }

my $x = 1;
watch($x, '$x');
say "starting watched value is $x";
my $y = 5 + twice(++$x);
say "ending watched value is $x";
say "but y is $y";
unwatch $x;

__END__
WATCH $x = 1 at examples/copied line 10.
FETCH $x --> 1 at examples/copied line 11.
starting watched value is 1
FETCH $x --> 1 at examples/copied line 12.
STORE $x <-- 2 at examples/copied line 12.
FETCH $x --> 2 at examples/copied line 7.
FETCH $x --> 2 at examples/copied line 13.
ending watched value is 2
but y is 9
UNWATCH $x = 2 at examples/copied line 15.
