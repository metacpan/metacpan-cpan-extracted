#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use File::Temp ();
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Test::Position qw/p position_of/;
use Game::Merrills::Test::Screen qw/terminal typed/;

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

sub boards { return scalar(() = $_[0] =~ m/^7 [ (\[{]/mg) }

subtest 'two people at one keyboard, typing moves' => sub {
	my ($terminal, $screen) = typed("d2\nf4\nd6\n", human => 'both');
	like($screen, qr/\ANine Men's Morris\. Type help for the commands\.\n/, 'it says what it is');
	is($terminal->game->to_text, "1. d2 f4\n2. d6\n", 'three moves were played');
	is(boards($screen), 4, 'the board was drawn at the start and after each');
	like($screen, qr/^white> d2$/m, 'each prompt names the side, and off a terminal what was typed is echoed');
	like($screen, qr/^black> f4$/m, 'for black as for white');
	like($screen, qr/^White placed a man on d2\.$/m, 'each move is said in words');
	like($screen, qr/Bye\.\n\z/, 'and the end of the input ends the game politely');
	is($terminal->game->status, 'active', 'leaving the game unfinished');
};

subtest 'a refused move says why, offers what could be played, and draws nothing' => sub {
	my ($terminal, $screen) = typed("d2\nd2\nnonsense\nd2-d3\n", human => 'both');
	is($terminal->game->ply, 1, 'only the first move was played');
	is(boards($screen), 2, 'the board is not drawn again after a refusal, so the reason stays on screen');
	like($screen, qr/^That point is not empty\.$/m, 'an occupied point');
	like($screen, qr/^You could play: a7, d7, g7, b6, d6, f6, c5, d5, e5, a4, b4, c4, and 11 more\.$/m,
		'with a list of what could be, cut to a dozen of the twenty-three');
	like($screen, qr/^That is not a move\.\nType moves for the list, or help for the commands\.$/m,
		'nonsense gets pointed at the help instead of a list');
	like($screen, qr/^You still have men to place, so place one\.$/m, 'moving a man while placing');
};

subtest 'the commands that only show something' => sub {
	my ($terminal, $screen) = typed("help\n?\nmoves\nposition\nboard\n\n   \n", human => 'both');
	is($terminal->game->ply, 0, 'none of them played a move');
	is(scalar(() = $screen =~ m/^A move is its points/mg), 2, 'help and ? both print the help');
	for my $command (sort keys %Game::Merrills::Terminal::COMMAND) {
		like($screen, qr/^  \Q$command\E\s+\S/m, "the help lists $command");
	}
	like($screen, qr/^ 1\. a7 +2\. d7 +3\. g7 +4\. b6 +5\. d6$/m, 'moves lists them five to a line, numbered');
	like($screen, qr/^21\. f2 +22\. a1 +23\. d1 +24\. g1$/m, 'all twenty-four');
	like($screen, qr/^Play one by its number, or type it out\.$/m, 'and says how to use the list');
	like($screen, qr/^\.{24} w 9 9 0 0$/m, 'position prints the position');
	is(boards($screen), 2, 'board draws it again, and an empty line does nothing');
	is(scalar(grep { m/[ \t]$/ && !m/^(?:white|black)> *$/ } split /\n/, $screen), 0,
		'and no line of the whole session ends in a space, bar a prompt nothing was typed at');
};

subtest 'a move by its number' => sub {
	my ($terminal, $screen) = typed("5\n1\n99\n0\n", human => 'both');
	is($terminal->game->to_text, "1. d6 a7\n", 'move 5 then move 1 of the list as it then stood');
	like($screen, qr/^There is no move 99\. Type moves for the list\.$/m, 'a number off the end is refused');
	like($screen, qr/^There is no move 0\./m, 'and so is nought');
};

subtest 'a hint' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3 e3/], black => [qw/b2 d2 e5/],
	));
	my ($terminal, $screen) = typed("hint\n", human => 'both', game => $game);
	like($screen, qr/^Try g4-g7x[a-g][1-7] \(it scores that \+\d+\.\d\d\)\.$/m, 'names a move and what it is worth');
	is($game->ply, 0, 'and plays nothing');

	my $over = Game::Merrills->new;
	$over->resign;
	my ($done) = terminal('', game => $over);
	is($done->hint->{line}, 'There is nothing to play.', 'in a finished game there is nothing to suggest');
};

subtest 'undo' => sub {
	my ($terminal, $screen) = typed("undo\nd2\nf4\nundo\n", human => 'both');
	like($screen, qr/^There is nothing to take back\.$/m, 'with no move played there is nothing to take back');
	is($terminal->game->to_text, "1. d2\n", 'two people: undo takes back one move');
	like($screen, qr/Taken back\.\n(?:.*\n)?Bye\.\n\z/, 'and says so after the board, where it will be read');
	unlike((split /Taken back/, $screen)[0] =~ s/.*^7  //msr, qr/placed a man/,
		'the board drawn for the undo no longer tells the story of the move undone');

	my ($with_bot) = typed("d2\nundo\n", human => 'white', bot => Game::Merrills::Bot->new(level => 1));
	is($with_bot->game->ply, 0, 'against a bot: undo takes back your move and the reply');
	is($with_bot->game->turn, 'white', 'so it is your turn again');
};

