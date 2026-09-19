#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;
use Game::Oware::Scoring;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# THIS IS THE ONLY EXTERNAL VECTOR THIS DISTRIBUTION HAS. Everything else in the
# suite is either a rule derived by hand or an invariant over games this engine
# played. Here the position, the move AND the number come from somebody who was
# not writing this code.
#
# Source: https://en.wikipedia.org/wiki/Oware, revid 1368141850, fetched
# 17 Sep 2026 with
#
#     curl -s "https://en.wikipedia.org/w/index.php?title=Oware&action=raw"
#
# FETCHED AS WIKITEXT ON PURPOSE. The two boards are {{Mancala labeled 2x6}}
# templates, so a tag-stripped fetch of the rendered page keeps the captions and
# loses every number in them. An earlier draft of the plan for this phase
# concluded the diagram was an image and told this file to reconstruct a board
# out of the prose. It is not, and it does not.
#
# The wikitext, verbatim, with y marking the article's own highlighting:
#
#     {{Mancala labeled 2x6
#     |2|2|1|2|3|1
#     |3|1|4|0|6y|2
#     ''The lower player prepares to sow from '''E'''.''
#
#     {{Mancala labeled 2x6
#     |2|3y|2y|3y|4|2
#     |3|1 |4 |0 |0|3
#     ''After sowing, '''e''', '''d''', and '''c''' are captured but not '''a'''.''
#
# and the sentence the capture rule is checked against:
#
#     "the lower player would capture all the seeds in houses e, d, and c but
#      not b (as it has four seeds) or a (since it is not contiguous to the
#      other captured houses)."
#
# THE DIAGRAM HOLDS 27 SEEDS, NOT 48. Twenty-one have already been captured and
# the article does not say by whom, so the 11 and 10 below are OURS and are
# chosen only so the conservation invariant stays live in this file. Nothing
# asserted here depends on the split. Without them a correct engine fails a
# test it should pass, which is worth an hour to whoever meets it first.

my @TOP_BEFORE    = (2, 2, 1, 2, 3, 1);
my @BOTTOM_BEFORE = (3, 1, 4, 0, 6, 2);
my @TOP_AFTER     = (2, 3, 2, 3, 4, 2);
my @BOTTOM_AFTER  = (3, 1, 4, 0, 0, 3);

# The article's rows read f e d c b a across the top and A to F across the
# bottom, so the top row reverses into indices 6 to 11. Done here rather than
# through Game::Oware::Notation so that a fault in the notation cannot make this
# file pass or fail for the wrong reason.
sub board_of {
	my ($top, $bottom, $p1_store, $p2_store) = @_;
	return [ @$bottom, reverse(@$top), $p1_store, $p2_store ];
}

my $BEFORE = board_of(\@TOP_BEFORE, \@BOTTOM_BEFORE, 11, 10);
my $AFTER  = board_of(\@TOP_AFTER,  \@BOTTOM_AFTER,  11, 10);

subtest 'the transcription, before the rule' => sub {
	my $on_board = 0;
	$on_board += $_ for (@TOP_BEFORE, @BOTTOM_BEFORE);
	is($on_board, 27, 'the article draws twenty-seven seeds, not forty-eight');

	my $after = 0;
	$after += $_ for (@TOP_AFTER, @BOTTOM_AFTER);
	is($after, 27, 'and the same twenty-seven afterwards, since nothing is removed yet');

	is(Game::Oware::Board->total($BEFORE), 48, 'our store split makes it forty-eight');
	is($BEFORE->[4], 6, 'E holds six seeds, which is what the highlight means');
};

subtest 'the sowing reaches exactly the houses the article draws' => sub {
	my ($next, $last, $sown) = Game::Oware::Board->sow($BEFORE, 4);

	is($sown, 6, 'six seeds left E');
	is($last, 10, 'and the sixth landed in e');
	is_deeply($next, $AFTER, "the whole board matches the article's second diagram");
	is($next->[11], 2, 'f was never reached, so it did not change');
};

subtest 'the capture is eight seeds, from e, d and c' => sub {
	my @chain = Game::Oware::Board->capture_chain($AFTER, 10, 6, 'p1');

	is_deeply(\@chain, [ 10, 9, 8 ], 'e, d and c, in walk-back order');
	is(Game::Oware::Scoring->taken($AFTER, \@chain), 8, 'which is eight seeds');

	is($AFTER->[7], 4, 'b is not captured, as it has four seeds');
	is($AFTER->[6], 2,
		'and a is not captured, since it is not contiguous to the other captured houses');

	is(Game::Oware::Board->total($AFTER), 48, 'and the chain did not move anything');
};

# THE NEGATIVE CONTROLS.
#
# Each is a whole alternative implementation, written out here rather than
# asserted as a number, so that it is the DIFFERENCE being tested and not a
# constant somebody could quietly update. A control that agrees with the
# published answer is not a control.
subtest 'the two implementations this rule is most often written as' => sub {

	# Scan every house the hand touched, take the opponent's ones at two or
	# three, and never look at whether they form a run. This is the obvious
	# implementation and it is the one the article's last clause exists to
	# rule out.
	my @touched = (5, 6, 7, 8, 9, 10);
	my $blind = 0;
	for my $house (@touched) {
		next unless Game::Oware::Board->owner_of($house) eq 'p2';
		my $count = $AFTER->[$house];
		$blind += $count if $count == 2 || $count == 3;
	}
	is($blind, 10, 'a contiguity-blind scan takes ten, adding a');
	isnt($blind, 8, 'which is not what the article says');

	# The same walk, stepping the other way. It leaves the houses the hand
	# reached and takes f, which this move never sowed into at all.
	my @forwards;
	my $i = 10;
	while (@forwards < 6) {
		last unless Game::Oware::Board->owner_of($i) eq 'p2';
		my $count = $AFTER->[$i];
		last unless $count == 2 || $count == 3;
		push @forwards, $i;
		$i = ($i + 1) % 12;
	}
	is_deeply(\@forwards, [ 10, 11 ], 'a forwards walk takes e and then f');
	is(Game::Oware::Scoring->taken($AFTER, \@forwards), 5, 'which is five seeds');
	isnt(Game::Oware::Scoring->taken($AFTER, \@forwards), 8, 'and is not the published eight');
	is($BEFORE->[11], $AFTER->[11],
		'and f was never sown into, so no correct rule can take it');
};

# The third implementation this engine guards against cannot be reached from
# this position, and saying so is better than inventing a number for it.
#
# The Kalah ring - stepping the fourteen-cell array instead of the twelve-house
# ring, so that seeds fall into the stores - only diverges when a sow crosses
# the boundary between house 11 and store 12. Six seeds leaving house 4 stop at
# house 10 and never get near it, so on this position the wrong ring gives the
# right answer.
#
# It is guarded in t/01-board.t instead, where breaking it deliberately fails 22
# of 98 assertions. An earlier draft of the plan for this phase claimed this
# file could show it taking five seeds; five is the forwards walk above, and the
# two were confused.
subtest 'the ring cannot be tested from here, and here is why' => sub {
	my @touched_by_the_wrong_ring;
	my $i = 4;
	for (1 .. 6) {
		$i = ($i + 1) % 14;
		push @touched_by_the_wrong_ring, $i;
	}

	is_deeply(\@touched_by_the_wrong_ring, [ 5, 6, 7, 8, 9, 10 ],
		'a fourteen-wide ring touches the same six houses from here');
	ok(!grep({ $_ >= 12 } @touched_by_the_wrong_ring),
		'because it never reaches a store, so this position cannot tell them apart');
};

done_testing;
