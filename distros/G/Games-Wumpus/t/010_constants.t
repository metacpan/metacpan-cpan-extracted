#!/usr/bin/perl

use 5.010;

use strict;
use warnings;
no warnings 'syntax';

use Test::More 0.88;

use Games::Wumpus::Constants;

our $r = eval "require Test::NoWarnings; 1";

is $WUMPUS, 1, '$WUMPUS';
is $BAT,    2, '$BAT';
is $PIT,    4, '$PIT';
is $PLAYER, 8, '$PLAYER';

is $NR_OF_WUMPUS, 1, '$NR_OF_WUMPUS';
is $NR_OF_BATS,   2, '$NR_OF_BATS';
is $NR_OF_PITS,   2, '$NR_OF_PITS';
is $NR_OF_ARROWS, 5, '$NR_OF_ARROWS';

is scalar @HAZARDS, 3, "3 Hazards";
ok grep ({$_ == $WUMPUS} @HAZARDS), "Wumpus is a hazard";
ok grep ({$_ == $BAT   } @HAZARDS), "Bat is a hazard";
ok grep ({$_ == $PIT   } @HAZARDS), "Pit is a hazard";

is $WUMPUS_MOVES, .75, '$WUMPUS_MOVES';

Test::NoWarnings::had_no_warnings () if $r;

done_testing;


__END__
