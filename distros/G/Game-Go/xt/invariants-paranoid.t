#!perl

# THE SINGLE MOST VALUABLE TEST IN THE DISTRIBUTION, and far too slow to
# install.
#
# t/12-invariants.t checks every tenth position of one short game. This checks
# EVERY position of every move of a thousand playouts, on all three board sizes,
# and it exists because of decision four.
#
# An incremental counter that drifts is the class of bug an XS-only dist has no
# defence against. There is no second implementation to disagree with it. The
# board stays plausible. Every legality test passes. The only symptom is a bot
# that plays slightly badly for reasons nothing reports, and the only way to
# catch it is to recompute the maintained structures from scratch often enough
# to hit the position that broke them.
#
# It emits ONE assertion per game rather than seven per move, because a hundred
# thousand ok lines is not a test result a person can read. The complaint that
# comes back names the move and what disagreed.

use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../t/lib";
use Test::More;
use Digest::SHA ();

plan skip_all => 'RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

use Game::Go;
use Game::Go::Rules;
use Invariants;

# Small by default so a release run is minutes and not an afternoon. The full
# thousand is GO_PARANOID_GAMES=1000, which is what to run after touching the
# chain maintenance, the capture path or the hash.
#
# MEASURED 18 SEP 2026: 10 games per size is 10,979 positions in 122 seconds,
# so the default of 40 is around eight minutes and a thousand is most of a day.
# The cost is the Perl audit, which is O(points) per move, and it is the price
# of the checker being written in the other language.
my $GAMES = $ENV{GO_PARANOID_GAMES} || 40;
my @SIZES = split /,/, ($ENV{GO_PARANOID_SIZES} || '9,13,19');

my $total_positions = 0;
my $total_moves = 0;

for my $size (@SIZES) {
	subtest "${size}x$size, $GAMES games, every position" => sub {
		my $bad = 0;

		for my $g (1 .. $GAMES) {
			my $game = Game::Go->new(size => $size, seed => "paranoid-$size-$g");
			my $n = 0;
			my @found;

			# The guard scales with the board: a 19x19 game needs about 850
			# actions and a fixed number reports a finished game unfinished.
			my $cap = 4 * $size * $size;

			while ($game->status eq 'active' && $game->phase eq 'play' && $n < $cap) {
				my $colour = $game->turn;
				my @plays = grep { $_->kind eq 'play' } @{ $game->legal($colour) };
				last unless @plays;

				my $word = unpack 'N', Digest::SHA::sha256("paranoid:$size:$g:$n");
				$game->play($colour, $plays[ $word % scalar @plays ]->point);
				$n++;

				# AFTER EVERY SINGLE MOVE. This is the whole point of the file.
				my @complaints = Invariants::complaints(Invariants::audit($game->board));
				push @found, "game $g move $n: $_" for @complaints;
				last if @found;

				$total_positions++;
			}

			$total_moves += $n;
			if (@found) {
				$bad++;
				diag($_) for @found;
				diag("the position:\n" . $game->board->to_text);
			}
		}

		is($bad, 0, "$GAMES games, no position where the engine and Perl disagree");
		done_testing();
	};
}

diag("$total_positions positions audited over $total_moves moves");
done_testing();
