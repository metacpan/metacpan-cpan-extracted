#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Terminal;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# Every one of these runs without a terminal: the keys come from `keysource`,
# so nothing here needs a tty, a pipe, or Term::ReadKey to be installed. That
# is the same arrangement as Game::Checkers' t/22, and it is the only way a
# key loop gets tested at all rather than being asserted about in POD.
#
# `interactive => 0` keeps the screen-clearing escape out of the captured
# output, because a test that has to skip past "\e[2J\e[H" to find a board is
# testing the wrong thing.

# A capture at E, a long house at D, and no starvation anywhere: an ordinary
# mid-game position where the five options have five different things to say.
my @MID = (0, 1, 2, 7, 3, 5, 1, 2, 4, 6, 4, 5, 4, 4);

sub terminal {
	my ($keys, %option) = @_;

	my @chars = split //, defined $keys ? $keys : '';
	my $output = '';
	open my $oh, '>', \$output or die "cannot open a string handle: $!";

	my $game = delete $option{game}
		|| Game::Oware->new(seed => 'pick', board => [@MID]);

	my $terminal = Game::Oware::Terminal->new(
		out         => $oh,
		game        => $game,
		seat        => 'p1',
		seed        => 'pick',
		level       => 1,
		ansi        => 0,
		interactive => 0,
		picking     => 1,
		keysource   => sub { shift @chars },
		%option,
	);

	return ($terminal, \$output, \@chars);
}

subtest 'a key at a time, named' => sub {
	my ($terminal) = terminal("k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");

	my @got;
	while (defined(my $key = $terminal->read_key)) {
		push @got, $key eq ' ' ? 'space' : $key;
	}

	is_deeply(\@got, [ qw/ k up down right left page_up home enter tab backspace
		interrupt eof space q escape page_down / ],
		'a character comes back as itself and a sequence as a name');
};

# The escape key and the opening byte of an arrow key are the same byte, and
# the only thing that tells them apart is whatever comes next.
subtest 'an escape does not eat the key behind it' => sub {
	my ($terminal) = terminal("\eq");

	is($terminal->read_key, 'escape', 'the escape is an escape');
	is($terminal->read_key, 'q', 'and the keystroke behind it survives');
};

subtest 'the arrow keys choose a move, and enter sows it' => sub {
	my ($terminal, $output) = terminal("\e[B\e[B\e[B\r");

	my $legal = $terminal->game->legal($terminal->seat);
	my $fourth = $legal->[3];

	$terminal->enter_raw;
	is($terminal->pick, 1, 'a picked move is played there and then');

	is(scalar @{ $terminal->game->events }, 2,
		"the start and one sow, and nothing else")
		or diag explain $terminal->game->events;

	my ($sow) = grep { $_->{kind} eq 'sow' } @{ $terminal->game->events };
	is($sow->{payload}{house}, $fourth,
		'the fourth option, three presses down from the first');

	like($$output, qr/arrows to choose/, 'and the keys were on the screen');
};

subtest 'the cursor wraps, both ways' => sub {
	my ($up) = terminal("\e[A\r");
	my $legal = $up->game->legal('p1');
	$up->enter_raw;
	$up->pick;
	my ($sow) = grep { $_->{kind} eq 'sow' } @{ $up->game->events };
	is($sow->{payload}{house}, $legal->[-1], 'up from the first is the last');

	my $down = ("\e[B" x scalar @$legal) . "\r";
	my ($round) = terminal($down);
	$round->enter_raw;
	$round->pick;
	my ($again) = grep { $_->{kind} eq 'sow' } @{ $round->game->events };
	is($again->{payload}{house}, $legal->[0],
		'and a full lap of downs comes back to the first');
};

# THE BOARD ABOVE THE LIST IS THE RESULT, NOT THE PATH. The first version of
# this drew the live board with the candidate's marks over it, so the cursor
# house read `- 1` for a house the move had just emptied, and a capture showed
# the opponent's seeds still sitting there. Checkers can highlight a jump
# because a checkers square holds a piece or nothing; an Oware house holds a
# NUMBER, and a mark beside the wrong number is worse than no mark.
subtest 'the preview is the board the move would produce' => sub {
	my ($terminal, $output) = terminal('q');

	$terminal->enter_raw;
	$terminal->pick;

	like($$output, qr/if you sow B:/, 'it says which move it is showing');

	# B holds one seed, so sowing it empties B and takes C from 2 to 3.
	my @line = grep { /\bx\b|\*|\+|-/ } split /\n/, $$output;
	my ($counts) = grep { /-\s+0/ } @line;
	ok($counts, 'the emptied house shows the nought it would hold')
		or diag $$output;
	like($counts, qr/\*\s+3/, 'and the landing house the three it would hold');

	# And the live game is untouched: a preview resolves a move, it never
	# plays one.
	is($terminal->game->board->[1], 1, 'B still holds its seed');
	is($terminal->game->status, 'active', 'and the game never moved');
};

