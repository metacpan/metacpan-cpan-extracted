#!perl

# Replay, and what makes a forged log detectable.
#
# THE RULE THIS FILE ENFORCES: player events are handed back to the method that
# made them and must be accepted; `sys timeout` and `sys abandon` are APPLIED,
# because the engine cannot derive a clock or a walk-out; and every other `sys`
# event is REGENERATED AND COMPARED. A log the engine does not reproduce is a
# log that cannot be trusted.
#
# It matters more here than in any other game the house has built, because for
# Go the log is not merely the convenient serialisation. A position cannot say
# what the ko point is, and it cannot say how many prisoners each side holds,
# which under Article 10.2 is half the score. There is nothing else to replay
# FROM.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# A short game with a capture in it, so a replay has prisoners to get wrong.
#   B (1,0), W (0,0), B (0,1) takes the corner, W passes, B plays away.
sub played {
	my $g = Game::Go->new(size => 9, seed => 'r' x 32);
	$g->play($B, $g->point(1, 0));
	$g->play($W, $g->point(0, 0));
	$g->play($B, $g->point(0, 1));
	$g->pass($W);
	$g->play($B, $g->point(5, 5));
	return $g;
}

subtest 'a game replays to the same game' => sub {
	my $g = played();
	is($g->prisoners->{$B}, 1, 'the original took a prisoner');

	my $r = Game::Go->new(size => 9, seed => 'r' x 32);
	my $n = $r->replay($g->events);
	is($n, scalar @{ $g->events }, 'every event was seen');

	is($r->board->to_text, $g->board->to_text, 'the same position');
	is($r->turn, $g->turn, 'the same turn');
	is($r->status, $g->status, 'the same status');
	is($r->phase, $g->phase, 'the same phase');
	is_deeply($r->prisoners, $g->prisoners, 'and the same prisoners');

	# The replayed game's own log must be the log it was given, or the next
	# replay of THAT log would diverge.
	is_deeply($r->events, $g->events, 'and its log came out the same');
	done_testing();
};

subtest 'a truncated log replays to where it stops' => sub {
	my $g = played();
	my $all = $g->events;
	my @short = @$all[0 .. 2];      # start, the first play, the second play

	my $r = Game::Go->new(size => 9);
	$r->replay(\@short);
	is($r->board->at(1, 0), $B, 'the first stone is there');
	is($r->board->at(0, 0), $W, 'and the second');
	is($r->board->at(0, 1), Game::Go::EMPTY, 'and the third is not');
	is($r->turn, $B, 'with black to move');
	is($r->status, 'active', 'and the game still running');
	done_testing();
};

subtest 'a player event that is not legal is refused' => sub {
	# Changing a play to an occupied point makes a log that describes a game
	# that could not have happened.
	my $g = played();
	my $bad = $g->events;
	$bad->[3]{payload}{pt} = $bad->[1]{payload}{pt};    # play on top of the first stone

	my $r = Game::Go->new(size => 9);
	ok(!eval { $r->replay($bad); 1 }, 'the replay refuses it');
	like($@, qr/was refused/, 'saying the log was refused');
	like($@, qr/already a stone/, 'and why');
	done_testing();
};

subtest 'a forged sys event is refused' => sub {
	# THE ONE THAT MATTERS. A `sys stop` claims play ended, which is what opens
	# the confirmation phase and therefore what leads to a score. Anyone who
	# could insert one could end a game at a moment of their choosing.
	my $g = played();
	my $forged = $g->events;
	splice @$forged, 3, 0, { actor => 'sys', kind => 'stop', payload => {} };

	my $r = Game::Go->new(size => 9);
	ok(!eval { $r->replay($forged); 1 }, 'a stop the engine never produced is refused');
	like($@, qr/did not produce/, 'and says that is what happened');

	# A forged start, which would let a log claim a different board.
	my $g2 = played();
	my $lie = $g2->events;
	$lie->[0]{payload}{size} = 19;
	my $r2 = Game::Go->new(size => 9);
	ok(!eval { $r2->replay($lie); 1 }, 'a start that disagrees about the size is refused');
	like($@, qr/disagrees about size/, 'naming the field');

	# A forged komi, which would change the score without changing a stone.
	my $g3 = played();
	my $komi = $g3->events;
	$komi->[0]{payload}{komi} = 0.5;
	my $r3 = Game::Go->new(size => 9);
	ok(!eval { $r3->replay($komi); 1 }, 'and one that disagrees about the komi');
	done_testing();
};

