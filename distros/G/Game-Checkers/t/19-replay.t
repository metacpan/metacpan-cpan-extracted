#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Notation;

# The fixtures are REGRESSION fixtures: this distribution's own bot played them,
# so they say that a recorded game still replays to the same position, and
# nothing about whether the rules are right. The rules are checked by hand in
# t/04 to t/11 and the generator against a published table in t/20-perft.t.
# t/fixtures/regen.pl writes them again, deliberately.
my %EXPECT = (
	'level-3.pdn' => {
		ply => 126,
		result => '1-0',
		reason => 'no_moves',
		fen => 'B:WK14,K27:B',
	},
	'level-4.pdn' => {
		ply => 123,
		result => '1/2-1/2',
		reason => 'repetition',
		fen => 'W:WK1:BK10',
	},
);

my @fixture = glob 't/fixtures/*.pdn';
plan skip_all => 'no fixtures here, so this is not the distribution root'
	unless @fixture;

plan tests => scalar @fixture;

for my $path (@fixture) {
	my ($name) = $path =~ m{([^/]+)$};
	subtest $name => sub {
		plan tests => 6;
		my $expect = $EXPECT{$name} or die "no expectation recorded for $name";

		open my $handle, '<', $path or die "cannot read $path: $!";
		my $pdn = do { local $/; <$handle> };
		close $handle;

		my $game = Game::Checkers->from_pdn($pdn);
		is $game->ply, $expect->{ply}, 'every move replayed';
		is $game->status, 'finished', 'and the game ended';
		is $game->result->pdn, $expect->{result}, 'with the recorded result';
		is $game->result->reason, $expect->{reason}, 'for the recorded reason';
		is $game->to_fen, $expect->{fen}, 'reaching the recorded position';

		# writing it back out must be the same bytes, so a change to the
		# notation cannot pass as "the tests still replay it"
		my $tags = Game::Checkers::Notation::parse_pdn($pdn)->{tags};
		is $game->to_pdn(%{$tags}), $pdn, 'and it writes out byte for byte';
	};
}
