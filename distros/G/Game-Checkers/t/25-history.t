#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp ();

use Game::Checkers;
use Game::Checkers::Bot;
use Game::Checkers::Terminal;

sub terminal {
	my ($script, %option) = @_;
	my @queue = @{$script};
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	my $terminal;
	my $source = sub {
		while (@queue && ref $queue[0]) {
			(shift @queue)->($terminal);
		}
		return shift @queue;
	};
	$terminal = Game::Checkers::Terminal->new(
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		keysource => $source,
		picking => 1,
		%option
	);
	return ($terminal, \$output);
}

sub keys_of {
	return map { ref $_ ? $_ : split //, $_ } @_;
}

sub against_bot {
	return (
		bot => Game::Checkers::Bot->new(level => 1, seed => 5),
		human => 'black',
	);
}

my $opening = Game::Checkers->new->to_pdn;

subtest 'u takes back your move and the reply, r plays them again' => sub {
	plan tests => 8;
	my %seen;
	my $snap = sub { my $name = shift; sub { $seen{$name} = $_[0]->game->to_pdn } };
	my $check = sub { my $name = shift; sub { $seen{"after $name"} = $_[0]->game->to_pdn } };
	my ($terminal, $output) = terminal([keys_of(
		"\r", $snap->('second turn'), "\r", $snap->('third turn'),
		'u', $check->('u'), 'r', $check->('r'), 'u', 'u', $check->('u u'),
		"q", "y\r"
	)], against_bot());
	$terminal->start;

	isnt $seen{'second turn'}, $opening, 'the bot had replied by the second turn';
	is $seen{'after u'}, $seen{'second turn'}, 'u went back to the start of the second turn';
	is +(Game::Checkers->from_pdn($seen{'after u'}))->ply, 2,
		'so the bot reply to the second move is gone with it';
	is $seen{'after r'}, $seen{'third turn'}, 'r played the turn again';
	is $seen{'after u u'}, $opening, 'two more u go back to the opening';
	like ${$output}, qr/Taken back\./, 'u said so';
	like ${$output}, qr/Played again\./, 'and so did r';
	is $terminal->history->redo_count, 2, 'and two turns were left to play again';
};

subtest 'a move after u forgets what could be played again' => sub {
	plan tests => 4;
	my %seen;
	my ($terminal, $output) = terminal([keys_of(
		"\r", "\r", 'u', sub { $seen{redo} = $_[0]->history->can_redo },
		"\e[B\r", sub { $seen{after} = $_[0]->history->can_redo; $seen{pdn} = $_[0]->game->to_pdn },
		'r', sub { $seen{again} = $_[0]->game->to_pdn },
		'q', "y\r"
	)], against_bot());
	$terminal->start;
	ok $seen{redo}, 'after u there was a turn to play again';
	ok !$seen{after}, 'after another move there was not';
	is $seen{again}, $seen{pdn}, 'so r changed nothing';
	like ${$output}, qr/There is nothing to play again\./, 'and said so';
};

subtest 'u at the start notes it and changes nothing' => sub {
	plan tests => 4;
	my %seen;
	my ($terminal, $output) = terminal([keys_of(
		'u', 'r', sub { $seen{pdn} = $_[0]->game->to_pdn }, 'q'
	)], against_bot());
	$terminal->start;
	is $seen{pdn}, $opening, 'the game is still the opening';
	is $terminal->game->ply, 0, 'with nothing played';
	like ${$output}, qr/There is nothing to take back\./, 'u said there was nothing';
	like ${$output}, qr/There is nothing to play again\./, 'and so did r';
};

subtest 'in hotseat every move is a turn' => sub {
	plan tests => 4;
	my @ply;
	my $ply = sub { push @ply, $_[0]->game->ply };
	my ($terminal) = terminal([keys_of(
		"\r", "\r", $ply, 'u', $ply, 'u', $ply, 'r', $ply, 'q', "y\r"
	)], human => 'both');
	$terminal->start;
	is $ply[0], 2, 'two moves, one a side';
	is $ply[1], 1, 'u takes back one';
	is $ply[2], 0, 'and the next u the other';
	is $ply[3], 1, 'r plays one again';
};

subtest 'undo and redo typed' => sub {
	plan tests => 4;
	my @ply;
	my $ply = sub { push @ply, $_[0]->game->ply };
	my ($picked) = terminal([keys_of(
		"\r", "\r", ":undo\r", $ply, ":redo\r", $ply, 'q', "y\r"
	)], against_bot());
	$picked->start;
	is_deeply \@ply, [2, 4], 'after a colon, undo and redo are commands';

	my $input = join '', map { "$_\n" } '11-15', '1', 'undo', 'redo', 'undo', 'quit', 'y';
	open my $in, '<', \$input or die "in memory handle: $!";
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	my $typed = Game::Checkers::Terminal->new(
		in => $in, out => $out, interactive => 0, colour => 0, ascii => 1, picking => 0,
		against_bot()
	);
	$typed->start;
	is $typed->game->ply, 2, 'undo, redo, undo leaves one turn taken back';
	is $typed->history->redo_count, 1, 'with that turn to play again';
	is scalar(() = $output =~ m/Taken back\./g), 2, 'and each undo said so';
};

subtest 'a swap clears what the old game left behind' => sub {
	plan tests => 3;
	my ($terminal) = terminal([], against_bot());
	$terminal->person_turn;
	$terminal->command('11-15');
	$terminal->bot_move;
	$terminal->person_turn;
	$terminal->highlight({ 11 => 'from' });
	$terminal->log->note('stale');
	$terminal->take_back;
	is_deeply $terminal->highlight, {}, 'no square is marked';
	is_deeply [$terminal->log->lines], [], 'nothing old is left to say';
	is $terminal->bot->last_search, undef, 'and the bot forgot its last search';
};

subtest 'the keys are listed' => sub {
	plan tests => 2;
	my ($terminal) = terminal([]);
	like $terminal->legend, qr/u undo, r redo/, 'u and r are in the legend';
	is $terminal->picker($terminal->game->legal_moves)->game_keys->{r}, 'redo',
		'and r is a picker key';
};

subtest 'with two bots playing there is nothing to take back' => sub {
	plan tests => 3;
	my ($terminal) = terminal([],
		bot => Game::Checkers::Bot->new(level => 1, seed => 7), human => 'none');
	$terminal->start;
	ok $terminal->game->result, 'the bots played to the end';
	is $terminal->history->undo_count, 0, 'and nothing was recorded';
	my $ply = $terminal->game->ply;
	$terminal->take_back;
	is $terminal->game->ply, $ply, 'so undo changes nothing';
};

subtest 'playing white, the bot opening is not a turn to go back to' => sub {
	plan tests => 4;
	my @seen;
	my ($terminal, $output) = terminal([keys_of(
		sub { push @seen, $_[0]->history->can_undo }, 'u', sub { push @seen, $_[0]->game->ply }, "
", 'u', sub { push @seen, $_[0]->game->ply }, 'q', "y\r"
	)], bot => Game::Checkers::Bot->new(level => 1, seed => 5), human => 'white');
	$terminal->start;
	ok !$seen[0], 'on the first turn there is nothing to take back';
	like ${$output}, qr/There is nothing to take back\./, 'and u says so';
	is $seen[1], 1, 'leaving the bot opening on the board';
	is $seen[2], 1, 'and u after a turn comes back to it';
};

subtest 'a loaded game starts its history afresh' => sub {
	plan tests => 2;
	my $file = File::Spec->catfile(File::Temp::tempdir(CLEANUP => 1), 'game.pdn');
	my ($saved) = terminal([keys_of("\r", "\r", ":save $file\r", ":load $file\r", 'q', "y\r")], human => 'both');
	$saved->start;
	is $saved->game->ply, 2, 'the game came back';
	ok !$saved->history->can_undo, 'with nothing to take back';
};

done_testing;