subtest 'save and load' => sub {
	my $dir = File::Temp->newdir;
	my $file = "$dir/game.txt";
	my ($saver, $saved) = typed("d2\nf4\nd6\nsave $file\nsave\n", human => 'both');
	like($saved, qr/^Saved to \Q$file\E\.$/m, 'save says where');
	like($saved, qr/^Save needs a file name\.$/m, 'and needs a name');
	ok(-s $file, 'the file is there');

	my ($loader, $loaded) = typed("load $file\nb4\nload\nload $dir/none.txt\n", human => 'both');
	like($loaded, qr/^Loaded \Q$file\E, 3 moves in\.$/m, 'load says how far in the game is');
	is($loader->game->to_text, "1. d2 f4\n2. d6 b4\n", 'and play carries on from there');
	like($loaded, qr/^Load needs a file name\.$/m, 'load needs a name too');
	like($loaded, qr/^Cannot read \Q$dir\E\/none\.txt: /m, 'and a file that is there');

	open my $handle, '>', $file or die $!;
	print {$handle} "1. d2 d2\n";
	close $handle;
	my ($bad, $refused) = typed("load $file\n", human => 'both');
	like($refused, qr/^That is not a game I can read: illegal record: move 2, 'd2': that point is not empty$/m,
		'a file that is not a game is refused, with the reason on one line');
	is($bad->game->ply, 0, 'and the game in hand is kept');

	my ($unwritable, $said) = typed("save $dir/no/such/dir.txt\n", human => 'both');
	like($said, qr/^Cannot write /m, 'a file that cannot be written says so');
};

subtest 'the level of the bot' => sub {
	my ($terminal, $screen) = typed("level 2\nlevel\nlevel 9\n", human => 'white',
		bot => Game::Merrills::Bot->new(level => 1, seed => 5));
	is($terminal->bot->level, 2, 'level 2 gives a level 2 bot');
	is($terminal->bot->seed, 5, 'with the seed of the old one');
	like($screen, qr/^The bot is at level 2\.$/m, 'and says so');
	is(scalar(() = $screen =~ m/^Level takes a number from 1 to 5\.$/mg), 2, 'no number, or a wrong one, is refused');

	my ($pair) = typed("level 3\n", human => 'none', game => do { my $g = Game::Merrills->new; $g->resign; $g },
		bot => { white => Game::Merrills::Bot->new(level => 1), black => Game::Merrills::Bot->new(level => 1) });
	is_deeply([ map { $pair->bot->{$_}->level } qw/white black/ ], [ 1, 1 ],
		'a finished game reads no commands, so nothing changed');
};

subtest 'a draw between two people' => sub {
	my ($terminal, $screen) = typed("accept\ndraw\ndecline\nd2\ndraw\naccept\nd6\n", human => 'both');
	like($screen, qr/^There is no draw to answer\.$/m, 'accepting what was not offered is refused');
	like($screen, qr/^White offers a draw\. Black may accept or decline\.$/m, 'white offers');
	like($screen, qr/^Black offers a draw\. White may accept or decline\.$/m, 'later black does');
	like($screen, qr/^Black plays on\.$/m, 'black declines the first');
	like($screen, qr/^Draw: agreed$/m, 'and white takes the second');
	is($terminal->game->result->reason, 'agreement', 'the game is drawn by agreement');
	unlike($screen, qr/Bye/, 'a finished game stops by itself, without reading on');
};

subtest 'a draw offered to the bot' => sub {
	my $level = Game::Merrills::Bot->new(level => 1);
	my ($taken, $screen) = typed("d2\ndraw\n", human => 'white', bot => $level);
	like($screen, qr/^The bot (?:takes the draw|plays on)\.$/m, 'the bot answers at once');

	my $behind = Game::Merrills::Bot->new(level => 1);
	$behind->last_search({ score => -250 });
	my ($drawn) = typed("draw\n", human => 'white', bot => $behind);
	is($drawn->game->result->reason, 'agreement', 'a bot that thinks it is behind takes it');

	my $ahead = Game::Merrills::Bot->new(level => 1);
	$ahead->last_search({ score => 250 });
	my ($played_on, $said) = typed("draw\n", human => 'white', bot => $ahead);
	is($played_on->game->status, 'active', 'a bot that thinks it is ahead plays on');
	is($played_on->game->draw_offered_by, undef, 'and the offer is gone');
	like($said, qr/^The bot plays on\.$/m, 'having said so');
};

