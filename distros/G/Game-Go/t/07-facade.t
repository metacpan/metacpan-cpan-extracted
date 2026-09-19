#!perl

# The facade: the turn, the legal-move list, the log, and the four ways a game
# can stop without being scored.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Move;
use Game::Go::Error;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

subtest 'a new game, and what it refuses to be' => sub {
	my $g = Game::Go->new(size => 9);
	is($g->size, 9, 'size');
	is($g->komi, 6.5, 'komi defaults to 6.5');
	is($g->handicap, 0, 'no handicap');
	is($g->status, 'active', 'active');
	is($g->phase, 'play', 'and playing rather than being counted');
	is($g->turn, $B, 'black first, which is Article 2');
	is_deeply([ $g->seats ], [ $B, $W ], 'two seats');
	is_deeply([ $g->waiting_on ], [ $B ], 'waiting on black');

	# A bad argument is programmer error and dies. A refused MOVE is a value.
	ok(!eval { Game::Go->new(size => 10); 1 }, 'a size off the list dies');
	like($@, qr/9, 13 or 19/, 'saying which sizes there are');
	ok(!eval { Game::Go->new(size => 9, komi => 6.25); 1 }, 'a komi off the half point dies');
	ok(!eval { Game::Go->new(size => 9, handicap => 12); 1 }, 'and a handicap above what the board takes');

	# When this file was written the handicap was accepted and croaked, because
	# the traditional placements had not been cited yet. They have been since,
	# so these now build; the cap is a property of the BOARD, since only 19x19
	# has nine star points. t/16-handicap.t is where all of that is asserted.
	ok(eval { Game::Go->new(size => 9, handicap => 1); 1 }, 'a handicap of 1 is fine');
	ok(eval { Game::Go->new(size => 9, handicap => 5); 1 }, 'and five on a small board');
	ok(!eval { Game::Go->new(size => 9, handicap => 6); 1 }, 'but not six, which has nowhere to go');

	for my $size (Game::Go->sizes) {
		ok(eval { Game::Go->new(size => $size); 1 }, "size $size is offered");
	}
	done_testing();
};

subtest 'the log starts with what the game is' => sub {
	my $g = Game::Go->new(size => 13, komi => 6.5);
	my $events = $g->events;
	is(scalar @$events, 1, 'one event to begin with');
	is($events->[0]{actor}, 'sys', 'from the system');
	is($events->[0]{kind}, 'start', 'and it is the start');
	is($events->[0]{payload}{size}, 13, 'carrying the size');
	is($events->[0]{payload}{komi}, 6.5, 'the komi');
	is($events->[0]{payload}{handicap}, 0, 'the handicap');
	is($events->[0]{payload}{first}, 'b', 'and who moves first');

	# events() is a COPY. A caller that edited the log it was handed would be
	# editing the game, and the log is the game.
	$events->[0]{kind} = 'tampered';
	is($g->events->[0]{kind}, 'start', 'and the copy handed out is not the log itself');
	done_testing();
};

subtest 'the legal list, and the pass that is always in it' => sub {
	my $g = Game::Go->new(size => 9);
	my $moves = $g->legal($B);
	is(scalar @$moves, 82, '81 points and a pass on an empty 9x9');
	is(scalar(grep { $_->kind eq 'pass' } @$moves), 1, 'exactly one pass');
	is(scalar(grep { $_->kind eq 'play' } @$moves), 81, 'and 81 plays');

	# A PASS IS ALWAYS OFFERED, which is the opposite of the previous game the
	# house built: Reversi's pass is forced, automatic, never offered and
	# refused if posted. Here it is a move a player makes on purpose, and it
	# is the only way a game ever reaches a score, so a list without one
	# would describe a game that cannot end.
	isa_ok($moves->[-1], 'Game::Go::Move', 'the moves are objects');
	is($moves->[-1]->kind, 'pass', 'and the pass comes last');

	is_deeply($g->legal($W), [], 'the other colour is offered nothing off turn');
	is_deeply($g->legal(Game::Go::EMPTY), [], 'and EMPTY is not a player');
	done_testing();
};

