#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Symbol ();

use Game::Oware;
use Game::Oware::Terminal;
use Game::Oware::Test::Play;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The terminal, driven in process against in-memory handles.
#
# No pipe, no fork, and no subprocess writing into the TAP stream: that is what
# `in` and `out` being properties is for.
#
# Whole games are driven by a TIED input handle that asks the game what is legal
# and answers with one of those. A scripted list of letters desyncs into nonsense
# the moment anything about the loop changes, and then fails for a reason that
# has nothing to do with the change.

sub terminal {
	my (%options) = @_;

	my $lines = delete $options{lines} || [];
	my $output = '';
	open my $oh, '>', \$output or die "cannot open a string handle: $!";

	my $game = delete $options{game}
		|| Game::Oware->new(seed => 'terminal', %{ $options{game_args} || {} });

	my $terminal = Game::Oware::Terminal->new(
		out   => $oh,
		game  => $game,
		seed  => 'terminal',
		level => 1,
		ansi  => 0,
		%options,
	);

	# Symbol::gensym, not `my $ih`: tie needs a real glob to tie to, and an
	# undefined scalar gives "Can't use an undefined value as a symbol
	# reference" from inside tie rather than from the test.
	my $ih = Symbol::gensym();
	my $driver = tie *$ih, 'Game::Oware::Test::Play',
		game => $game, seat => $terminal->seat, lines => $lines;
	$terminal->in($ih);

	return ($terminal, \$output, $driver);
}

subtest 'a whole game, in process, on handles that are strings' => sub {
	my ($terminal, $output) = terminal();

	my $result = $terminal->start;

	isa_ok($result, 'Game::Oware::Result');
	is($terminal->game->status, 'finished', 'the game finished');
	cmp_ok(length $$output, '>', 500, 'and it printed a game rather than a line');

	like($$output, qr/p1 sows/, 'the human moves are narrated');
	like($$output, qr/p2 sows/, 'and so are the bot ones');
	like($$output, qr/\bA\b.*\bF\b/s, 'the letters are printed');
};

subtest 'the board is turned round for whoever is looking' => sub {
	my $game = Game::Oware->new(seed => 'view',
		board => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 0, 0 ]);

	my ($as_p1) = terminal(game => $game, seat => 'p1');
	my ($as_p2) = terminal(game => $game, seat => 'p2');

	my @one = $as_p1->board_text($game, 'p1');
	my @two = $as_p2->board_text($game, 'p2');

	like($one[0], qr/f\s+e\s+d\s+c\s+b\s+a/, "p1 sees p2's row on top");
	like($one[-1], qr/A\s+B\s+C\s+D\s+E\s+F/, 'and its own at the bottom');

	like($two[0], qr/F\s+E\s+D\s+C\s+B\s+A/, "p2 sees p1's row on top");
	like($two[-1], qr/a\s+b\s+c\s+d\s+e\s+f/, 'and its own at the bottom');

	# THE HALF THAT MATTERS: the view rotates, the names do not. Two people
	# looking at one game must never disagree about where a house is.
	is(scalar @one, 7, 'seven lines: two letter rows, two number rows, three rules');
	like($one[4], qr/\|\s*1\|\s*2\|\s*3\|\s*4\|\s*5\|\s*6\|/,
		"p1's own row reads A to F, left to right");
	like($two[2], qr/\|\s*6\|\s*5\|\s*4\|\s*3\|\s*2\|\s*1\|/,
		'and p2 sees the same row reversed, still called A to F');
};

subtest 'a bad letter is refused and the prompt comes back' => sub {
	my ($terminal, $output) = terminal(lines => [ "Z\n", "9\n", "\n" ]);

	$terminal->start;

	like($$output, qr/That is not a house/, 'it says so');
	my $count = () = $$output =~ /That is not a house/g;
	is($count, 2, 'once for each of the two bad answers');
	is($terminal->game->status, 'finished', 'and the game still played out');
};

