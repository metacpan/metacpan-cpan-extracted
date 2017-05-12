#!/usr/bin/perl

# This script was featured in the article:
# http://www.perl.com/pub/a/2003/11/17/lmsolve.html

package Jumping::Cards;

use strict;

use Games::LMSolve::Base;

use vars qw(@ISA);

@ISA=qw(Games::LMSolve::Base);

sub input_board
{
    my $self = shift;

    my $filename = shift;

    return [ 1 .. 8 ];
}

# A function that accepts the expanded state (as an array ref)
# and returns an atom that represents it.
sub pack_state
{
    my $self = shift;
    my $state_vector = shift;
    return join(",", @$state_vector);
}

# A function that accepts an atom that represents a state
# and returns an array ref that represents it.
sub unpack_state
{
    my $self = shift;
    my $state = shift;
    return [ split(/,/, $state) ];
}

# Accept an atom that represents a state and output a
# user-readable string that describes it.
sub display_state
{
    my $self = shift;
    my $state = shift;
    return $state;
}

sub check_if_final_state
{
    my $self = shift;

    my $coords = shift;
    return join(",", @$coords) eq "8,7,6,5,4,3,2,1";
}

# This function enumerates the moves accessible to the state.
# If it returns a move, it still does not mean that it is a valid
# one. I.e: it is possible that it is illegal to perform it.
sub enumerate_moves
{
    my $self = shift;

    my $state = shift;

    my (@moves);
    for my $i (0 .. 6)
    {
        for my $j (($i+1) .. 7)
        {
            my @new = @$state;
            @new[$i,$j]=@new[$j,$i];
            my $is_ok = 1;
            for my $t (0 .. 6)
            {
                if (abs($new[$t]-$new[$t+1]) > 3)
                {
                    $is_ok = 0;
                    last;
                }
            }
            if ($is_ok)
            {
                push @moves, [$i,$j];
            }
        }
    }
    return @moves;
}

# This function accepts a state and a move. It tries to perform the
# move on the state. If it is succesful, it returns the new state.
#
# Else, it returns undef to indicate that the move is not possible.
sub perform_move
{
    my $self = shift;

    my $state = shift;
    my $m = shift;

    my @new = @$state;

    my ($i,$j) = @$m;
    @new[$i,$j]=@new[$j,$i];
    return \@new;
}

sub render_move
{
    my $self = shift;

    my $move = shift;

    if (defined($move))
    {
        return join(" <=> ", @$move);
    }
    else
    {
        return "";
    }
}

package main;

my $solver = Jumping::Cards->new();
$solver->main();


