package Game::Dominoes::Scoring;

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(count score_for bonus MAX_COUNT);

use constant MAX_COUNT => 35;

sub count {
	my ($layout) = @_;
	die 'Game::Dominoes::Scoring: count wants a layout' unless ref $layout;
	my $total = 0;
	for my $end ($layout->ends) {
		$total += ($end->{sole} || $end->{tile}->is_double)
			? $end->{tile}->pips
			: $end->{face};
	}
	return $total;
}

sub score_for {
	my ($total, $scale) = @_;
	return 0 unless defined $total && $total > 0;
	return 0 if $total % 5;
	$scale = 1 unless defined $scale && $scale > 0;
	return $total / $scale;
}

sub bonus {
	my ($pips, $scale) = @_;
	return 0 unless defined $pips && $pips > 0;
	my $rounded = int(($pips + 2) / 5) * 5;
	$scale = 1 unless defined $scale && $scale > 0;
	return $rounded / $scale;
}

1;

__END__

=head1 NAME

Game::Dominoes::Scoring - the open end total, what it scores, and the domino bonus

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Scoring qw(count score_for bonus);

	my $total = count($layout);      # 15
	score_for($total);               # 15, because it is a multiple of five
	score_for($total, 5);            # 3, on the cribbage board scale
	bonus(13);                       # 15, rounded to the nearest five

=head1 DESCRIPTION

All Fives scoring, pinned to Pagat's All Fives page and verified against it.

The contested part of All Fives is which ends count and when, and none of it is
decided here. L<Game::Dominoes::Layout> reports the ends that exist, and every
rule falls out of that list without a special case: a spinner with both sides
covered is not at an end, so it is not in the list, so it contributes nothing.

=head2 The Fives family differ by exactly this, so do not copy between them

Four games in this family share the scoring and differ only in how many
spinners are in play, and their rules are therefore B<not> interchangeable
however similar the prose looks:

=over

=item Muggins

No spinner at all. It also rounds each opponent's hand separately before
summing, where All Fives totals first and rounds once.

=item All Fives

One spinner, the first double played. This is what this distribution plays.

=item Sniff

One spinner, but B<the Sniff keeps counting while its ends are exposed>, where
an All Fives spinner stops the moment both its sides are covered. Pagat's Sniff
page works an example through to a total of 15 where All Fives would give 7,
and says plainly in the sentence before it that this is the difference between
the two games.

=item Five Up

Every double is a spinner, and scores are divided by five to a target of 61.

=back

Two apparent contradictions between sources dissolved when the pages were read
rather than summarised: Sniff's 15 and Muggins's per-hand rounding are both
correct statements about B<different games>. A summary that flattens the family
into "dominoes" manufactures disagreements that are not there, and then invites
somebody to fix an engine that was right.

=head1 FUNCTIONS

=head2 count

	my $total = count($layout);

The open end total. A double at an end counts both its halves; a single tile on
the table is one end and not two.

=head2 score_for

	score_for($total);        # the total, if it is a multiple of five
	score_for($total, 5);     # the same, divided, for a cribbage board

What that total scores. A multiple of five scores B<the total itself>, not the
total divided by five.

Zero never scores, although it is arithmetically a multiple of five. The
published list of opening tiles that score at once is 6-4, 5-5, 5-0, 4-1 and
3-2, and the absence of the double blank from it is the evidence.

C<$scale> divides the result, for the variation that keeps score on a cribbage
board to a target of 61. B<The scale and the target are a matched pair>: 61
with the raw scale, or 250 with a divided one, is the likeliest silent bug in
this area, which is why L<Game::Dominoes> carries both together and neither
alone.

=head2 bonus

	bonus(13);   # 15

The pips left in the other hands, rounded to the nearest multiple of five.

The pips are B<added up first and rounded once>. Rounding each opponent
separately and then summing is a different published rule and gives a different
answer at three and four seats: three opponents holding thirteen each give 40
this way and 45 the other. It is invisible in any two-seat test.

Rounding to the nearest five can never tie, so there is no tie-breaking policy
to choose here.

=head2 MAX_COUNT

	MAX_COUNT;   # 35

The highest total reachable in one play. Pagat gives the construction as well
as the number: the 6-6, 5-5 and 4-4 on three arms and a tile showing a five on
the fourth, so 12 + 10 + 8 + 5.

=head1 SEE ALSO

L<Game::Dominoes::Layout>, whose C<ends> this reads.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Scoring

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