subtest 'an illegal move is refused with the reason' => sub {
	# p2 is starved and only F reaches, so anything else is a must_feed refusal.
	my $game = Game::Oware->new(seed => 'feed',
		board => [ 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 21, 23 ]);

	my ($terminal, $output) = terminal(game => $game, lines => [ "A\n" ]);

	$terminal->start;

	like($$output, qr/no seeds, so you must play a house that reaches them/,
		'the refusal explains itself');
};

subtest 'the feeding rule is announced before it can be broken' => sub {
	my $game = Game::Oware->new(seed => 'feed',
		board => [ 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 21, 23 ]);

	my ($terminal, $output) = terminal(game => $game);

	$terminal->start;

	like($$output, qr/p2 has no seeds, so you must play a house that reaches them: F/,
		'a player who never tries the illegal move still learns the rule');
};

# THE ONE MOST LIKELY TO BE REPORTED AS A BUG. A capturing move captures
# nothing, and without a sentence that is indistinguishable from data loss.
subtest 'a forfeited slam says what happened' => sub {
	my $game = Game::Oware->new(seed => 'slam',
		board => [ 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 23, 23 ]);

	my ($terminal, $output) = terminal(game => $game);

	$terminal->start;

	like($$output, qr/would have taken every seed p2 has/,
		'it names the rule rather than leaving the board looking broken');
	like($$output, qr/so it takes none and they stay on the board/,
		'and says what happened to the seeds');
};

subtest 'a sow that laps the board says it skipped its own house' => sub {
	my $game = Game::Oware->new(seed => 'lap',
		board => [ 13, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 14, 15 ]);

	my ($terminal, $output) = terminal(game => $game, lines => [ "A\n" ]);

	$terminal->start;

	like($$output, qr/went right round, so it skipped A on the way past/,
		'because otherwise the counts do not add up by eye');
};

subtest 'the cycle ending is named as a house rule' => sub {
	# The circuit: one seed each, twelve-ply period, fires on ply 24.
	my $game = Game::Oware->new(seed => 'circuit',
		board => [ (0) x 5, 1, (0) x 5, 1, 23, 23 ]);

	my ($terminal, $output) = terminal(game => $game);

	$terminal->start;

	is($terminal->game->result->reason, 'cycle', 'the cycle rule ended it');
	like($$output, qr/the same position came round for the third time/,
		'it says which trigger fired');
	like($$output, qr/THAT IS A HOUSE RULE AND NOT A RULE OF OWARE/,
		'and refuses to pass a house rule off as the published one');
};

subtest 'the failed feed is explained, because it reads backwards' => sub {
	my $game = Game::Oware->new(seed => 'sweep',
		board => [ 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 19, 23 ]);
	$game->turn('p2');

	my ($terminal, $output) = terminal(game => $game);

	$terminal->start;

	is($terminal->game->result->reason, 'no_feed', 'the ending fired');
	like($$output, qr/took every seed in its own territory/,
		'a seat that cannot move being rewarded needs saying out loud');
};

subtest 'quit stops without a result, and start still returns' => sub {
	my ($terminal, $output) = terminal(lines => [ "quit\n" ]);

	my $result = $terminal->start;

	is($result, undef, 'no result');
	is($terminal->game->status, 'active', 'and the game was left where it stood');
	like($$output, qr/Stopped\. Nobody won/, 'it says so');
};

subtest 'help prints and does not consume a turn' => sub {
	my ($terminal, $output) = terminal(lines => [ "help\n" ]);

	$terminal->start;

	like($$output, qr/Twenty-five seeds wins/, 'the help is there');
	like($$output, qr/takes none/, 'and it warns about the three surprising rules');
};