subtest 'a forged ending is refused' => sub {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));
	$g->resign($W);
	is($g->winner, $B, 'black won by resignation');

	my $lie = $g->events;
	$lie->[-1]{payload}{winner} = 'w';      # claim the other player won

	my $r = Game::Go->new(size => 9);
	ok(!eval { $r->replay($lie); 1 }, 'a game_end naming the wrong winner is refused');
	like($@, qr/disagrees about winner/, 'naming the field');
	done_testing();
};

subtest 'timeout and abandon are applied, not regenerated' => sub {
	# The engine cannot derive a clock, so there is nothing to compare these
	# against. Refusing them would make every timed-out game unreplayable,
	# which on a correspondence site is a large fraction of them.
	my $t = Game::Go->new(size => 9);
	$t->play($B, $t->point(3, 3));
	$t->timeout($W);

	my $r = Game::Go->new(size => 9);
	ok(eval { $r->replay($t->events); 1 }, 'a timed-out game replays') or diag $@;
	is($r->status, 'finished', 'and is finished');
	is($r->winner, $B, 'with the same winner');
	is($r->result, 'timeout', 'by the same result');

	my $a = Game::Go->new(size => 9);
	$a->play($B, $a->point(3, 3));
	$a->abandon;

	my $r2 = Game::Go->new(size => 9);
	ok(eval { $r2->replay($a->events); 1 }, 'an abandoned game replays') or diag $@;
	is($r2->winner, undef, 'with no winner');
	is($r2->result, 'abandoned', '...');
	done_testing();
};

subtest 'a log that is not a log' => sub {
	my $r = Game::Go->new(size => 9);
	ok(!eval { $r->replay({}); 1 }, 'a hashref is not a log');
	ok(!eval { $r->replay([ { actor => 'q', kind => 'play', payload => {} } ]); 1 },
		'an actor that is not a player is refused');
	ok(!eval { $r->replay([ { actor => 'b', kind => 'wibble', payload => {} } ]); 1 },
		'and a player event of a kind that does not exist');
	done_testing();
};

subtest 'two passes replay into the confirmation phase' => sub {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));
	$g->pass($W);
	$g->pass($B);
	is($g->phase, 'marking', 'the original stopped');

	my $r = Game::Go->new(size => 9);
	$r->replay($g->events);
	is($r->phase, 'marking', 'and so does the replay');
	is($r->status, 'active', 'still active');

	# The `sys stop` in the log was REGENERATED by the replay's own second
	# pass and then compared, rather than taken on trust. That is the whole
	# mechanism, and this is the case where it does real work.
	is($r->events->[-1]{kind}, 'stop', 'with the stop in its own log');
	done_testing();
};

subtest 'clone is a replay' => sub {
	my $g = played();
	my $c = $g->clone;

	is($c->board->to_text, $g->board->to_text, 'the same position');
	is($c->turn, $g->turn, 'the same turn');
	is_deeply($c->prisoners, $g->prisoners, 'the same prisoners');
	is_deeply($c->events, $g->events, 'and the same log');

	# Independent, or a search that cloned a game would be playing the
	# original's moves.
	$c->play($c->turn, $c->point(7, 7));
	isnt($c->board->to_text, $g->board->to_text, 'and moving in the copy leaves the original alone');
	is(scalar @{ $g->events }, 6, '...');
	done_testing();
};

done_testing();
