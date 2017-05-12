package Games::Mastermind::Solver::BruteForce;

use strict;
use warnings;
use base qw(Games::Mastermind::Solver);

our $VERSION = '0.02';

sub guess {
    my( $self ) = @_;

    return [ _from_number( $self->_guess, $self->_pegs, $self->_holes ) ];
}

sub _guess {
    my( $self ) = @_;
    die 'Cheat!' unless $self->remaining;
    return $self->_possibility( rand $self->remaining );
}

sub remaining {
    my $p = $_[0]->_possibility;
    return $p ? scalar @$p : $_[0]->_peg_number ** $_[0]->_holes;
}

sub reset {
    my( $self ) = @_;
    $self->SUPER::reset;
    $self->{possibility} = undef;
}

sub _possibility {
    my( $self, $idx ) = @_;

    return $self->{possibility} if @_ == 1;
    return $self->{possibility} ? $self->{possibility}[$idx] : $idx;
}

sub check {
    my( $self, $guess, $result ) = @_;
    my $game = Games::Mastermind->new;
    my( $pegs, $holes, @new ) = ( $self->_pegs, $self->_holes );

    foreach my $try ( @{$self->_possibility || [0 .. $self->remaining - 1]} ) {
        $game->code( [ _from_number( $try, $pegs, $holes ) ] );
        my $try_res = $game->play( @$guess );
        push @new, $try if    $try_res->[0] == $result->[0]
                           && $try_res->[1] == $result->[1];
    }

    $self->{possibility} = \@new;
}

sub _from_number {
    my( $number, $pegs, $holes ) = @_;
    my $peg_number = @$pegs;
    return map { my $peg = $number % $peg_number;
                 $number = int( $number / $peg_number );
                 $pegs->[$peg]
                 } ( 1 .. $holes );
}

sub _peg_number { scalar @{$_[0]->game->pegs} }
sub _pegs  { $_[0]->game->pegs }
sub _holes { $_[0]->game->holes }

1;

__END__

=head1 NAME

Games::Mastermind::Solver::BruteForce - a Master Mind puzzle solver

=head1 SYNOPSIS

    # See Games::Mastermind::Solver

=head1 DESCRIPTION

C<Games::Mastermind::Solver::BruteForce> uses the classical
brute-force algorithm for solving Master Mind puzzles.

=head1 METHODS

=head2 remaining

    $number = $player->remaining;

The number of possible solutions given the knowledge the player has
accumulated.

=head2 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head2 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
