#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Test::Screen qw/terminal/;

# The games in t/fixtures were played by this distribution's own bot and
# written by t/fixtures/regen.pl. They are regression fixtures: they hold
# today's engine to yesterday's games, and say nothing about whether the
# rules are right. Each file ends with three notes, written when the game was
# played: the result, the final position, and the number of plies.

my @files = sort glob 't/fixtures/*.txt';

plan skip_all => 'the fixtures are not here, so this is not the distribution root'
	unless @files;

is(scalar @files, 4, 'four recorded games');

for my $file (@files) {
	subtest $file => sub {
		open my $handle, '<', $file or die "cannot read $file: $!";
		my $text = do { local $/; <$handle> };
		close $handle;

		my ($result, $position, $plies) = $text =~ m/^# (.*)\n# (.*)\n# (\d+)\n\z/m
			or return fail('the file does not end with its three notes');
		(my $moves = $text) =~ s/^#.*\n//mg;

		my $game = eval { Game::Merrills->from_text($text) };
		ok($game, 'it replays') or return diag $@;
		is($game->status, 'finished', 'to the end');
		is($game->result->stringify, $result, "with the result it had: $result");
		is($game->to_position, $position, 'at the position it ended on');
		is($game->ply, $plies, "after $plies plies");
		is($game->to_text, $moves, 'and written out again it is the file, byte for byte, less the notes');
		cmp_ok(scalar(grep { $_->is_capture } @{ $game->history }), '>=', 3, 'a whole game, men taken and all');
	};
}

subtest 'a record with one move changed is refused, by the number of the move' => sub {
	open my $handle, '<', 't/fixtures/level-1.txt' or die $!;
	my $text = do { local $/; <$handle> };
	close $handle;

	my @moves = map { Game::Merrills::Notation::format_move($_) }
		@{ Game::Merrills::Notation::parse_record($text) };
	my $at = 20;
	my $was = $moves[$at];
	$moves[$at] = $moves[ $at - 2 ];
	my $changed = Game::Merrills::Notation::format_record(\@moves);
	isnt($moves[$at], $was, "move 21 changed from $was to $moves[$at]");
	my $died = eval { Game::Merrills->from_text($changed); 1 } ? '' : $@;
	like($died, qr/^illegal record: move 21, '\Q$moves[$at]\E': /, 'and the replay stops there, saying which and why');
};

subtest 'the terminal shows a record a move at a time' => sub {
	open my $handle, '<', 't/fixtures/from-a-position.txt' or die $!;
	my $text = do { local $/; <$handle> };
	close $handle;
	my $game = Game::Merrills->from_text($text);
	my $moves = scalar @{ $game->history };

	my ($terminal, $screen) = terminal('');
	my $result = $terminal->replay($text);
	is($result->stringify, $game->result->stringify, 'replay hands back the result');
	is(scalar(() = $$screen =~ m/^7 [ (\[{<]/mg), $moves + 1, 'a board before the first move and one after each');
	is(scalar(() = $$screen =~ m/^(?:White|Black) (?:placed|moved|flew) .*\.$/mg) >= $moves ? 1 : 0, 1,
		'with every move said in words');
	is($terminal->game->to_position, $game->to_position, 'and the game shown is left as the terminal\'s game');
	is($terminal->game->position, $game->position, 'begun from the position the record names');

	my ($broken) = terminal('');
	my $died = eval { $broken->replay("1. d2 d2\n"); 1 } ? '' : $@;
	is($died, "illegal record: move 2, 'd2': that point is not empty\n", 'a record that does not play dies, naming the move');
};

done_testing;
