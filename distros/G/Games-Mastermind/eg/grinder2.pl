#!/usr/bin/perl
#
# Example Mastermind solver by David Landgren
#
# take 2
#

use strict;
use Games::Mastermind;
use List::Util 'shuffle';

my $game  = Games::Mastermind->new( @ARGV );
my $holes = $game->holes;
my @pegs  = @{ $game->pegs };

my @guess;
my %seen;
my $result = [ 0, 0 ];
for my $p( @pegs ) {
    my @x = ($p) x $holes;
    $result = $game->play( @x );
    $seen{"@x"}++;
    print "@x | @$result\n";
    my $nr = $result->[0]+$result->[1];
    push @guess, $p while $nr-- > 0;
    last if @guess == $holes;
}

while ( defined $result && $result->[0] != $holes ) {
    do { @guess = shuffle @guess } until !$seen{"@guess"}++;
    $result = $game->play(@guess);
    print "@guess | @$result\n";
}