subtest 'a capture shows the store going up before it is played' => sub {
	# E sows 3 into F, a, b, taking b at 3 and a at 2: five seeds.
	my ($terminal, $output) = terminal("Eq");

	$terminal->enter_raw;
	$terminal->pick;

	like($$output, qr/if you sow E:/, 'the letter jumped the cursor to E');
	like($$output, qr/E\s+sows 3, captures 5 from b, a/,
		'the option says what it takes');
	like($$output, qr/x\s+0/, 'the captured houses are marked and emptied');
	like($$output, qr/\b9\b/, 'and the store shows 4 plus 5');
	like($$output, qr/35 in play/, 'with five seeds gone off the board');
};

# THE ONE THE PICKER BROKE. `_show_choice` clears the screen on every
# keystroke, so the narration printed when the bot moved has scrolled off
# before there is anything to choose: the player would be answering a move
# they were shown for no time at all.
subtest "the opponent's last move is on every frame" => sub {
	my $game = Game::Oware->new(seed => 'reply', board => [@MID]);
	$game->turn('p2');

	my ($terminal, $output) = terminal("\e[Bq", game => $game);

	# p2 sows c, which is the bot's turn, and then it is p1 to pick.
	my $result = $terminal->start;

	is($result, undef, 'the player quit out of the picker');
	like($$output, qr/p2 sowed [a-f]\./,
		'the frame says what the opponent did, in the past tense');

	my @frame = split /    if you sow /, $$output;
	shift @frame;
	cmp_ok(scalar @frame, '>=', 2, 'there was more than one frame');

	my $said = () = $$output =~ /p2 sowed [a-f]\./g;
	cmp_ok($said, '>=', 2, 'and it is on each of them, not just the first');
};

subtest 'v swaps the preview for the board as it stands' => sub {
	my $game = Game::Oware->new(seed => 'stands', board => [@MID]);
	$game->turn('p2');

	my ($terminal, $output) = terminal("vq", game => $game);
	$terminal->start;

	like($$output, qr/    as it stands:/, 'v draws the live position');

	# The live frame carries the OPPONENT'S marks, which is what the board
	# looked like when the bot had finished with it.
	my ($stands) = ($$output =~ /    as it stands:\n(.*?)\n\n/s);
	ok($stands, 'and there is a board under that heading') or diag $$output;
	like($stands, qr/-\s+0/, "with the house p2 emptied marked on it");
};

subtest 'a house letter that is not on the list says why not' => sub {
	my ($terminal, $output) = terminal("Aaq");

	$terminal->enter_raw;
	$terminal->pick;

	like($$output, qr/That house has no seeds in it\./,
		'A is empty, so it is refused rather than ignored');
	like($$output, qr/That house is on your opponent side of the board\./,
		'and a lowercase letter is the other seat');
};

subtest 'the number keys and home and end jump about' => sub {
	my ($terminal) = terminal("3\r");
	my $legal = $terminal->game->legal('p1');
	$terminal->enter_raw;
	$terminal->pick;
	my ($sow) = grep { $_->{kind} eq 'sow' } @{ $terminal->game->events };
	is($sow->{payload}{house}, $legal->[2], 'a digit is the option at that place');

	my ($last) = terminal("\e[F\r");
	$last->enter_raw;
	$last->pick;
	my ($end) = grep { $_->{kind} eq 'sow' } @{ $last->game->events };
	is($end->{payload}{house}, $legal->[-1], 'and end is the last of them');
};

subtest 'a key that does nothing says so, and nothing is played' => sub {
	my ($terminal, $output) = terminal("zq");

	$terminal->enter_raw;
	is($terminal->pick, 0, 'q stopped it');

	like($$output, qr/That key does nothing here/, 'the dud key said so');
	is($terminal->game->status, 'active', 'and no move was made');
};

subtest 'eof and an interrupt both stop, and leave the game standing' => sub {
	for my $case ([ '', 'end of input' ], [ "\x03", 'an interrupt' ]) {
		my ($keys, $what) = @$case;
		my ($terminal) = terminal($keys);
		$terminal->enter_raw;
		is($terminal->pick, 0, "$what stops the picker");
		is($terminal->raw, 0, 'and puts the terminal back');
	}
};

