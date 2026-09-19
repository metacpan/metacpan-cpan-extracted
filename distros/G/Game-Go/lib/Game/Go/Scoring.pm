package Game::Go::Scoring;

use 5.010;
use strict;
use warnings;

use Game::Go::Rules;
use Game::Go::Result;

our $VERSION = '0.01';

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

sub stones_played {
	my ($game) = @_;
	my %n = ($B => 0, $W => 0);
	for my $e (@{ $game->log }) {
		next unless $e->{kind} eq 'play' || $e->{kind} eq 'handicap';
		my $who = Game::Go::Rules::from_letter($e->{actor}) or next;
		$n{$who}++;
	}
	return \%n;
}

sub raw { $_[0]->raw_score }

sub score {
	my ($game, %o) = @_;
	my $raw = $o{raw} || raw($game);

	my $bs = $raw->{score_b} / 10;
	my $ws = $raw->{score_w} / 10;

	my $winner = $bs > $ws ? $B : $ws > $bs ? $W : undef;

	return Game::Go::Result->new(
		winner    => $winner,
		result    => 'score',
		scored_by => $o{scored_by} || 'territory',
		scores    => { $B => $bs, $W => $ws },
		territory => { $B => $raw->{territory_b}, $W => $raw->{territory_w} },
		prisoners => { $B => $raw->{prisoners_b}, $W => $raw->{prisoners_w} },
		area      => { $B => $raw->{area_b},      $W => $raw->{area_w} },
		komi      => $game->komi,
		dame      => $raw->{dame},
	);
}

sub score_by_area {
	my ($game) = @_;
	my $a = $game->raw_area;

	my $bs = $a->{area_b};
	my $ws = $a->{area_w} + $game->komi;
	my $winner = $bs > $ws ? $B : $ws > $bs ? $W : undef;

	return Game::Go::Result->new(
		winner    => $winner,
		result    => 'score',
		scored_by => 'area',
		scores    => { $B => $bs, $W => $ws },
		territory => {},
		prisoners => {},
		area      => { $B => $a->{area_b}, $W => $a->{area_w} },
		komi      => $game->komi,
		dame      => $a->{dame},
	);
}

sub agree_under_equivalence {
	my ($game) = @_;

	return undef if @{ $game->marked_seki };

	my $played = stones_played($game);
	return undef unless $played->{$B} == $played->{$W};

	my $raw = raw($game);

	my $territory = ($raw->{territory_b} - $raw->{prisoners_w})
	              - ($raw->{territory_w} - $raw->{prisoners_b});
	my $area      = $raw->{area_b} - $raw->{area_w};

	return $territory == $area ? 1 : 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Scoring - Japanese territory, and the area score it is checked against

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $result = Game::Go::Scoring::score($game);
    say $result->stringify;             # "White wins by 6.5"

    Game::Go::Scoring::agree_under_equivalence($game);   # undef, 1 or 0

=head1 DESCRIPTION

Japanese territory scoring, Articles 8 and 10, in five steps:

    1. remove every chain agreed dead, adding each stone to the prisoners of
       the player who did NOT own it                              (10.1)
    2. flood-fill the empty regions of what is left
    3. a region reaching exactly one colour is that colour's eye points;
       a region reaching both is dame                             (8)
    4. territory is the eye points, less any region agreed seki   (8)
    5. black = territory(black) - prisoners held by WHITE
       white = territory(white) - prisoners held by BLACK + komi  (10.2)

B<Step 5 is subtraction from the opponent, not addition to yourself.> Article
10.2 fills each player's prisoners "into the opponent's territory". Adding your
own prisoners to your own score gives the same difference and a different pair
of numbers, and the pair is what a scoreboard prints and what an SGF record's
C<RE[]> encodes.

=head2 Where this scorer is knowingly incomplete

Article 8:

    Empty points surrounded by the live stones of just one player are called
    "eye points." Other empty points are called "dame." Stones which are alive
    but possess dame are said to be in "seki." Eye points surrounded by stones
    that are alive but NOT IN SEKI are called "territory," each eye point
    counting as one point of territory.

The British Go Association's comparison table makes it the row that separates
Japanese from every other ruleset on the page: "Can you count points in a seki?
Japanese, Korean: No. AGA, Chinese, SST (Ing), New Zealand: Yes."

A flood fill identifies dame correctly, because a region reaching both colours
is dame by definition. What it B<cannot> identify on its own is a one-point eye
inside a seki: it reaches one colour, it is not dame, and it is still not
territory, because the stones around it are in seki. Seeing that requires
knowing which groups are alive-with-dame, which is life and death again, and
this distribution has no solver.

B<So seki is agreed, not detected.> The confirmation phase lets the players mark
a region as seki, and a marked region scores nothing. A position where the
players do not mark it will be scored one or two points wrong in exactly that
shape, F<t/14-seki.t> asserts that wrong answer as documented behaviour, and the
escape hatch is Article 9.3: a player losing a point to it can send the game back
to the board and play the seki out, which is what a human referee would say.

=head1 FUNCTIONS

=head2 score

    Game::Go::Scoring::score($game, scored_by => 'territory')

A L<Game::Go::Result>.

=head2 score_by_area

    Game::Go::Scoring::score_by_area($game)

A L<Game::Go::Result> scored by Tromp's rule 9: "A player's score is the number
of points of her color, plus the number of empty points that reach only her
color."

B<It reads no marks>, and that is the whole reason it is what a disputed game
falls through to: it is a function of the position and of nothing else, so
nobody has to agree to anything for it to produce an answer. Komi still applies,
because it compensates for moving first and that is true under either ruleset.

=head2 raw

The scorer's own numbers, as a hashref, before they are dressed as a result.
Scores in it are in B<tenths>, because komi is fractional and the C engine has
no floats.

=head2 stones_played

How many stones each colour played over the whole game, from the log. Not the
same as the stones each has on the board; the difference is exactly the
prisoners, and that identity is what the next function rests on.

=head2 agree_under_equivalence

    undef   the condition does not hold
    1       it holds and the two scorers agree
    0       it holds and they DISAGREE

B<This is the differential test that a single implementation of everything else
would otherwise leave this distribution without.> There is no pure-Perl board to
compare the C against and no published ladder to check it with, but there are
two scorers over one position, and they must agree under a stated condition.

Wikipedia's "Rules of Go":

    If the game ends with both players having played the same number of stones,
    then the result will be identical in territory and area scoring.

The condition implemented is B<equal stones played, and no region agreed seki>,
which is derived in a comment in the source rather than taken on trust. Two
things that look as though they should matter do not: removing dead stones
preserves the identity, because a lifted stone moves from the board count into
the prisoner count on both sides of it; and unfilled dame preserves it, because
dame counts zero to both scorers. An agreed seki does break it, because territory
excludes a seki and area does not.

A 0 from this is a bug in one of the two scorers.

=head1 SEE ALSO

L<Game::Go>, L<Game::Go::Result>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
