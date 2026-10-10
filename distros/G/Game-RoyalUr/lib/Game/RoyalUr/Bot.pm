package Game::RoyalUr::Bot;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

use Game::RoyalUr::Engine ();
use Game::RoyalUr::Variant;

our $VERSION = '0.01';

my $E = 'Game::RoyalUr::Engine';

my (%LADDER, %FINKEL, %MASTERS);
BEGIN {
    %FINKEL  = (exposed => 16, rosette => 16, entry => 8);
    %MASTERS = (exposed => 16);
    %LADDER = (
        short => [
            { greedy => 1 },
            { depth => 2, weights => { %FINKEL } },
            { depth => 3, weights => { %FINKEL } },
            { depth => 4, weights => { %FINKEL } },
        ],
        long => [
            { greedy => 1 },
            { depth => 2, weights => { %MASTERS } },
            { depth => 3, weights => { %MASTERS } },
            { depth => 4, weights => { %MASTERS } },
        ],
    );
}

has level => (is => 'ro');

has budget => (is => 'ro', default => 1_000_000);

sub BUILD {
    my ($self) = @_;
    my $level = $self->level;
    Carp::croak('Game::RoyalUr::Bot: a level is a whole number from 1 up')
        if defined $level && $level !~ /\A[1-9]\d?\z/;
    my $budget = $self->budget;
    Carp::croak('Game::RoyalUr::Bot: a budget is a whole number of positions from 1 to 2000000000')
        unless defined $budget && $budget =~ /\A[1-9]\d{0,9}\z/ && $budget <= 2_000_000_000;
    return;
}

my $rungs = sub {
    my ($rules) = @_;
    return $LADDER{ Game::RoyalUr::Variant->of($rules)->route };
};

sub levels {
    my ($invocant, $rules) = @_;
    my $top = scalar @{ $rungs->($rules) };
    return 1 .. $top;
}

sub rung {
    my ($invocant, $level, $rules) = @_;
    my $ladder = $rungs->($rules);
    Carp::croak("Game::RoyalUr::Bot: there is no level '" . ($level // 'undef') . "'; the levels are 1 to " . @$ladder)
        unless defined $level && $level =~ /\A\d+\z/ && $level >= 1 && $level <= @$ladder;
    my $rung = $ladder->[ $level - 1 ];
    return { %$rung, ($rung->{weights} ? (weights => { %{ $rung->{weights} } }) : ()) };
}

sub level_for {
    my ($self, $rules) = @_;
    my $top = scalar @{ $rungs->($rules) };
    my $level = $self->level;
    return $top unless defined $level;
    return $level > $top ? $top : $level;
}

sub think {
    my ($self, $game) = @_;
    my @legal = $game->legal;
    return undef unless @legal;

    my $variant = $game->variant;
    my $rules = $variant->as_hash;
    my $level = $self->level_for($variant);
    my $rung = $rungs->($variant)->[ $level - 1 ];

    my ($board, $code) = $E->of_string($game->position);
    Carp::croak("Game::RoyalUr::Bot: the game's position was refused, code $code") unless $board;

    my $found;
    if ($rung->{greedy}) {
        $found = { index => $board->greedy($game->roll, $rules), depth => 0, value => undef, nodes => '0', stopped => 0 };
    }
    else {
        $found = $board->search($game->roll,
            rules => $rules, depth => $rung->{depth}, budget => $self->budget, weights => $rung->{weights});
    }
    Carp::croak('Game::RoyalUr::Bot: the search found no move where the game has one')
        unless $found->{index} >= 0 && $found->{index} < @legal;
    return { %$found, level => $level, move => $legal[ $found->{index} ] };
}

sub choose {
    my ($self, $game) = @_;
    my $thought = $self->think($game);
    return $thought ? $thought->{move} : undef;
}

1;

__END__

=head1 NAME

Game::RoyalUr::Bot - an opponent for the Royal Game of Ur, at several strengths

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr;
    use Game::RoyalUr::Bot;

    my $game = Game::RoyalUr->new(seed => $seed);
    my $bot  = Game::RoyalUr::Bot->new(level => 2);

    until ($game->is_over) {
        $game->play($bot->choose($game));
    }

=head1 DESCRIPTION

Something to play against. A bot is handed a game with a roll waiting and
answers with one of the game's own legal moves. It does not make the move,
keeps nothing between one move and the next, and the same bot asked the same
question gives the same answer.

=head2 The levels

A level is a rung of a ladder, 1 the weakest. Each rung was played against the
one below it over thousands of games with the same dice from both seats, and
B<is on the ladder because it won>: a rung that could not be told from the
one below it was taken out, not renamed.

The two routes have different ladders, because what wins on one does not
always win on the other.

Level 1 does not look ahead. It captures if it can, lands on a rosette if it
cannot, and otherwise moves its piece that is furthest along.

Every level above it looks ahead through the dice: it weighs every roll that
could come by how likely it is, supposes each side then makes the move that is
best for it, and so on for a number of rolls. Higher levels look further.
They also value more than how far the pieces have come: they count what a
piece left where it can be captured stands to lose, and, where the rules make
a rosette safe, the worth of holding one.

Dice are dice. A higher level wins more often, and still loses a great many
games to a lower one.

=head2 What a move costs

A search is bounded by the number of positions it may look at and never by
the time it takes, which is why its answer does not depend on the machine.
C<budget> is that number. Left alone it is large enough that no level is cut
short; set lower, a search that runs out answers from as far as it got.

=head1 METHODS

=head2 new

    my $bot = Game::RoyalUr::Bot->new;
    my $bot = Game::RoyalUr::Bot->new(level => 1, budget => 50_000);

=over 4

=item C<level>

A whole number from 1 up. Left out, the bot plays at the top of whatever
ladder the game's rules have; set higher than that ladder goes, it plays at
the top.

=item C<budget>

The most positions one search may look at, from 1 to 2,000,000,000. One
million when it is left out.

=back

B<Croaks> on a level or a budget that is not such a number.

=head2 level

The level the bot was made with, or C<undef> for the top.

=head2 budget

The most positions one search may look at.

=head2 choose

    my $move = $bot->choose($game);

One of the moves C<< $game->legal >> offers, or C<undef> when the game has
none to offer because it is over.

=head2 think

    my $thought = $bot->think($game);

As C<choose>, with what the bot knows about its answer, as a hash reference:

    { move => $move, level => 3, index => 1, depth => 3, value => 812,
      nodes => '3391', stopped => 0 }

C<level> is the level played, C<index> the move's place in C<< $game->legal >>,
and the rest are as L<Game::RoyalUr::Engine/search> returns them. At level 1
there is no search: C<depth> is 0 and C<value> is C<undef>.

=head2 levels

    my @levels = Game::RoyalUr::Bot->levels('masters');

The levels there are for a rule set, 1 to however many. A rule set with no
name has the ladder of its route.

=head2 level_for

    my $level = $bot->level_for($rules);

The level this bot plays at under a rule set: its own, or the top of that
ladder if its own is higher or was left out.

=head2 rung

    my $rung = Game::RoyalUr::Bot->rung(2, 'finkel');

What a level is, as a hash reference: C<< { greedy => 1 } >> for a level that
does not look ahead, or C<< { depth => ..., weights => { ... } } >>. A copy.
B<Croaks> on a level the rule set's ladder does not have.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
