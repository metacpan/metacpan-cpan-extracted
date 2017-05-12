#!/usr/bin/perl
#
# Example Mastermind solver by David Landgren
#
# take 3
#

use strict;
use Games::Mastermind;
use List::Util 'shuffle';

my $game  = Games::Mastermind->new;
my $holes = $game->holes;
my @pegs  = @{ $game->pegs };

my @guess;
my %seen;
my $result = [ 0, 0 ];
for my $p( @pegs ) {
    my @x = ($p) x $holes;
    $result = $game->play( @x );
    $seen{"@x"} = [@$result];
    print "@x | @$result\n";
    my $nr = $result->[0]+$result->[1];
    push @guess, $p while $nr-- > 0;
    last if @guess == $holes;
}

while ( defined $result && $result->[0] != $holes ) {
    GUESS: while( 1 ) {
        do { @guess = shuffle @guess } while exists $seen{"@guess"};
        for my $g( keys %seen ) {
            my $r = $seen{$g};
            my @g = split / /, $g;
            if( $r->[0] > 0 ) {
                my $same = 0;
                $g[$_] eq $guess[$_] and ++$same for 0..$#g;
                redo GUESS if $same != $r->[0];
            }
            # print "<@guess> vs <@g> black $r->[0]\n";
        }
        last;
    }
    $result = $game->play(@guess);
    $seen{"@guess"} = [@$result];
    print "@guess | @$result\n";
}