subtest 'playing, and the turn going round' => sub {
	my $g = Game::Go->new(size => 9);
	my $pt = $g->point(3, 3);

	my $m = $g->play($B, $pt);
	isa_ok($m, 'Game::Go::Move', 'a play returns a move');
	is($m->kind, 'play', 'of kind play');
	is($m->point, $pt, 'at the point asked for');
	is($m->captured, 0, 'taking nothing');
	is($g->turn, $W, 'and the turn passes');
	is($g->board->at(3, 3), $B, 'the stone is on the board');

	# A REFUSED MOVE IS A VALUE, NOT A DEATH.
	my $again = $g->play($B, $g->point(4, 4));
	isa_ok($again, 'Game::Go::Error', 'playing out of turn');
	is($again->code, 'not_your_turn', 'says so');
	ok($again->error, 'and is flagged as an error');
	is($g->turn, $W, 'with the turn where it was');

	my $taken = $g->play($W, $pt);
	isa_ok($taken, 'Game::Go::Error', 'playing on a stone');
	is($taken->code, 'point_taken', 'says so');

	my $off = $g->play($W, 100000);
	isa_ok($off, 'Game::Go::Error', 'playing off the board');
	is($off->code, 'off_board', 'says so');

	is($g->play($W, $g->point(4, 4))->kind, 'play', 'and a real move still works');
	done_testing();
};

subtest 'points, and the boundary a caller has to cross' => sub {
	my $g = Game::Go->new(size => 9);
	my $pt = $g->point(2, 5);
	is_deeply([ $g->col_row($pt) ], [ 2, 5 ], 'a point round-trips');
	is($g->point(-1, 0), -1, 'off the board is -1');
	is($g->point(9, 0), -1, '...');

	# A POINT IS NOT row * size + col, and this is the assertion that says so.
	# The board is padded with a sentinel ring so the engine's neighbour walk
	# needs no bounds test, which makes the index opaque.
	isnt($pt, 5 * 9 + 2, 'and it is not row * size + col');
	done_testing();
};

subtest 'prisoners are derived from the log' => sub {
	# Black takes the corner:
	#   B (1,0), W (0,0), B (0,1) and the white stone has no liberty left.
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(1, 0));
	$g->play($W, $g->point(0, 0));
	my $m = $g->play($B, $g->point(0, 1));

	is($m->captured, 1, 'one stone comes off');
	is_deeply([ $g->col_row($m->caps->[0]) ], [ 0, 0 ], 'and it is the corner');
	is($g->board->at(0, 0), Game::Go::EMPTY, 'which is now empty');

	my $p = $g->prisoners;
	is($p->{$B}, 1, 'black holds one prisoner');
	is($p->{$W}, 0, 'white holds none');

	# Derived rather than kept, because the log is the game. A position
	# cannot say how many prisoners each side holds, and under Article 10.2
	# the prisoner counts are half the score.
	is(scalar @{ $g->events }, 4, 'and it came out of four events');
	done_testing();
};

subtest 'two passes stop play and do not end the game' => sub {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));
	$g->pass($W);
	is($g->phase, 'play', 'one pass is just a move');
	is($g->status, 'active', '...');

	$g->play($B, $g->point(4, 4));
	$g->pass($W);
	is($g->phase, 'play', 'and a pass with a move in between is not two in a row');

	$g->pass($B);
	# Article 9.1: "When a player passes his move and his opponent passes in
	# succession, the game STOPS." Article 9.2 is what ends it, and that is
	# the confirmation phase.
	is($g->phase, 'marking', 'two in succession stop play');
	is($g->status, 'active', 'AND THE GAME IS STILL ACTIVE, because stopping is not ending');

	my $last = $g->events->[-1];
	is($last->{kind}, 'stop', 'the log says so');
	is($last->{actor}, 'sys', 'as a system event');

	# NO STONE IS LEGAL WHILE THE GAME IS BEING COUNTED, and that is what this
	# asserts rather than an empty list. When this file was written the
	# confirmation phase had no moves at all and `[]` was the whole truth; it
	# now offers marks and answers, so the assertion is about KINDS. Checking
	# emptiness here would have started failing the moment the phase acquired
	# its own moves, which is a test asserting the absence of a feature.
	my %kinds;
	$kinds{ $_->kind }++ for @{ $g->legal($W) }, @{ $g->legal($B) };
	is($kinds{play}, undef, 'no play is offered to either colour');
	is($kinds{pass}, undef, 'and no pass');
	ok(scalar keys %kinds, 'while the confirmation phase does offer something (' .
		join(', ', sort keys %kinds) . ')');

	my $e = $g->play($W, $g->point(5, 5));
	isa_ok($e, 'Game::Go::Error', 'and a posted stone');
	is($e->code, 'still_marking', 'is refused for being in the wrong phase');

	# The reason that matters: a player told about liberties when the truth
	# is that the game is over has been told the wrong thing.
	like($e->message, qr/being scored/, 'with a message about scoring, not about liberties');
	done_testing();
};

