#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Devel::WatchVars;
sub twice { return 2 * shift  }

{
    my $x = 1;
    watch($x, '$x');
    say "starting watched value is $x";
    $x = 5 + twice(++$x);
    say "ending watched value is $x";
    say "about to go out of scope";
}

say "x is out of scope";

__END__
WATCH $x = 1 at examples/destroyed line 11.
FETCH $x --> 1 at examples/destroyed line 12.
starting watched value is 1
FETCH $x --> 1 at examples/destroyed line 13.
STORE $x <-- 2 at examples/destroyed line 13.
FETCH $x --> 2 at examples/destroyed line 7.
STORE $x <-- 9 at examples/destroyed line 13.
FETCH $x --> 9 at examples/destroyed line 14.
ending watched value is 9
about to go out of scope
DESTROY $x = 9 at examples/destroyed line 15.
x is out of scope
