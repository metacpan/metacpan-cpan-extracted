#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Devel::WatchVars;

sub treble { $_ *= 3 for @_ }

my %color = (
    red   => 1,
    blue  => 3,
    green => 5,
);

watch $color{blue}, "the blue color element";

say "initial hash is (", join(", " => (map { "$_ => $color{$_}" } sort keys %color)), ")";
treble(values %color);
say "final hash is (",   join(", " => (map { "$_ => $color{$_}" } sort keys %color)), ")";

unwatch $color{blue};

say "done with program";

__END__
WATCH the blue color element = 3 at examples/hash line 16.
FETCH the blue color element --> 3 at examples/hash line 18.
initial hash is (blue => 3, green => 5, red => 1)
FETCH the blue color element --> 3 at examples/hash line 8.
STORE the blue color element <-- 9 at examples/hash line 8.
FETCH the blue color element --> 9 at examples/hash line 20.
final hash is (blue => 9, green => 15, red => 3)
UNWATCH the blue color element = 9 at examples/hash line 22.
done with program
