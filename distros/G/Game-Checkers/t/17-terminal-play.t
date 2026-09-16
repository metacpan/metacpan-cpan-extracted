#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

use Game::Checkers;
use Game::Checkers::Bot;
use Game::Checkers::Terminal;

# the whole game is driven in process: two in memory handles, no pipe, no
# process, and no terminal
sub drive {
	my ($script, %option) = @_;
	my $input = join '', map { "$_\n" } @{$script};
	open my $in, '<', \$input or die "in memory handle: $!";
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";

	my $terminal = Game::Checkers::Terminal->new(
		in => $in,
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		%option
	);
	my $result = $terminal->start;
	return ($terminal, $output, $result);
}

subtest 'a game against the bot' => sub {
	plan tests => 4;
	# after the opening move the replies are taken by number, because a bot move
	# can force a capture and a scripted notation would then be refused
	my ($terminal, $output, $result) = drive(
		[qw/f6-e5 1 1 1 resign/],
		bot => Game::Checkers::Bot->new(level => 1, seed => 3),
		human => 'black'
	);
	is $terminal->game->ply, 8, 'four moves each, then the resignation';
	is $result->winner, 'white', 'which White wins';
	like $output, qr/White wins: Black resigned/, 'and the board says so';
	like $output, qr/plays/, 'the bot announced its moves';
};

subtest 'hotseat, and what the prompt says' => sub {
	plan tests => 3;
	my ($terminal, $output) = drive([qw/f6-e5 c3-d4 e5xc3 quit y/], human => 'both');
	is $terminal->game->ply, 3, 'both sides played from the one keyboard';
	like $output, qr/black> /, 'the prompt names the side to move';
	like $output, qr/white> /, 'both of them';
};

subtest 'an illegal move is answered, not fatal' => sub {
	plan tests => 6;
	# f6-d4 is neither a step nor a jump from f6, a3 is White's, wibble is not
	# notation at all, h4 is not a square anybody plays on, and b6-a5 is a move
	my ($terminal, $output) = drive(
		['f6-d4', 'a3-b4', 'wibble', 'g4-h5', 'b6-a5', 'quit', 'y'],
		human => 'both'
	);
	is $terminal->game->ply, 1, 'only the legal move was played';
	like $output, qr/That is not a legal move/, 'the slide that is not a move';
	like $output, qr/You have no piece on that square/, q|and the other side's man|;
	like $output, qr/That is not a move/, 'and the word that is not either';
	is scalar(() = $output =~ m/That is not a move/g), 2,
		'nor is a square the game is never played on';
	like $output, qr/Type moves for the list/, 'with a way out of it';
};

subtest 'moves, hint and a move by its number' => sub {
	plan tests => 4;
	my ($terminal, $output) = drive(['moves', 'hint', '5', 'quit', 'y'], human => 'both');
	like $output, qr/ 1\. b6-a5/, 'the list is numbered in the engine order';
	like $output, qr/ 7\. h6-g5/, 'all seven of them';
	like $output, qr/Try \S+ \(it scores that [-+]/, 'the hint names a move and a score';
	is $terminal->game->history->[0]->coord_notation, 'f6-e5',
		'and the fifth move on the list is the fifth move on the list';
};

subtest 'the board is only drawn again when it changes' => sub {
	plan tests => 3;
	# the complaint this is here for: the list, or the refusal, scrolled off the
	# screen under a board that was exactly the board already on it
	my ($terminal, $output) = drive(
		['moves', 'f6-d4', 'quit', 'y'],
		human => 'both'
	);
	my @board = $output =~ m/^ 8 /mg;
	is scalar @board, 1, 'one board for the opening position';
	like $output, qr/ 7\. h6-g5\nPlay one by its number[^\n]*\nblack> /,
		'the list is still there under the prompt';
	like $output, qr/That is not a legal move[^\n]*\nYou could play[^\n]*\nblack> /,
		'and so is the refusal';
};

subtest 'undo takes back the reply too' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new;
	my ($terminal, $output) = drive(
		['11-15', 'undo', 'quit'],
		game => $game,
		bot => Game::Checkers::Bot->new(level => 1, seed => 5),
		human => 'black'
	);
	is $terminal->game->ply, 0, 'the move and the answer to it are both gone';
	is $terminal->game->to_fen, Game::Checkers->new->to_fen, 'the opening is back';
	like $output, qr/Taken back/, 'and it said so';
};

subtest 'save and load' => sub {
	plan tests => 4;
	my $directory = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($directory, 'game.pdn');

	my ($saved, $output) = drive(
		['11-15', '22-18', "save $file", 'quit', 'y'],
		human => 'both'
	);
	like $output, qr/Saved to/, 'the game was written out';
	ok -s $file, 'and the file has something in it';

	my ($loaded, $second) = drive(["load $file", 'quit', 'y'], human => 'both');
	is $loaded->game->ply, 2, 'the moves came back';
	is $loaded->game->to_fen, $saved->game->to_fen, 'and so did the position';
};

subtest 'the switches' => sub {
	plan tests => 4;
	my ($terminal, $output) = drive(
		['level 2', 'flip', 'ascii', 'fen', 'quit'],
		bot => Game::Checkers::Bot->new(level => 1),
		human => 'black',
		# the handle carries the UTF-8 layer, so the symbols can be switched off
		# part way through without the wide board that came first being a warning
		ascii => 0
	);
	is $terminal->bot->level, 2, 'the level was set';
	ok $terminal->flip, 'the board was flipped';
	ok $terminal->ascii, 'and the symbols swapped for letters';
	like $output, qr/FEN: B:W21/, 'the FEN was printed';
};

subtest 'end of file is a clean quit' => sub {
	plan tests => 2;
	my ($terminal, $output, $result) = drive(['11-15'], human => 'both');
	is $terminal->game->ply, 1, 'what was typed was played';
	like $output, qr/Bye\./, 'and then the input ran out, which is not an error';
};

subtest 'a game that ends on the board' => sub {
	plan tests => 2;
	# black takes the last white man and White has nothing to move
	my ($terminal, $output, $result) = drive(
		['11x18'],
		game => Game::Checkers->new(fen => 'B:W15:B11'),
		human => 'both'
	);
	is $result->reason, 'no_moves', 'the game ended itself';
	like $output, qr/Black wins: White has no move/, 'and printed the result';
};

done_testing;
