package Game::Dominoes::Rules;

use strict;
use warnings;

use Exporter 'import';

use Game::Dominoes::Scoring ();

our $VERSION = '0.01';
our @EXPORT_OK = qw(candidates can_play best_arm);

sub candidates {
	my ($layout, $hand) = @_;
	die 'Game::Dominoes::Rules: candidates wants a layout and a hand'
		unless ref $layout && ref $hand;

	my @arms = $layout->arms_open;
	my @out;

	if ($layout->is_empty) {
		push @out, { tile => $_, arm => $arms[0] } for @{ $hand->sorted };
		return \@out;
	}

	for my $tile (@{ $hand->sorted }) {
		for my $arm (@arms) {
			next unless $layout->can_place($tile, $arm);
			push @out, { tile => $tile, arm => $arm };
		}
	}
	return \@out;
}

sub can_play {
	my ($layout, $hand) = @_;
	return scalar @{ candidates($layout, $hand) } ? 1 : 0;
}

sub score_of {
	my ($layout, $tile, $arm, $scale) = @_;
	my $trial = $layout->clone;
	$trial->place($tile, $arm);
	return Game::Dominoes::Scoring::score_for(
		Game::Dominoes::Scoring::count($trial), $scale
	);
}

1;

__END__

=head1 NAME

Game::Dominoes::Rules - which plays are legal, and what they would score

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Rules qw(candidates can_play);

	my $moves = Game::Dominoes::Rules::candidates($layout, $hand);
	# [ { tile => $tile, arm => 'L' }, ... ]

	Game::Dominoes::Rules::can_play($layout, $hand);   # 1 or 0

	Game::Dominoes::Rules::score_of($layout, $tile, 'L');   # what it would score

=head1 DESCRIPTION

Move generation, as functions rather than a class, because the bot calls this
far more often than anything else here.

It is deliberately B<not> the raw unblessed array interface that
L<Game::Checkers::Rules> uses. That shape exists there because alpha-beta over
a checkers position visits millions of nodes and allocating an object per move
was measurable. Whether dominoes needs the same depends on how the determinised
search behaves, and writing the awkward version before anything has been
measured would be guessing at a cost nobody has paid yet.

=head1 FUNCTIONS

=head2 candidates

	my $moves = candidates($layout, $hand);

Every legal tile and arm pairing, as an arrayref of
C<< { tile => ..., arm => ... } >>.

The order is stable: the hand in canonical tile order, then the arms L, R, U,
D. A bot that takes the first of several equal moves therefore takes the same
one on every machine and every perl, which is what makes a game replayable.

On an empty table every tile is a candidate, because the opening lead may be
any tile.

=head2 can_play

	can_play($layout, $hand);

Whether the hand has any legal play at all. This is the question that decides
whether a turn is a decision or a forced draw.

=head2 score_of

	score_of($layout, $tile, 'L');
	score_of($layout, $tile, 'L', 5);   # on the divided scale

What a play would score, without committing to it.

It works on a copy of the layout. Placing and then unplacing would be faster
and would have to undo the spinner bookkeeping, and an undo that is subtly
wrong produces a bug that surfaces several plays later in a different part of
the table.

=head1 SEE ALSO

L<Game::Dominoes::Layout>, L<Game::Dominoes::Scoring>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Rules

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
