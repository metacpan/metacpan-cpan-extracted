#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Terminal;
use Game::Merrills::Test::Position qw/p names position_of stream/;

# Every one of these runs without a terminal: the keys come from keysource, so
# nothing here needs a tty, a pipe, or Term::ReadKey to be installed.
sub terminal {
	my ($keys, %option) = @_;
	my @chars = split //, defined $keys ? $keys : '';
	my $typed = delete $option{typed};
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	open my $in, '<', \(defined $typed ? $typed : '') or die "in memory handle: $!";
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
	return ($terminal, \$output, \@chars);
}

sub boards { return scalar(() = ${ $_[0] } =~ m/^7 [ (\[{<]/mg) }

sub last_frame {
	my ($output) = @_;
	my @frames = split /^(?=7 [ (\[{<])/m, ${$output};
	return $frames[-1];
}

my %MILL = (white => [qw/a7 d7 g4 c3 e3/], black => [qw/a1 d1 g1 b4 e5/]);

sub mill_game { return Game::Merrills->new(position => position_of(%MILL)) }

subtest 'a key at a time, named' => sub {
	my ($terminal) = terminal("k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~\e[Z");
	my @got;
	while (defined(my $key = $terminal->read_key)) {
		push @got, $key eq ' ' ? 'space' : $key;
	}
	is_deeply(\@got, [qw/k up down right left page_up home enter tab backspace
		interrupt eof space q escape page_down back_tab/],
		'a character comes back as itself and a sequence as a name');

	my ($named) = terminal("\e[A");
	cmp_ok(length($named->read_key), '>', 1, 'so a name is the longer of the two');
};

subtest 'an escape does not eat the key behind it' => sub {
	my ($terminal) = terminal("\eq");
	is($terminal->read_key, 'escape', 'the escape is an escape');
	is($terminal->read_key, 'q', 'and the keystroke behind it survives');
};

subtest 'the arrows go where a hand expects on a board that is not a grid' => sub {
	my ($terminal) = terminal('');
	my @all = Game::Merrills::Points::all_points();
	my @cases = (
		[ a7 => right => 'd7', 'along the top, not down to b6' ],
		[ a7 => down => 'a4', 'down the side, not in to b6' ],
		[ d6 => down => 'd5', 'the next point down the file' ],
		[ d6 => up => 'd7', 'and up it' ],
		[ d5 => down => 'd3', 'across the centre to the point facing' ],
		[ c4 => right => 'e4', 'and the same from side to side' ],
		[ b6 => right => 'd6', 'along the middle square' ],
		[ g1 => left => 'd1', 'back along the bottom' ],
		[ a7 => up => 'a7', 'nothing above the top row: stay' ],
		[ a7 => left => 'a7', 'nothing left of the a file: stay' ],
		[ g1 => down => 'g1', 'nothing below the bottom row: stay' ],
		[ g1 => right => 'g1', 'nothing right of the g file: stay' ],
	);
	for my $case (@cases) {
		my ($from, $direction, $to, $why) = @{$case};
		is(Game::Merrills::Points::name($terminal->nearest(p($from), $direction, \@all)), $to,
			"$from $direction is $to: $why");
	}
	is(Game::Merrills::Points::name($terminal->nearest(p('a7'), 'right', [ p('b6'), p('g1') ])), 'b6',
		'with d7 not on offer, right from a7 takes the next best');
	is($terminal->nearest(p('a7'), 'right', [ p('a7') ]), p('a7'), 'and with nothing on offer, stays');
};

subtest 'enter on an empty board places the first point' => sub {
	my ($terminal, $output) = terminal("\r");
	$terminal->enter_raw;
	is($terminal->pick, '', 'a picked move is played there and then, and nothing is handed back');
	is($terminal->game->to_text, "1. a7\n", 'the first point in order is a7');
	like(${$output}, qr/^Choose a point to place a man on\.$/m, 'the screen said what was being asked');
	like(${$output}, qr/^ > a7   1 of 24$/m, 'and where the cursor was, among how many');
	like(${$output}, qr/^7 \[W\]/m, 'with the man drawn where it would land');
	like(${$output}, qr/arrows move \| tab next \| enter choose \| backspace back/, 'and the keys along the foot');
	is_deeply($terminal->highlight, {}, 'once played, the marks of choosing are gone');
	is($terminal->preview, undef, 'and so is the board that was only a preview');
};

subtest 'the cursor is moved with the arrows, tab, and by naming a point' => sub {
	my ($arrows) = terminal("\e[C\e[B\r");
	$arrows->enter_raw;
	$arrows->pick;
	is($arrows->game->to_text, "1. d6\n", 'right then down from a7 is d7 then d6');

	my ($tabs) = terminal("\t\t\tk\r");
	$tabs->enter_raw;
	$tabs->pick;
	is($tabs->game->to_text, "1. g7\n", 'three tabs forward and a k back is the third point');

	my ($back) = terminal("\e[Z\r");
	$back->enter_raw;
	$back->pick;
	is($back->game->to_text, "1. g1\n", 'shift-tab from the first goes round to the last');

	my ($ends) = terminal("\e[F\e[H\e[6~\r");
	$ends->enter_raw;
	$ends->pick;
	is($ends->game->to_text, "1. g1\n", 'end, home, then page down is the last again');

	my ($named, $output) = terminal("d2\r");
	$named->enter_raw;
	$named->pick;
	is($named->game->to_text, "1. d2\n", 'd then 2 jumps to d2');

	my ($wrong, $said) = terminal("d4a7\r");
	$wrong->game->move('a7');
	$wrong->enter_raw;
	$wrong->pick;
	like(${$said}, qr/^A point is a letter and a number, like d2\.$/m, 'd4 is not a point, and it says so');
	like(${$said}, qr/^A7 cannot be chosen here\.$/m, 'a7 is taken, and it says that');
	is($wrong->game->history->[-1]->notation, 'd7', 'and the cursor stayed where it was, on the first free point');
};

subtest 'a move is chosen a step at a time: the man, the point, the man to take' => sub {
	my ($terminal, $output) = terminal("g4\rg7\rb4\r", game => mill_game());
	$terminal->enter_raw;
	$terminal->pick;
	is($terminal->game->history->[-1]->notation, 'g4-g7xb4', 'three steps, one move');
	is($terminal->frames, 6, 'six screens: one on arriving at each step and one after each jump');

	my $screen = ${$output};
	like($screen, qr/^Choose a man to move\.$/m, 'first it asks for the man');
	like($screen, qr/^Move g4 to where\?$/m, 'then where it goes');
	like($screen, qr/^Move g4 to g7 and take which man\?$/m, 'then, the move closing a mill, which man');
	like($screen, qr/^ > g7, closes a mill   \d of \d$/m, 'and it said the mill would close while that could still be declined');
};

subtest 'what the board shows at each step' => sub {
	my ($terminal, $output) = terminal("g4\r", game => mill_game());
	$terminal->enter_raw;
	$terminal->pick;
	my @frames = split /^(?=7 [ (\[{<])/m, ${$output};
	like($frames[1], qr/^4 .*\[W\]/m, 'choosing the man: brackets on the man under the cursor');
	unlike($frames[1], qr/[{<]/, 'and nothing chosen or takeable yet');

	my ($at_to, $to_output) = terminal("g4\rg7", game => mill_game());
	$at_to->enter_raw;
	$at_to->pick;
	my $frame = last_frame($to_output);
	like($frame, qr/^7  W-----------W----------\[W\]$/m, 'choosing where: the man is drawn ON g7, as if played');
	like($frame, qr/^4 .*\(\.\)/m, 'and gone from g4, which is marked as the point left');
	like($frame, qr/\{B\}/, 'the men that closing would let it take are marked at once');
	is(scalar(() = $frame =~ m/\{B\}/g), 2, 'b4 and e5, the two outside the black mill');
	unlike($frame, qr/^1 .*\{B\}/m, 'and not the three in it');

	my ($at_take, $take_output) = terminal("g4\rg7\r", game => mill_game());
	$at_take->enter_raw;
	$at_take->pick;
	$frame = last_frame($take_output);
	like($frame, qr/^7  W-----------W----------<W>$/m, 'choosing the man to take: the move so far is marked as chosen');
	like($frame, qr/^5 .*\[B\]/m, 'the cursor is on the first man that can be taken, e5');
	like($frame, qr/^4 .*\{B\}/m, 'and the other, b4, is still marked takeable');
	like($frame, qr/^ > e5, takes this man   1 of 2$/m, 'with the readout saying what enter will do');
	is($at_take->game->ply, 0, 'and through all of it nothing has been played');
	is($at_take->game->board->side_at(p('g4')), 'white', 'the real board still has the man on g4');
};

subtest 'a flight is called one before it is made' => sub {
	my $position = position_of(white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2 c3/]);
	my ($terminal, $output) = terminal("a7\re3", game => Game::Merrills->new(position => $position));
	$terminal->enter_raw;
	$terminal->pick;
	like(last_frame($output), qr/^ > e3, a flight   \d+ of 17$/m, 'a7 to e3 is not along a line, and the readout says so');

	my ($step, $stepped) = terminal("a7\rd7", game => Game::Merrills->new(position => $position));
	$step->enter_raw;
	$step->pick;
	like(last_frame($stepped), qr/^ > d7   \d+ of 17$/m, 'a7 to d7 is, and it does not');
};

subtest 'backspace goes back a step, and says so when there is none' => sub {
	my ($terminal, $output) = terminal("\x7fg4\rg7\r\x7f\x7fc3\rc4\r", game => mill_game());
	$terminal->enter_raw;
	$terminal->pick;
	like(${$output}, qr/^There is nothing to go back over\.$/m, 'at the first step there is nothing behind');
	is($terminal->game->history->[-1]->notation, 'c3-c4', 'two steps in and two back out, another move altogether is played');

	my ($escape) = terminal("g4\r\e\ec3\rc4\r", game => mill_game());
	$escape->enter_raw;
	$escape->pick;
	is($escape->game->history->[-1]->notation, 'c3-c4', 'escape goes back as backspace does');

	my ($kept, $screen) = terminal("g4\rg7\r\x7f", game => mill_game());
	$kept->enter_raw;
	$kept->pick;
	like(last_frame($screen), qr/^ > g7, closes a mill/m, 'going back puts the cursor on the point just un-chosen');

	my ($man, $men) = terminal("e3\r\x7f", game => mill_game());
	$man->enter_raw;
	$man->pick;
	like(last_frame($men), qr/^ > e3   \d of \d$/m, 'and on the man just un-chosen, not back on the first of them');
};

sub walk {
	my ($terminal, $choose) = @_;
	my @prefix;
	for (1 .. 4) {
		my $options = $terminal->options_for(\@prefix);
		return undef unless @{$options};
		push @prefix, $options->[ $choose->(scalar @{$options}) ];
		my $move = $terminal->complete(\@prefix);
		return $move if $move;
	}
	return undef;
}

sub positions {
	my ($seed, $want) = @_;
	my $next = stream($seed);
	my (@games, %phase);
	my $tries = 0;
	while (@games < $want && $tries++ < 20 * $want) {
		my $game = Game::Merrills->new;
		my $stop = $next->(80);
		while ($game->status eq 'active' && $game->ply < $stop) {
			my $legal = $game->legal_moves;
			$game->move($legal->[ $next->(scalar @{$legal}) ]);
		}
		next unless $game->status eq 'active';
		push @games, $game;
		$phase{ $game->phase }++;
	}
	return (\@games, \%phase);
}

subtest 'first, last and middle: every walk ends on a legal move, over 200 positions' => sub {
	my ($games, $phase) = positions(2222, 200);
	is(scalar @{$games}, 200, 'two hundred positions');
	cmp_ok($phase->{$_} || 0, '>', 5, "$_: " . ($phase->{$_} || 0)) for qw/placing moving flying/;

	my %walk = (
		first => sub { 0 },
		last => sub { $_[0] - 1 },
		middle => sub { int($_[0] / 2) },
	);
	for my $name (sort keys %walk) {
		my ($ended, $legal, $captures) = (0, 0, 0);
		for my $game (@{$games}) {
			my ($terminal) = terminal('', game => $game);
			my $move = walk($terminal, $walk{$name}) or next;
			$ended++;
			$legal++ if grep { $_ == $move } @{ $game->legal_moves };
			$captures++ if $move->is_capture;
		}
		is($ended, 200, "$name option at every step: all 200 walks end on a move");
		is($legal, 200, 'and each is an object out of the game\'s own list of legal moves');
		note "$name: $captures of the 200 took a man";
	}
};

subtest 'every legal move can be chosen, and nothing else can, over 50 positions' => sub {
	my ($games) = positions(5050, 50);
	my ($wrong, $moves, $longest) = (0, 0, 0);
	for my $game (@{$games}) {
		my ($terminal) = terminal('', game => $game);
		my %reached;
		my @todo = ([]);
		while (my $prefix = shift @todo) {
			if (my $move = $terminal->complete($prefix)) {
				$reached{ $move->notation }++;
				next;
			}
			my $options = $terminal->options_for($prefix);
			$wrong++ unless @{$options};
			$longest = @{$options} if @{$options} > $longest;
			push @todo, map { [ @{$prefix}, $_ ] } @{$options};
		}
		my %legal = map { $_->notation => 1 } @{ $game->legal_moves };
		$moves += keys %legal;
		$wrong++ unless join(' ', sort keys %reached) eq join(' ', sort keys %legal);
		$wrong++ if grep { $_ != 1 } values %reached;
	}
	cmp_ok($moves, '>', 500, "$moves legal moves in all");
	is($wrong, 0, 'each reached by exactly one run of choices, with no dead end and no stranger');
	cmp_ok($longest, '<=', 24, "and no step ever offers more than $longest points");
};

subtest 'an arrow never lands off the points on offer, and tab reaches them all' => sub {
	my ($games) = positions(808, 200);
	my ($asked, $stray, $unreached) = (0, 0, 0);
	for my $game (@{$games}) {
		my ($terminal) = terminal('', game => $game);
		my @prefix;
		for (1 .. 3) {
			my $options = $terminal->options_for(\@prefix);
			last unless @{$options};
			my %on_offer = map { $_ => 1 } @{$options};
			for my $at (@{$options}) {
				for my $direction (qw/up down left right/) {
					$asked++;
					$stray++ unless $on_offer{ $terminal->nearest($at, $direction, $options) };
				}
			}
			push @prefix, $options->[ @{$options} / 2 ];
			last if $terminal->complete(\@prefix);
		}

	}
	cmp_ok($asked, '>', 5000, "$asked arrow presses");
	is($stray, 0, 'every one landed on a point that could be chosen');

	my ($terminal, $output) = terminal("\t" x 24);
	$terminal->enter_raw;
	$terminal->pick;
	my @seen = ${$output} =~ m/^ > ([a-g][1-7])   \d+ of 24$/mg;
	is(scalar @seen, 25, 'twenty-four tabs draw twenty-five screens');
	is(scalar(keys %{ { map { $_ => 1 } @seen } }), 24, 'which between them put the cursor on all 24 points');
	is($seen[-1], $seen[0], 'and come back round to the first');
};

subtest 'a hint moves the cursor to the move, step by step' => sub {
	my $expected = Game::Merrills::Bot->new->choose(mill_game())->notation;
	my ($terminal, $output) = terminal("h\r\r\r", game => mill_game());
	$terminal->enter_raw;
	$terminal->pick;
	like(${$output}, qr/^Try \Q$expected\E \(it scores that [+-]\d+\.\d\d\)\.$/m, 'the hint is shown on the screen');
	is($terminal->game->history->[-1]->notation, $expected,
		"and enter at each step, with no arrow touched, plays it: $expected");

	my ($first_part) = $expected =~ m/^([a-g][1-7])/;
	my ($other) = grep { $_ ne $first_part } qw/a7 c3 e3/;
	my ($moved_off) = terminal("$other\rh\r\r\r", game => mill_game());
	$moved_off->enter_raw;
	$moved_off->pick;
	is($moved_off->game->history->[-1]->notation, $expected, 'asked for part way into another move, it starts the move again');
};

subtest 'keys that are commands, and keys that are not' => sub {
	for my $case ([ u => 'undo' ], [ t => 'type' ], [ q => 'quit' ]) {
		my ($terminal) = terminal($case->[0]);
		$terminal->enter_raw;
		is($terminal->pick, $case->[1], "$case->[0] hands back $case->[1]");
		is_deeply($terminal->highlight, {}, 'with the board cleaned up behind it');
	}

	my ($typed, $output) = terminal(":resign\r");
	$typed->enter_raw;
	is($typed->pick, 'resign', 'a colon reads a command a key at a time');
	like(${$output}, qr/^: resign$/m, 'echoing it as it goes');

	my ($rubbed) = terminal(":rex\x7fsign\r");
	$rubbed->enter_raw;
	is($rubbed->pick, 'resign', 'and backspace rubs a letter out');

	my ($help, $said) = terminal("?z");
	$help->enter_raw;
	is($help->pick, undef, 'running out of keys ends the choosing');
	like(${$said}, qr/^The arrow keys move to the nearest point/m, '? puts the keys on the screen');
	like(${$said}, qr/^That key does nothing here\. Press \? for the ones that do\.$/m, 'and a key that does nothing says so');

	my ($stopped) = terminal("\x03");
	$stopped->enter_raw;
	is($stopped->pick, undef, 'an interrupt ends the choosing');
	my ($ended) = terminal("\x04");
	$ended->enter_raw;
	is($ended->pick, undef, 'and so does the end of the input');
	is($ended->game->ply, 0, 'with nothing played');
};

subtest 'a whole session on the keys: one board a screen, and the story stays on it' => sub {
	my ($terminal, $output) = terminal("\r" x 30);
	my $result = $terminal->start;
	cmp_ok($terminal->game->ply, '>=', 15, 'thirty enters play ' . $terminal->game->ply
		. ' moves: one each while placing, two or three once men move or a mill closes');
	is(boards($output), $terminal->frames, 'a board is drawn once for each choosing screen and never between');
	cmp_ok($terminal->frames, '>=', 31, 'at least a screen a move and one more: ' . $terminal->frames);
	like(${$output}, qr/Bye\.\n\z/, 'and running out of keys says goodbye');
	ok(!$terminal->raw, 'leaving the terminal as it was found');

	my @frames = split /^(?=7 [ (\[{<])/m, ${$output};
	my $told = grep { m/^(?:White|Black) (?:placed|moved|flew) /m } @frames[ 2 .. $#frames ];
	is($told, @frames - 2, 'every screen after the first move tells the move it answers');
	like($frames[2], qr/^White placed a man on a7\.$/m, 'in words, in the past tense');
};

subtest 'against a bot: its move is told on the screen that answers it' => sub {
	my ($terminal, $output) = terminal("\r\r", human => 'white', bot => Game::Merrills::Bot->new(level => 1, seed => 3));
	$terminal->start;
	is($terminal->game->ply, 4, 'two moves of yours and two replies');
	my $reply = $terminal->game->history->[1]->notation;
	like(last_frame($output), qr/^Black placed a man on \w\w\.$/m, 'the last screen tells what black just did');
	like(${$output}, qr/^You placed a man on a7\.\nBlack placed a man on \Q$reply\E\.$/m,
		'and before it, what you did that it was answering');
	is(boards($output), $terminal->frames, 'still one board a screen');
};

subtest 'undo from the keys, and the word that it was done survives the next screen' => sub {
	my ($terminal, $output) = terminal("\r\ru");
	$terminal->start;
	is($terminal->game->to_text, "1. a7\n", 'two moves, then u takes one back');
	like(last_frame($output), qr/^Taken back\.$/m, 'and the next choosing screen says so');
	is(boards($output), $terminal->frames, 'with no board drawn in between to be wiped');
};

subtest 'two bots, with keys on offer that nobody is there to press' => sub {
	my ($terminal, $output) = terminal('', human => 'none', bot => {
		white => Game::Merrills::Bot->new(level => 1, seed => 1),
		black => Game::Merrills::Bot->new(level => 1, seed => 2),
	});
	local $SIG{ALRM} = sub { die "the game did not end\n" };
	alarm 60;
	$terminal->start;
	alarm 0;
	is($terminal->game->status, 'finished', 'the game is played out');
	is($terminal->frames, 0, 'no choosing screen is drawn');
	is(boards($output), $terminal->game->ply + 1, 'and the board is drawn every ply, as it is when typing');
};

subtest 'switching to typing and back' => sub {
	my ($terminal, $output) = terminal("\rt\r", typed => "f4\npick\n");
	$terminal->start;
	is($terminal->game->to_text, "1. a7 f4\n2. d7\n", 'a key, then t, a typed move, pick, and a key again');
	like(${$output}, qr/^Type your moves\. The command pick brings the keys back\.$/m, 't says what it has done');
	like(${$output}, qr/^black> f4$/m, 'and the typed move was read at a prompt');

	my ($untyped) = terminal('', picking => 0, typed => "d2\n");
	$untyped->start;
	is($untyped->game->to_text, "1. d2\n", 'with picking off from the start, moves are typed');
	is($untyped->frames, 0, 'and no choosing screen is ever drawn');
};

subtest 'without keys to read, picking is off' => sub {
	my $output = '';
	open my $out, '>', \$output or die $!;
	open my $in, '<', \"d2\n" or die $!;
	my $terminal = Game::Merrills::Terminal->new(in => $in, out => $out, human => 'both', ascii => 1);
	ok(!$terminal->picking, 'not a terminal, no key source: picking is off');
	ok(!Game::Merrills::Terminal->new(in => $in, out => $out, picking => 1)->picking,
		'and asking for it does not turn it on, there being no keys to read');
	ok(!$terminal->keys_available, 'and keys are not available');
	is($terminal->pick, undef, 'pick does nothing');
	$terminal->start;
	is($terminal->game->to_text, "1. d2\n", 'and the game is typed');
	$terminal->command('pick');
	like($output, qr/^This terminal cannot be read a key at a time\.$/m, 'asking for the keys says why not');
};

subtest 'the choosing screen in colour' => sub {
	my ($terminal, $output) = terminal("g4\rg7", game => mill_game(), colour => 1, ascii => 0);
	$terminal->enter_raw;
	$terminal->pick;
	my $frame = ${$output};
	my %ground = %Game::Merrills::Terminal::GROUND;
	my %ink = %Game::Merrills::Terminal::INK;
	like($frame, qr/\Q$ground{option}\Em/, 'points that could be chosen have a ground of their own');
	like($frame, qr/\Q$ground{candidate}\Em/, 'the cursor has another');
	like($frame, qr/\Q$ground{takeable}\Em/, 'and the men that could be taken a third');
	like($frame, qr/\Q$ink{cursor}\Em> g7/, 'the readout is painted');
	like($frame, qr/\Q$ink{step}\EmMove g4 to where\?/, 'and so is the question');
	like($frame, qr/\Q$ink{key}\Emarrows/, 'and the keys in the legend');
	my %seen = map { $_ => 1 } values %ground;
	is(scalar keys %seen, scalar keys %ground, 'no two grounds are the same colour');
	is(scalar(grep { m/\e\[/ && (m/.*(\e\[[0-9;]*m)/s)[0] ne "\e[0m" } split /\n/, $frame), 0,
		'and every painted line puts the colour back');
};

done_testing;
