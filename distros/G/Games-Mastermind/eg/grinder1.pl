#!/usr/bin/perl
#
# Example Mastermind solver by David Landgren
#

use strict;
use Games::Mastermind;
use List::Util 'shuffle';

my $game  = Games::Mastermind->new;    # standard game
my $holes = $game->holes;
my @pegs  = @{ $game->pegs };

my %seen;
my $count;
my @guess;
my $result = [ 0, 0 ];
while ( defined $result && $result->[0] != $holes ) {
    do { @guess = map { $pegs[ rand @pegs ] } 1 .. $holes; }
        until !$seen{"@guess"}++;
    $result = $game->play(@guess);
    last if $result->[0] + $result->[1] == $holes;
    print ++$count, ": @guess | @$result\n";
}

if( $result->[0] != $holes ) {
    while ( defined $result && $result->[0] != $holes ) {
        do { @guess = shuffle @guess }
            until !$seen{"@guess"}++;
        $result = $game->play(@guess);
        print ++$count, ": @guess | @$result +\n";
    }
}
