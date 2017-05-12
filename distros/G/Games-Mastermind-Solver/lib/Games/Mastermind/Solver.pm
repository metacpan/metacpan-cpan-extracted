package Games::Mastermind::Solver;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.02';

__PACKAGE__->mk_ro_accessors( qw(game won) );

sub new {
    my( $class, $game ) = @_;
    my $self = $class->SUPER::new( { game => $game } );
    $self->reset;
    return $self;
}

sub move {
    my( $self, $guess ) = @_;
    return ( 1, undef, undef ) if $self->won;

    $guess ||= $self->guess;
    my $result = $self->game->play( @$guess );
    if( $result->[0] == $self->game->holes ) {
        $self->{won} = 1;
    } else {
        $self->check( $guess, $result );
    }

    return ( $self->won, $guess, $result );
}

sub reset {
    my( $self ) = @_;
    $self->game->reset;
    $self->{won} = 0;
}

1;

__END__

=head1 NAME

Games::Mastermind::Solver - a Master Mind puzzle solver

=head1 SYNOPSIS

    # a trivial Mastermind solver

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

=head1 DESCRIPTION

C<Games::Mastermind::Solver> is a base class for Master Mind solvers.

=head1 METHODS

=head2 new

    $player = Games::Mastermind::Solver->new( $game );

Constructor. Takes a C<Games::Mastermind> object as argument.

=head2 move

    ( $won, $guess, $result ) = $player->move;
    ( $won, $guess, $result ) = $player->move( $guess );

The player chooses a suitable move to continue the game, plays it
against the game object passed as constructor and updates its knowledge
of the solution. The C<$won> return value is a boolean, C<$guess> is
an array reference holding the value passed to C<Games::Mastermind::play>
and C<$result> is the value returned  by C<play>.

It is possible to pass an array reference as the move to make.

=head2 remaining (optional)

    $number = $player->remaining;

The number of possible solutions given the knowledge the player has
accumulated.

=head2 reset

    $player->reset;

Resets the internal state of the player.

=head2 guess

    $guess = $player->guess;

Guesses a solution (to be implemented in a subclass).

=head2 check

    $player->check( $guess, $result );

Given a guess and the result for the guess, determines which positions
are still possible solutions for the game (to be implemented in a subclass).

=head2 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head2 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
