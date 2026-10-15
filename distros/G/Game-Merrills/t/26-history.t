#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use File::Temp ();
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Terminal;
use Game::Merrills::Test::Screen qw/typed/;

sub session {
	my ($keys, %option) = @_;
	my @chars = split //, $keys;
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	open my $in, '<', \'' or die "in memory handle: $!";
	my $terminal = Game::Merrills::Terminal->new(
		in => $in,
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		human => 'both',
		keysource => sub { shift @chars },
		picking => 1,
		%option
	);
	local $SIG{ALRM} = sub { die "the session did not end\n" };
	alarm 60;
	$terminal->start;
	alarm 0;
	return ($terminal, $output);
}

sub last_frame {
	my ($output) = @_;
	my @frames = split /^(?=7 [ (\[{<])/m, $output;
	return $frames[-1];
}

sub against_bot {
	my ($keys) = @_;
	return session($keys, human => 'white', bot => Game::Merrills::Bot->new(level => 1, seed => 3));
}

subtest 'against the bot, u takes back your move and the reply to it' => sub {
	my ($first) = against_bot('');
	my ($second) = against_bot("\r");
	is($second->game->ply, 2, 'your move and the reply bring your second turn');
	is($second->history->text, $second->game->to_text, 'which is kept as it stands');

	my ($back, $output) = against_bot("\ru");
	is($back->game->to_text, $first->game->to_text, 'u at the second turn: the game is as it was at the first');
	is($back->game->ply, 0, 'the reply is gone as well as the move');
	like(last_frame($output), qr/^Taken back\.$/m, 'and the next screen says so');

	my ($third) = against_bot("\r\r");
	my ($two_back) = against_bot("\r\ru");
	is($two_back->game->to_text, $second->game->to_text, 'u at the third turn: as it was at the second');
	is($two_back->game->ply, 2, 'two plies back, not one');
	is_deeply($two_back->recent, [], 'the moves taken back are no longer told');
	is_deeply($two_back->highlight, {}, 'nothing is left marked');
	is($two_back->preview, undef, 'and nothing is drawn in place of the board');
	is($two_back->bot->last_search, undef, 'the bot forgets a search of a game that is gone');

	my ($again, $said) = against_bot("\r\rur");
	is($again->game->to_text, $third->game->to_text, 'r plays it again');
	like(last_frame($said), qr/^Played again\.$/m, 'and says so');
};

subtest 'a move after u forgets what could have been played again' => sub {
	my ($terminal, $output) = session("\r\ru\rr", human => 'white',
		bot => Game::Merrills::Bot->new(level => 1, seed => 3));
	ok(!$terminal->history->can_redo, 'nothing to play again');
	like(last_frame($output), qr/^There is nothing to play again\.$/m, 'r says so');
	is($terminal->game->ply, 4, 'and changes nothing');
};

subtest 'u at the start says so and changes nothing' => sub {
	my ($terminal, $output) = session('u');
	is($terminal->game->ply, 0, 'no move');
	like(last_frame($output), qr/^There is nothing to take back\.$/m, 'a line says there is nothing');
	ok(!$terminal->history->can_undo, 'and the history is empty');

	my ($opening, $said) = session('r');
	like(last_frame($said), qr/^There is nothing to play again\.$/m, 'and r the same');
};

subtest 'two people at one keyboard: every move is a step' => sub {
	my ($terminal) = session("\r\r\ruu");
	is($terminal->game->to_text, "1. a7\n", 'three moves, two taken back');
	is($terminal->history->undo_count, 1, 'one more to take back');
	is($terminal->history->redo_count, 2, 'and two to play again');

	my ($again) = session("\r\r\ruur");
	is($again->game->to_text, "1. a7 d7\n", 'r plays one of them again');
};

subtest 'undo and redo typed' => sub {
	my ($terminal, $screen) = typed("d2\nf4\nd6\nundo\nundo\nredo\n");
	is($terminal->game->to_text, "1. d2 f4\n", 'two back and one forward');
	like($screen, qr/^Played again\.$/m, 'redo says so');

	my ($nothing, $said) = typed("redo\n");
	like($said, qr/^There is nothing to play again\.$/m, 'redo with nothing to play again says so');
	is($nothing->game->ply, 0, 'and plays nothing');
};

subtest 'loading starts the history afresh' => sub {
	my ($handle, $file) = File::Temp::tempfile(UNLINK => 1);
	print {$handle} "1. d2 f4\n";
	close $handle;
	my ($terminal, $screen) = typed("a7\nload $file\nundo\n");
	is($terminal->game->to_text, "1. d2 f4\n", 'the loaded game stands');
	like($screen, qr/^There is nothing to take back\.$/m, 'with nothing before it to take back');
};

subtest 'two bots: nobody is at the keys, so there is no history' => sub {
	my ($terminal) = session('', human => 'none', bot => {
		white => Game::Merrills::Bot->new(level => 1, seed => 1),
		black => Game::Merrills::Bot->new(level => 1, seed => 2),
	});
	my $text = $terminal->game->to_text;
	ok(!$terminal->history->can_undo, 'nothing was kept');
	$terminal->take_back;
	is($terminal->game->to_text, $text, 'and undo changes nothing');
	is((grep { $_ eq q{There is nothing to take back.} } @{ $terminal->heard }), 1, q{saying so});
};

done_testing;
