#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Devel::WatchVars;
sub twice { return 2 * shift  }

our $x = 1;

watch($x, '$x');

say "starting watched value is $x";

$x = 5 + twice(++$x);

say "ending watched value is $x";
say "program is done";

exit;

__END__
WATCH $x = 1 at examples/global-destruction line 11.
FETCH $x --> 1 at examples/global-destruction line 13.
starting watched value is 1
FETCH $x --> 1 at examples/global-destruction line 15.
STORE $x <-- 2 at examples/global-destruction line 15.
FETCH $x --> 2 at examples/global-destruction line 7.
STORE $x <-- 9 at examples/global-destruction line 15.
FETCH $x --> 9 at examples/global-destruction line 17.
ending watched value is 9
program is done
DESTROY (during global destruction) $x = 9 at examples/global-destruction line 0.
