package Game::Oware::Variant;

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(variants is_variant check_variant spec_for fields
                    grand_slam target draw_at
                    repetition_limit plies_without_capture);

my %SPEC = (
	abapa => {
		grand_slam            => 'no_capture',
		target                => 25,
		draw_at               => 24,
		repetition_limit      => 3,
		plies_without_capture => 500,
	},
	awari => {
		grand_slam            => 'illegal_unless_only',
		target                => 25,
		draw_at               => 24,
		repetition_limit      => 3,
		plies_without_capture => 500,
	},
);

my @FIELDS = sort keys %{ $SPEC{abapa} };

sub variants { return sort keys %SPEC }

sub fields { return @FIELDS }

sub is_variant { return exists $SPEC{ $_[0] // '' } ? 1 : 0 }

sub check_variant {
	my ($variant) = @_;
	die "Game::Oware::Variant: there is no variant '"
		. (defined $variant ? $variant : 'undef') . "'"
		unless is_variant($variant);
	return $variant;
}

sub spec_for {
	my ($variant) = @_;
	check_variant($variant);
	return { %{ $SPEC{$variant} } };
}

for my $field (@FIELDS) {
	no strict 'refs';
	*{ __PACKAGE__ . '::' . $field } = sub {
		my ($variant) = @_;
		check_variant($variant);
		return $SPEC{$variant}{$field};
	};
}

1;

__END__

=head1 NAME

Game::Oware::Variant - the rule table, and what varies between rule sets

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Variant qw(grand_slam target);

    grand_slam('abapa');       # no_capture
    grand_slam('awari');       # illegal_unless_only
    target('abapa');           # 25

=head1 DESCRIPTION

A table of named rule flags with one accessor per field, in the shape of
L<Game::Schnapsen::Variant>. Not subclasses: two rule sets that differ in five
scalars do not need two class hierarchies, and a spec table is the only form in
which the difference can be read at a glance.

=head2 abapa is the default, and the only one a player will meet

The rules in the Wikipedia article's own body, "considered to be the most
appropriate for serious, adult play". Everything else here exists for the test
suite.

=head2 grand_slam names the policy, and the two shipped are not both Wikipedia's

A grand slam is a move whose capture chain would take every seed the opponent
has. Wikipedia lists four readings of it. This distribution implements two
policies, and B<only one of them is on that list>:

=over

=item C<no_capture>

The move is legal and captures nothing. Shipped as C<abapa>, because it is what
the article's own rules body already describes - "the capture is forfeited ...
and the seeds are instead left on the board" - and because the Variations
section says international competitions follow it. This is Wikipedia's
variation 2.

=item C<illegal_unless_only>

The move is not legal at all, B<unless it is the only move available>, in which
case it is played and captures normally. Shipped as C<awari>, and this is the
rule set Romein and Bal solved.

=back

=head2 Where the awari rule set comes from, and why it is not what Wikipedia says

C<awari> exists for one reason: the Awari Game Score Database published by the
Vrije Universiteit (DOI 10.48338/vu01-11wjke, CC-BY 4.0) is an exact
per-position oracle, and it is an oracle for the rule set they solved rather
than for the one the site plays.

B<Wikipedia is not a source for that rule set.> It describes it only as
"variations allowing Grand slams to end the game", a phrase matching none of its
own four numbered variations, and taking it at face value would have shipped
"the capture is made and the rest of the board goes to the opponent", which is
its variation 3 and is B<wrong>.

The rule is pinned instead from the dataset's own F<Awari-Python/README.md>,
fetched 18 September 2026, which says of the scores it returns:

    The score printed is the score of the current board interpreted
    according to the special rules regarding which moves are acceptable.
    Specifically, it is not allowed to remove all stones of the opponent
    (leaving it no move), unless it is the only move available.

Note what that single sentence does: it is Wikipedia's variation 1 with an
exception clause, and B<it subsumes the feeding rule>. "Leaving the opponent no
move" covers both capturing all their seeds and failing to give seeds to an
opponent who has none, so C<awari> needs one rule where C<abapa> needs two. The
exception clause is what keeps a position with no other option playable.

The dataset pins nothing else. Its F<README.md>, its description and its
F<Board.py> cover sowing, capture and Goedel indexing only; F<Board.py> has no
move generation at all. So the cycle rule and the treatment of a position where
neither side can move are B<still unpinned>, and the other four fields here are
copied from C<abapa>. An oracle test has to keep away from positions where that
matters, and F<xt/awari-oracle.t> says so.

=head2 plies_without_capture is measured, and it is a backstop rather than the rule

Five hundred. It is a house rule with no published number behind it, so the
value is measured rather than chosen, and F<xt/cycle-measure.t> is the
measurement.

Over three hundred bot games at mixed levels, B<with the cap lifted so the
sample is not truncated by the thing it is meant to justify>, the longest
capture-free stretch was B<396> plies, the 95th percentile was 124 and the
median was 19. Five hundred is above the observed maximum with margin, and well
inside the scale of a game, so it ends a game that has genuinely stopped
progressing and never one that was still going somewhere.

The development placeholder was fifty, which the same measurement shows would
have fired in well over a third of ordinary games.

B<At five hundred this trigger is the outer bound and repetition is what
actually ends cyclic games>: in that sample, threefold repetition ended 24 games
of 300 and the ply cap ended none. That is the division of labour D2 described,
and an earlier reading of the evidence had it backwards because it was drawn
from games played by a first-legal-move policy rather than by a bot.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 variants

Every variant name, sorted.

=head2 fields

Every field name, sorted. The two specs carry the same keys, and this is what
proves it.

=head2 is_variant

True for a known variant name.

=head2 check_variant

Returns its argument, or dies. An unknown variant is programmer error.

=head2 spec_for

A copy of one variant's whole table, so a caller cannot edit the original.

=head2 grand_slam

C<no_capture> or C<illegal_unless_only>.

=head2 target

The seeds that win a game. Twenty-five.

=head2 draw_at

The seeds each that draw one. Twenty-four.

=head2 repetition_limit

How many times a position may occur before the cycle rule ends the game.

=head2 plies_without_capture

How many plies may pass with no seed entering a store before the cycle rule
ends the game. Five hundred, measured rather than chosen; see above.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Rules>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
