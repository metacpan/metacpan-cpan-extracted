#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Terminal;

sub terminal {
	my @script = map { ref $_ ? $_ : split // } @_;

	my $output = '';
	open my $oh, '>', \$output or die "cannot open a string handle: $!";

	my $terminal = Game::Oware::Terminal->new(
		out         => $oh,
		game        => Game::Oware->new(seed => 'history'),
		seat        => 'p1',
		seed        => 'history',
		level       => 1,
		ansi        => 0,
		interactive => 0,
		picking     => 1,
	);

	$terminal->keysource(sub {
		while (@script && ref $script[0]) {
			(shift @script)->($terminal);
		}
		return shift @script;
	});

	return ($terminal, \$output);
}

sub typed {
	my (@lines) = @_;

	my $output = '';
	open my $oh, '>', \$output or die "cannot open a string handle: $!";
	my $text = join '', map { "$_\n" } @lines;
	open my $ih, '<', \$text or die "cannot open a string handle: $!";

	my $terminal = Game::Oware::Terminal->new(
		in      => $ih,
		out     => $oh,
		game    => Game::Oware->new(seed => 'history'),
		seat    => 'p1',
		seed    => 'history',
		level   => 1,
		ansi    => 0,
		picking => 0,
	);

	return ($terminal, \$output);
}

sub sows {
	my ($game) = @_;
	return scalar grep { $_->{kind} eq 'sow' } @{ $game->log };
}

my $opening = Game::Oware->new(seed => 'history')->to_text;

subtest 'u takes back the move and the reply to it, and r plays them again' => sub {
	my %text;
	my ($terminal, $output) = terminal(
		"\r",
		sub { $text{second} = $_[0]->game->to_text },
		'u',
		sub { $text{undone} = $_[0]->game->to_text },
		'r',
		sub { $text{redone} = $_[0]->game->to_text },
		'q',
	);

	is($terminal->start, undef, 'the player quit');
	is(sows(Game::Oware->from_text($text{second})), 2, 'the move and the reply were played');
	is($text{undone}, $opening, 'u goes back to the turn before');
	is(sows(Game::Oware->from_text($text{undone})), 0, 'and the reply is gone too');
	is($text{redone}, $text{second}, 'r plays both again');
	like($$output, qr/Taken back\./, 'u says so');
	like($$output, qr/Played again\./, 'and so does r');
};

subtest 'a move after u leaves nothing to play again' => sub {
	my (%text, $could);
	my ($terminal, $output) = terminal(
		"\r",
		'u',
		"\e[B\r",
		sub {
			$could = $_[0]->history->can_redo;
			$text{played} = $_[0]->game->to_text;
		},
		'r',
		sub { $text{after} = $_[0]->game->to_text },
		'q',
	);

	$terminal->start;
	ok(!$could, 'the new move emptied redo');
	is($text{after}, $text{played}, 'r changes nothing');
	like($$output, qr/There is nothing to play again\./, 'and says so');
};

subtest 'u at the start notes and changes nothing' => sub {
	my $text;
	my ($terminal, $output) = terminal(
		'u',
		sub { $text = $_[0]->game->to_text },
		'q',
	);

	$terminal->start;
	is($text, $opening, 'the game is as it began');
	like($$output, qr/There is nothing to take back\./, 'and says so');
};

subtest 'the program opening is not a step to take back' => sub {
	my $output = '';
	open my $oh, '>', \$output or die "cannot open a string handle: $!";
	my @script = ('u', 'q');
	my $terminal = Game::Oware::Terminal->new(
		out         => $oh,
		game        => Game::Oware->new(seed => 'history'),
		seat        => 'p2',
		seed        => 'history',
		level       => 1,
		ansi        => 0,
		interactive => 0,
		picking     => 1,
		keysource   => sub { shift @script },
	);

	$terminal->start;
	is(sows($terminal->game), 1, 'the bot opening stands');
	like($output, qr/There is nothing to take back\./, 'u has nothing to take');
};

subtest 'undo and redo are typed commands' => sub {
	my ($terminal, $output) = typed('A', 'undo', 'quit');
	$terminal->start;
	is($terminal->game->to_text, $opening, 'undo takes back the move and the reply');
	like($$output, qr/Taken back\./, 'and says so');

	($terminal, $output) = typed('A', 'undo', 'redo', 'quit');
	$terminal->start;
	is(sows($terminal->game), 2, 'redo plays them again');
	like($terminal->game->to_text, qr/^A/m, 'from the house that was typed');
	like($$output, qr/Played again\./, 'and says so');

	($terminal, $output) = typed('undo', 'quit');
	$terminal->start;
	is($terminal->game->to_text, $opening, 'undo at the start changes nothing');
	like($$output, qr/There is nothing to take back\./, 'and says so');
};

subtest 'a finished game can take back its last move' => sub {
	my ($terminal) = terminal();
	$terminal->keysource(sub { "\r" });

	$terminal->start;
	is($terminal->game->status, 'finished', 'the game played out');
	ok($terminal->take_back, 'the last move is taken back');
	is($terminal->game->status, 'active', 'and the game is on again');
	ok($terminal->play_again, 'and played again');
	is($terminal->game->status, 'finished', 'to the same end');
};

done_testing;