# THE COLLISION THE FIRST DRAFT SHIPPED. `b` as a shortcut for `board` shadows
# houses B and b, so an ordinary move redrew the board instead of playing it.
subtest 'board is spelled out, because b is a house' => sub {
	my ($terminal) = terminal();

	is($terminal->command("board\n"), 'board', 'the word is the command');
	is($terminal->command("B\n"), 'B', 'and B is a house, not a command');
	is($terminal->command("b\n"), 'b', 'and so is b');
	is($terminal->command("q\n"), 'quit', 'q is safe, no house is called that');
	is($terminal->command("h\n"), 'help', 'and so is h');
	is($terminal->command("\n"), 'again', 'an empty line asks again');
	is($terminal->command(undef), 'quit', 'and end of input is a quit');
};

subtest 'NO_COLOR beats everything, and ansi beats the tty check' => sub {
	my ($plain) = terminal(ansi => 0);
	my ($bright) = terminal(ansi => 1);

	is($plain->ansi, 0, 'ansi off when asked');
	is($bright->ansi, 1, 'and on when asked');

	local $ENV{NO_COLOR} = '1';
	is($bright->ansi, 0, 'but NO_COLOR wins over an explicit request');

	local $ENV{NO_COLOR} = '';
	is($bright->ansi, 1, 'an empty NO_COLOR is not set');
};

subtest 'colour carries no information' => sub {
	my ($bright, $output) = terminal(ansi => 1, lines => [ "quit\n" ]);
	$bright->start;
	my $coloured = $$output;

	my ($plain, $plain_out) = terminal(ansi => 0, lines => [ "quit\n" ]);
	$plain->start;

	$coloured =~ s/\e\[[0-9;]*m//g;
	is($coloured, $$plain_out, 'strip the escapes and the two are the same text');
};

subtest 'every option is validated in the constructor' => sub {
	eval { Game::Oware::Terminal->new(variant => 'draughts') };
	like($@, qr/there is no variant 'draughts'/, 'an unknown variant');

	eval { Game::Oware::Terminal->new(level => 9) };
	like($@, qr/there is no level 9/, 'an unknown level');

	eval { Game::Oware::Terminal->new(seat => 'p3') };
	like($@, qr/seat must be p1 or p2/, 'and a seat that does not exist');
};

subtest 'quiet says nothing but still plays' => sub {
	my ($terminal, $output) = terminal(quiet => 1);

	my $result = $terminal->start;

	isa_ok($result, 'Game::Oware::Result');
	unlike($$output, qr/sows/, 'no narration');
	unlike($$output, qr/Oware, abapa rules/, 'and no banner');
};

# bin/oware owns the exit status, which is the only reason it exists as a
# separate file. Run as a subprocess because that is the only way to see an
# exit status, and with output captured so nothing lands in the TAP stream.
subtest 'bin/oware reports what happened in its exit status' => sub {
    my $perl = $^X;

    my $help = `$perl -Ilib bin/oware --help 2>&1`;
    is($? >> 8, 0, 'help exits 0');
    like($help, qr/Exit status is 0 if you won or drew/, 'and prints the legend');

    my $version = `$perl -Ilib bin/oware --version 2>&1`;
    is($? >> 8, 0, 'version exits 0');
    like($version, qr/oware \d/, 'and prints one');

    for my $bad (
        [ '--variant draughts', qr/there is no variant/ ],
        [ '--level 9',          qr/there is no level/ ],
        [ '--seat p3',          qr/seat must be p1 or p2/ ],
    ) {
        my ($option, $expect) = @$bad;
        my $out = `$perl -Ilib bin/oware $option </dev/null 2>&1`;
        is($? >> 8, 2, "$option exits 2");
        like($out, $expect, "$option says why");
        unlike($out, qr/ at \S+ line \d+/, "$option does not leak a perl location");
    }

    my $unknown = `$perl -Ilib bin/oware --nonsense </dev/null 2>&1`;
    is($? >> 8, 2, 'an unknown option exits 2');

    my $quit = `echo quit | $perl -Ilib bin/oware --quiet --seed z 2>&1`;
    is($? >> 8, 0, 'quitting exits 0');
};

done_testing;
