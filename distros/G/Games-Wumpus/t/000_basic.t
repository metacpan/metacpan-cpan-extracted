#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    foreach my $pkg (qw [Games::Wumpus::Constants Games::Wumpus::Room
                         Games::Wumpus::Cave      Games::Wumpus]) {
        use_ok ($pkg) or BAIL_OUT ("Loading of '$pkg' failed");
    }
}

ok defined $Games::Wumpus::VERSION, "VERSION is set";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