# The feeding rule prunes the list, and a list that only ever shows what is
# legal is exactly where a player cannot find out why their house went.
subtest 'the feeding rule is said where the list is' => sub {
	my $game = Game::Oware->new(seed => 'feed',
		board => [ 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 21, 23 ]);

	my ($terminal, $output) = terminal('q', game => $game);

	$terminal->enter_raw;
	$terminal->pick;

	like($$output, qr/p2 has no seeds, so only a house that reaches them/, 'the pruned list explains itself');
	unlike($$output, qr/^\s+A\s+sows/m, 'and A, which does not reach, is not on it');
};

subtest 't and a colon hand the turn to the typed prompt' => sub {
	for my $key (qw/ t : /) {
		my @line = ("quit\n");
		my ($terminal, $output) = terminal($key);

		# The typed loop reads from `in`, which the picker never touches.
		my $handle = \@line;
		$terminal->in(_lines(\@line));

		$terminal->enter_raw;
		is($terminal->pick, 0, "$key fell through to the typed turn, which quit");
		is($terminal->raw, 0, 'and the terminal was put back first');
		like($$output, qr/your move \[/, 'the typed prompt was printed');
	}
};

subtest 't turns picking off for good, a colon does not' => sub {
	my ($typed) = terminal('t');
	$typed->in(_lines([ "quit\n" ]));
	$typed->enter_raw;
	$typed->pick;
	is($typed->picking, 0, 't is a change of mode');

	my ($once) = terminal(':');
	$once->in(_lines([ "quit\n" ]));
	$once->enter_raw;
	$once->pick;
	is($once->picking, 1, 'and a colon is one command');
};

subtest 'picking follows the keys, and quiet turns it off' => sub {
	my ($asked) = terminal('q', picking => 1);
	is($asked->picking, 1, 'asked for, and on');

	my ($refused) = terminal('q', picking => 0);
	is($refused->picking, 0, 'refused, and off');

	# keysource is set, so the keys ARE available; quiet still wins, because
	# quiet means there is no board to put a cursor on.
	my ($hushed) = terminal('q', picking => undef, quiet => 1);
	is($hushed->keys_available, 1, 'the keys are there');
	is($hushed->picking, 0, 'but quiet has no board to pick against');
};

# Without Term::ReadKey and without a keysource there is nothing to read keys
# with, and the fallback has to be the typed game rather than a failure.
subtest 'no key source at all falls back to typing, once' => sub {
	my ($terminal, $output) = terminal(undef, picking => 1, keysource => undef);
	$terminal->in(_lines([ "quit\n" ]));

	is($terminal->keys_available, 0, 'nothing to read keys with');
	is($terminal->pick, 0, 'so pick hands over to the typed turn, which quit');
	is($terminal->picking, 0, 'and does not try again next turn');
	like($$output, qr/your move \[/, 'the typed prompt was printed');
};

subtest 'a whole game, picked rather than typed' => sub {
	my $game = Game::Oware->new(seed => 'whole');

	# Always the first option, which is a legal move in every position this
	# can reach, so the game plays itself out without the script knowing a
	# single house in advance.
	my ($terminal, $output) = terminal(undef, game => $game);
	$terminal->keysource(sub { "\r" });

	my $result = $terminal->start;

	isa_ok($result, 'Game::Oware::Result');
	is($game->status, 'finished', 'the game finished on the keys alone');
	is($terminal->raw, 0, 'and the terminal was put back');
	like($$output, qr/if you sow /, 'every turn showed a preview');

	# In the picker the narration lives in the frame's header, in the past
	# tense, because the screen it was printed on has been cleared. Only the
	# ply that ends the game narrates in place: there is no frame after it.
	like($$output, qr/p1 sowed [A-F]\./, 'the round is reprinted each frame');
	like($$output, qr/\Q@{[ $result->stringify ]}\E/, 'and the result is printed');

	# NOT ONCE PER PLY. The picker suppresses the mid-game redraw precisely
	# because the next frame clears it, so a board drawn there is a flash.
	my $boards = () = $$output =~ /in play, 25 wins/g;
	my $frames = () = $$output =~ /    if you sow /g;
	is($boards, $frames + 1, 'one board a frame, plus the final position');
};

# An in-memory filehandle over a list of lines, for the subtests that fall
# through from the picker into the typed prompt.
sub _lines {
	my ($lines) = @_;
	my $text = join '', @$lines;
	open my $fh, '<', \$text or die "cannot open a string handle: $!";
	return $fh;
}

done_testing;