subtest 'resigning and quitting' => sub {
	my ($resigned, $screen) = typed("d2\nresign\n", human => 'white', bot => Game::Merrills::Bot->new(level => 1));
	is($resigned->game->result->reason, 'resign', 'resign ends the game');
	is($resigned->game->result->winner, 'black', 'against you, whoever is to move');
	like($screen, qr/^Black wins: White resigned$/m, 'and the result is shown');

	my ($out_of_turn) = terminal('', human => 'white', bot => Game::Merrills::Bot->new(level => 1));
	$out_of_turn->game->move('d2');
	$out_of_turn->resign;
	is($out_of_turn->game->result->winner, 'black',
		'asked while it is the bot to move, it is still you that resigns');

	my ($hotseat) = typed("d2\nresign\n", human => 'both');
	is($hotseat->game->result->winner, 'white', 'at one keyboard it is the side to move that resigns');

	my ($fresh, $unasked) = typed("quit\nd2\n", human => 'both');
	is($fresh->game->ply, 0, 'quit with nothing played stops at once');
	unlike($unasked, qr/Really quit/, 'without asking');

	my ($stayed, $asked) = typed("d2\nquit\nn\nf4\nquit\ny\nd6\n", human => 'both');
	like($asked, qr/^Really quit, with the game unfinished\? \(y\/n\) n$/m, 'with a game on, it asks');
	is($stayed->game->to_text, "1. d2 f4\n", 'n carries on, y stops, and nothing after it is read');
};

subtest 'against a bot: it replies, and says what it did' => sub {
	my ($terminal, $screen) = typed("d2\nd6\n", human => 'white', bot => Game::Merrills::Bot->new(level => 1, seed => 2));
	is($terminal->game->ply, 4, 'two moves of yours and two replies');
	is(scalar(() = $screen =~ m/^You placed a man on d[26]\.$/mg) >= 2 ? 1 : 0, 1, 'your moves are said as yours');
	like($screen, qr/^Black placed a man on [a-g][1-7]\.$/m, 'and the bot\'s as black\'s');
	unlike($screen, qr/thinking/, 'off a terminal there is no thinking line to rub out');
	unlike($screen, qr/^black> /m, 'and no prompt for the side the bot plays');
	like($screen, qr/^White \(you\) to place, 7 in hand\.$/m, 'the turn line says which side is you');

	my ($as_black, $seen) = typed("1\n", human => 'black', bot => Game::Merrills::Bot->new(level => 1));
	is($as_black->game->ply, 3, 'playing black, the bot opens and replies');
	is($as_black->game->history->[1]->side, 'black', 'and your move is the second');
	like($seen, qr/^black> 1$/m, 'at a prompt for black');
	unlike($seen, qr/^white> /m, 'and none for white');
};

subtest 'two bots play a whole game to its result' => sub {
	my ($terminal, $screen) = typed('', human => 'none', bot => {
		white => Game::Merrills::Bot->new(level => 1, seed => 1),
		black => Game::Merrills::Bot->new(level => 1, seed => 2),
	});
	is($terminal->game->status, 'finished', 'with nobody typing, the game still ends');
	my $result = $terminal->game->result->stringify;
	like($screen, qr/^\Q$result\E$/m, "and the result is the last thing shown: $result");
	unlike($screen, qr/Bye|> /, 'no prompt and no goodbye');
	is(boards($screen), $terminal->game->ply + 1, 'the board was drawn once a ply and once at the start');
};

subtest 'a finished game reads nothing more and asks no bot for a move' => sub {
	my $over = Game::Merrills->new;
	$over->resign;
	my $asked = 0;
	my $idle = Game::Merrills::Bot->new(level => 1);
	my ($terminal, $screen) = terminal("d2\nf4\n", human => 'none', game => $over,
		bot => { white => $idle, black => $idle });
	local $SIG{ALRM} = sub { die "the terminal went on looping in a finished game\n" };
	alarm 20;
	my $ended = eval { $terminal->start; 1 };
	alarm 0;
	ok($ended, 'start comes back') or diag $@;
	is(boards($$screen), 1, 'having drawn the board once');
	unlike($$screen, qr/> |Bye/, 'and prompted for nothing');
};

subtest 'start hands back the result, or undef for a game left unfinished' => sub {
	my ($done) = terminal("resign\n", human => 'both');
	isa_ok($done->start, 'Game::Merrills::Result', 'a finished game');
	my ($left) = terminal("d2\n", human => 'both');
	is($left->start, undef, 'an unfinished one');
};

subtest 'what cannot be a terminal dies' => sub {
	like(dies { Game::Merrills::Terminal->new(human => 'red') },
		qr/^human must be white, black, both or none, got 'red'/, 'a human that is no side');
};

done_testing;
