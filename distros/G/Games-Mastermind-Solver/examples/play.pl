#!/usr/bin/perl -w

use strict;
use warnings;
use lib 'lib';

use Games::Mastermind;
use Games::Mastermind::Solver::BruteForce;

my $player = Games::Mastermind::Solver::BruteForce
                 ->new( Games::Mastermind->new );
my $try;

print join( ' ', @{$player->game->code} ), "\n\n";

until( $player->won || ++$try > 10 ) {
    my( $win, $guess, $result ) = $player->move;

    print join( ' ', @$guess ),
          '  ',
          'B' x $result->[0], 'W' x $result->[1],
          "\n";
}
