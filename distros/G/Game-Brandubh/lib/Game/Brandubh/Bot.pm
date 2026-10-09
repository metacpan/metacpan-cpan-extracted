package Game::Brandubh::Bot;

use 5.010;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();

our $VERSION = '0.01';

our @LADDER = (1_000, 10_000, 10_000, 100_000);

our %SLIP = (
    1_000   => 20,
    10_000  => 0,
    100_000 => 0,
);

our $LEVEL;

sub levels {
    my %seen;
    return grep { !$seen{$_}++ } sort { $a <=> $b } @LADDER;
}

sub _number {
    my (@parts) = @_;
    return unpack 'N', Digest::SHA::sha256(join '|', map { defined $_ ? $_ : '' } @parts);
}

sub level_for {
    my ($class, $seed) = @_;
    return $LADDER[ int(@LADDER / 2) ] unless defined $seed;
    return $LADDER[ _number('level', $seed) % @LADDER ];
}

sub slip_for {
    my ($class, $level) = @_;
    return 0 unless defined $level && exists $SLIP{$level};
    return $SLIP{$level};
}

sub _level {
    my ($class, %with) = @_;
    my $level = defined $with{level} ? $with{level}
              : defined $LEVEL       ? $LEVEL
              :                        $class->level_for($with{seed});
    Carp::croak('Game::Brandubh::Bot: a level is a whole number of positions to search, from 1 up')
        unless !ref $level && $level =~ /\A[0-9]{1,9}\z/ && $level >= 1;
    return $level;
}

sub choose {
    my ($class, $game, %with) = @_;
    my $thought = $class->think($game, %with);
    return $thought ? $thought->{move} : undef;
}

sub think {
    my ($class, $game, %with) = @_;
    Carp::croak('Game::Brandubh::Bot: choose takes a Game::Brandubh')
        unless ref $game && $game->can('search') && $game->can('legal');
    return undef unless $game->status eq 'active';

    my $level = $class->_level(%with);
    my $seat  = $game->turn;
    my $seed  = $with{seed};

    my $slip = defined $with{slip} ? $with{slip} : $class->slip_for($level);
    if ($slip && _number('slip', $seed, $seat, $game->ply, $game->signature) % 100 < $slip) {
        my $legal = $game->legal;
        my $move = $legal->[ _number('which', $seed, $seat, $game->ply, $game->signature) % @$legal ]{move};
        return { move => $move, level => $level, slipped => 1, depth => 0, nodes => 0, score => undef };
    }

    my $found = $game->search(
        budget => $level,
        salt   => join('|', 'bot', (defined $seed ? $seed : ''), $seat),
        (defined $with{weights} ? (weights => $with{weights}) : ()),
    );
    return undef unless $found;
    return {
        move    => $found->{move},
        level   => $level,
        slipped => 0,
        depth   => $found->{depth},
        nodes   => $found->{nodes},
        score   => $found->{score},
    };
}

sub hint {
    my ($class, $game, %with) = @_;
    return $class->choose($game, %with, level => $LADDER[-1], slip => 0);
}

1;

__END__

=head1 NAME

Game::Brandubh::Bot - a program that plays brandubh, at three strengths

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Brandubh;
    use Game::Brandubh::Bot;

    my $game = Game::Brandubh->new;

    until ($game->status eq 'finished') {
        my $move = Game::Brandubh::Bot->choose($game, seed => $thirty_two_bytes);
        $game->play($move);
    }

    my $better = Game::Brandubh::Bot->hint($game);

=head1 DESCRIPTION

Chooses a move for whichever side is to move. It is L<Game::Brandubh/search>
with levels of play on top, and it holds nothing: every method is called on
the class, and the game is the only state there is.

=head2 A level is a number of positions

How strong the program plays is how many positions it may look at before it
chooses: 1,000, 10,000 or 100,000. It is never a number of seconds. The same
game, level and seed give the same move every time, on a busy machine as on an
idle one, so a game against the program can be played again move for move.

The weakest level also plays a move picked without thought one time in five.
A program that only looks less far ahead is still a careful player; this one
is meant to be beaten by somebody learning the game.

=head2 The seed

C<seed> is any string, and in practice the thirty-two bytes a game was made
with. From it the program draws which level to play, when no level is given,
and which of several equally good moves to choose. Two programs given
different seeds do not play the same game. A program given none always plays
the same way.

=head1 VARIABLES

=head2 @LADDER

The levels a seed draws from, weakest first. A level that appears twice is
drawn twice as often.

=head2 %SLIP

For each level, out of a hundred, how often a move is picked without thought.

=head2 $LEVEL

When set, the level every call plays at unless it is given one. For tests.

=head1 METHODS

=head2 choose

    my $move = Game::Brandubh::Bot->choose($game);
    my $move = Game::Brandubh::Bot->choose($game, seed => $bytes, level => 10_000);

A move for the side to move, as it is stored, or C<undef> when the game is
finished. The game is not changed.

=over 4

=item C<seed>

See L</The seed>.

=item C<level>

How many positions to look at. When left out it is C<$LEVEL> if that is set,
and otherwise the level the seed draws.

=item C<slip>

Out of a hundred, how often to pick a move without thought. The level's own
figure when left out.

=item C<weights>

Passed to the search: see L<Game::Brandubh::Rules/weights>. For measuring the
program, not for playing against it.

=back

B<Croaks> when it is not given a game, or is given a level that is not a whole
number.

=head2 think

    my $thought = Game::Brandubh::Bot->think($game, seed => $bytes);

C<choose>, with its working shown. Takes what C<choose> takes and returns a
hash reference, or C<undef> when the game is finished: C<move>; C<level>, the
level it played at; C<slipped>, true when the move was picked without thought;
and, when it was not, C<depth>, C<nodes> and C<score> as
L<Game::Brandubh/search> reports them.

=head2 hint

    my $move = Game::Brandubh::Bot->hint($game);

The move the strongest level would choose, with no slip.

=head2 level_for

    my $level = Game::Brandubh::Bot->level_for($seed);

The level a seed draws from C<@LADDER>. The same seed always draws the same
level. With no seed, the middle of the ladder.

=head2 slip_for

    my $percent = Game::Brandubh::Bot->slip_for($level);

How often that level picks a move without thought, out of a hundred.

=head2 levels

    my @levels = Game::Brandubh::Bot->levels;

The different levels there are, weakest first.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
