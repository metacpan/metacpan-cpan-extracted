package Game::Durak::Bot;

use strict;
use warnings;

use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Durak::Search qw(best LEVELS);

our $VERSION = '0.01';

our @LADDER = (1, 1, 2, 3, 3);

has level => (is => 'ro', isa => Int);
has seed  => (is => 'ro', isa => Str);

sub levels { return LEVELS }

sub level_for {
    my ($class, $asked) = @_;
    return $LADDER[0] unless defined $asked && $asked =~ /\A[0-9]+\z/ && $asked >= 1;
    return $asked > @LADDER ? $LADDER[-1] : $LADDER[ $asked - 1 ];
}

sub word_for {
    my ($self, $seat, $ply) = @_;
    my $seed = defined $self->seed ? $self->seed : '';
    return unpack 'N', Digest::SHA::sha256("$seed:$seat:$ply");
}

sub choose {
    my ($self, $view) = @_;
    return undef unless $view && $view->{legal} && @{ $view->{legal} };
    my $level = $self->level;
    $level = 1 unless defined $level;
    return best($view, $level, $self->word_for($view->{seat}, $view->{ply}));
}

sub hint {
    my ($class, $view) = @_;
    return undef unless $view && $view->{legal} && @{ $view->{legal} };
    return best($view, LEVELS, 0);
}

1;

__END__

=head1 NAME

Game::Durak::Bot - a seat at a level, playing from a view

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bot = Game::Durak::Bot->new(level => 3, seed => $seed);

    my $move = $bot->choose($game->view($seat));
    $game->apply($seat, $move);

    Game::Durak::Bot->level_for(4);      # 3, the rung a consumer's level 4 gets
    Game::Durak::Bot->hint($view);       # what the top rung would do

=head1 DESCRIPTION

A level and a seed. Everything else is L<Game::Durak::Search>, and like that
module this one never sees a game: C<choose> takes the same view a consumer
sends to a browser, so a bot cannot read a hand it is not holding however
badly a caller wires it up.

=head2 The ladder is a mapping, not a list of behaviours

    our @LADDER = (1, 1, 2, 3, 3);

A consumer with five bot levels gets three rungs, weakest first, because the
engine has three and pretending otherwise would put two identical opponents
on a leaderboard with different names. Which of the five maps to which rung
is a judgement to be B<measured> rather than declared, and F<bin/ladder> is
how: the mapping above is the one the measurement in F<docs/measured.md>
supports.

The list is written weakest first because C<hint> reaches for the top and a
consumer's level test asserts the order.

=head2 The word, and why a bot is reproducible

C<word_for> hashes the bot's seed with the seat and the ply, so rung 1's
choice and every tie-break above it are a function of the seed and the
position. Two bots of the same rung in one deal are handed different words
because the seat is in the hash, which is what stops a bot versus bot deal
from being a mirror.

=head1 METHODS

=head2 level, seed

What the bot was built with. A missing level plays rung 1; a missing seed
still works and plays the same deal every time, which is a test fixture and
not a game.

=head2 choose

    $bot->choose($view);

A move from the view's C<legal>, or undef when there is nothing to do.

=head2 hint

    Game::Durak::Bot->hint($view);

What the top rung would play, for a consumer that offers a nudge. A class
method: a hint has no seed and no level of its own.

=head2 word_for

    $bot->word_for($seat, $ply);

The 32-bit word for one position, hashed from the bot's seed with the seat
and the ply. Public because a consumer that wants a bot's choice without
building a view can ask for the same number, and because a test that wants to
prove two seats differ has to be able to see it.

=head2 level_for

    Game::Durak::Bot->level_for($n);

The rung a consumer's level maps to. Out of range clamps rather than dies,
because a consumer's levels are not this module's to police.

=head2 levels

Three, from L<Game::Durak::Search>.

=head1 SEE ALSO

L<Game::Durak::Search>, L<Game::Durak>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