subtest 'resigning' => sub {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));

	is($g->resign($W), 'resign', 'white resigns');
	is($g->status, 'finished', 'the game is over');
	is($g->winner, $B, 'black won');
	is($g->result, 'resign', 'by resignation');
	is($g->turn, undef, 'and nobody is to move');
	is_deeply([ $g->waiting_on ], [], 'nobody is waited on');
	is_deeply($g->legal($B), [], 'and nothing is legal');

	my $e = $g->play($B, $g->point(4, 4));
	is($e->code, 'game_over', 'a move after the end is refused');
	is($g->resign($B)->code, 'game_over', 'and so is a second resignation');

	my $end = $g->events->[-1];
	is($end->{kind}, 'game_end', 'the log ends with the end');
	is($end->{payload}{winner}, 'b', 'naming the winner');
	is($end->{payload}{result}, 'resign', 'and how');
	done_testing();
};

subtest 'timeout and abandon are the site talking' => sub {
	# Nothing in the rules of Go knows about a clock or a player walking away.
	# These are here because the log has to carry them and a replay has to
	# reproduce them.
	my $t = Game::Go->new(size => 9);
	is($t->timeout($B), 'timeout', 'black times out');
	is($t->winner, $W, 'white wins');
	is($t->status, 'finished', '...');
	is($t->events->[-2]{kind}, 'timeout', 'and the log records it');
	is($t->events->[-2]{payload}{p}, 'b', 'naming who was late');

	my $a = Game::Go->new(size => 9);
	is($a->abandon, 'abandoned', 'a game is abandoned');
	is($a->winner, undef, 'with NO winner, which is the whole problem with it');
	is($a->result, 'abandoned', '...');
	is($a->events->[-1]{payload}{winner}, undef, 'and the log says so');
	done_testing();
};

subtest 'the seed is not published until the game is over' => sub {
	my $g = Game::Go->new(size => 9, seed => 'k' x 32);
	is($g->seed, undef, 'no seed while the game is running');
	$g->resign($W);
	is($g->seed, 'k' x 32, 'and the seed once it is finished');

	# That is what lets a site publish the seed at the end so anybody can
	# re-verify a bot's play, without it being readable while the game is on.
	done_testing();
};

subtest 'the board view speaks in columns and rows' => sub {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(0, 0));
	$g->play($W, $g->point(8, 8));

	my $b = $g->board;
	isa_ok($b, 'Game::Go::Board');
	is($b->size, 9, 'size');
	is($b->at(0, 0), $B, 'black in the top left');
	is($b->at(8, 8), $W, 'white in the bottom right');
	is($b->at(4, 4), Game::Go::EMPTY, 'empty in the middle');
	is($b->at(-1, 0), Game::Go::BORDER, 'and off the board is BORDER');
	is($b->libs(0, 0), 2, 'a corner stone has two liberties');
	is($b->stones($B), 1, 'one black stone');
	is($b->empties, 79, 'and 79 empty points');

	is_deeply($b->chain_at(0, 0), [ [ 0, 0 ] ], 'a chain comes back as col/row pairs');
	is_deeply($b->chain_at(4, 4), [], 'and an empty point has none');

	my @lines = split /\n/, $b->to_text;
	is(scalar @lines, 9, 'to_text has a line per row');
	is(substr($lines[0], 0, 1), 'X', 'black reads as X');
	is(substr($lines[8], 8, 1), 'O', 'white as O');
	is(substr($lines[4], 4, 1), '.', 'and empty as a dot');
	done_testing();
};

subtest 'a Move knows what it may carry' => sub {
	# Cheap here, and expensive to find in a replay three phases later.
	ok(!eval { Game::Go::Move->new(kind => 'nonsense', colour => $B); 1 },
		'a kind that does not exist dies');
	ok(!eval { Game::Go::Move->new(kind => 'pass', colour => $B, point => 5); 1 },
		'a pass with a point dies');
	ok(!eval { Game::Go::Move->new(kind => 'play', colour => $B); 1 },
		'a play with no point dies');
	ok(!eval { Game::Go::Move->new(kind => 'play', point => 5); 1 },
		'a move with no colour dies');
	ok(!eval { Game::Go::Move->new(kind => 'pass', colour => $B, caps => [1]); 1 },
		'only a play captures');

	my $m = Game::Go::Move->new(kind => 'play', colour => $B, point => 5, caps => [7, 8]);
	is($m->captured, 2, 'a play may capture');
	ok($m->is_play, 'is_play');
	ok(!$m->is_pass, 'not is_pass');
	like($m->stringify, qr/black/, 'and it reads as a sentence');
	done_testing();
};

done_testing();
