#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Devel::WatchVars;
sub twice { return 2 * shift  }

my $x = 1;
my $sref = \$x;
watch($x, '$x');
say "starting watched value is $x";
$x = 5 + twice(++$x);
say "value through ref is $$sref";
say "ending watched value is $x";
unwatch $x;
say "x is still $x";
say "value through ref is $$sref";

__END__
WATCH $x = 1 at examples/refs line 11.
FETCH $x --> 1 at examples/refs line 12.
starting watched value is 1
FETCH $x --> 1 at examples/refs line 13.
STORE $x <-- 2 at examples/refs line 13.
FETCH $x --> 2 at examples/refs line 7.
STORE $x <-- 9 at examples/refs line 13.
FETCH $x --> 9 at examples/refs line 14.
value through ref is 9
FETCH $x --> 9 at examples/refs line 15.
ending watched value is 9
UNWATCH $x = 9 at examples/refs line 16.
x is still 9
value through ref is 9
