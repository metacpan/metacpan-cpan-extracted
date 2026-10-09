#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Error;
use Game::Merrills::Test::Position qw/p position_of stream/;

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

# refused($game, $move, $code, $not, $name): the move is refused with $code,
# is NOT refused with $not, which is the flag it is most easily mistaken for,
# and leaves the game exactly as it was.
sub refused {
	my ($game, $move, $code, $not, $name) = @_;
	subtest $name => sub {
		my $before = $game->to_position;
		my $plies = $game->ply;
		my $error = $game->move($move);
		isa_ok($error, 'Game::Merrills::Error') or return;
		is($error->code, $code, "the code is $code");
		ok($error->$code, "the $code flag is set");
		ok(!$error->$not, "and $not is not");
		is(scalar(grep { $error->$_ } Game::Merrills::Error->flags), 1, 'one flag and one only');
		is($error->message, Game::Merrills::Error->messages->{$code}, 'with its message');
		ok($error->error, 'it answers true to error');
		is($game->to_position, $before, 'the position has not changed');
		is($game->ply, $plies, 'nor the count of moves');
	};
}

my %MEN = (white => [qw/a7 d7 g4 c3 e3/], black => [qw/a1 d1 g1 b4 e5/]);

sub moving { return Game::Merrills->new(position => position_of(%MEN, @_)) }

subtest 'every reason has a message, and they are all different' => sub {
	my @flags = Game::Merrills::Error->flags;
	is(scalar @flags, 14, 'fourteen reasons');
	my $messages = Game::Merrills::Error->messages;
	is_deeply([ sort keys %{$messages} ], [ sort @flags ], 'a message for each and no others');
	my %seen = map { $_ => 1 } values %{$messages};
	is(scalar keys %seen, 14, 'no two the same');
	for my $flag (@flags) {
		unlike($messages->{$flag}, qr/^[A-Z]|\.$/, "$flag has no capital and no full stop");
	}
	$messages->{occupied} = 'changed';
	isnt(Game::Merrills::Error->messages->{occupied}, 'changed', 'messages hands out a copy');
	like(dies { Game::Merrills::Error->throw('nonsense') }, qr/^'nonsense' is not an error flag/,
		'a flag that is not one dies');
	like(dies { Game::Merrills::Error->throw(undef) }, qr/^'undef' is not an error flag/,
		'and so does none');
	is(Game::Merrills::Error->throw('occupied')->stringify, 'that point is not empty',
		'stringify is the message');
	is_deeply(Game::Merrills::Error->throw('occupied')->legal, [], 'legal defaults to an empty list');
};

subtest 'game_over' => sub {
	my $game = Game::Merrills->new;
	$game->resign;
	refused($game, 'd2', 'game_over', 'not_a_move', 'a good move after the end');
	refused($game, 'nonsense', 'game_over', 'not_a_move', 'and nonsense after the end is still game_over');
	is_deeply($game->move('d2')->legal, [], 'with nothing offered instead');
};

subtest 'not_a_move' => sub {
	my $game = Game::Merrills->new;
	refused($game, $_, 'not_a_move', 'not_legal', defined $_ ? "'$_'" : 'undef')
		for undef, '', 'd4', 'd2-', 'pass', 'd2-d2';
	refused($game, [], 'not_a_move', 'not_legal', 'an arrayref');
	refused($game, {}, 'not_a_move', 'not_legal', 'a hashref with no to');
	refused($game, { to => 24 }, 'not_a_move', 'occupied', 'a to off the board');
	refused($game, { to => 'z9' }, 'not_a_move', 'occupied', 'a to that is no coordinate');
	refused($game, { to => 0, from => -1 }, 'not_a_move', 'not_your_man', 'a from off the board');
	refused($game, { to => 0, remove => [] }, 'not_a_move', 'no_man_there', 'a remove that is a reference');
	is(scalar @{ $game->move('nonsense')->legal }, 24, 'the legal moves are offered instead');
};

subtest 'men_in_hand' => sub {
	my $game = Game::Merrills->new;
	$game->move('d2');
	$game->move('f4');
	refused($game, 'd2-d3', 'men_in_hand', 'not_adjacent', 'moving a man while eight are in hand');
	refused($game, 'f4-g4', 'men_in_hand', 'not_your_man', "even the other side's man");
	refused($game, 'a7-g1', 'men_in_hand', 'not_your_man', 'even from an empty point');
};

subtest 'no_men_in_hand' => sub {
	my $game = moving();
	refused($game, 'b6', 'no_men_in_hand', 'not_legal', 'placing with every man down');
	refused($game, 'a7', 'no_men_in_hand', 'occupied', 'even on a point that is taken');
	refused($game, 'g7xb4', 'no_men_in_hand', 'must_remove', 'even where it would close a mill');
};

subtest 'not_your_man' => sub {
	my $game = moving();
	refused($game, 'b6-d6', 'not_your_man', 'not_legal', 'from an empty point');
	refused($game, 'b4-c4', 'not_your_man', 'not_legal', "from one of black's");
	refused($game, 'b4-a7', 'not_your_man', 'occupied', "black's man onto an occupied point");
	refused($game, 'f2-a1', 'not_your_man', 'not_adjacent', 'nobody, going nowhere near');
};

subtest 'occupied' => sub {
	my $game = moving();
	refused($game, 'a7-d7', 'occupied', 'not_legal', 'onto your own man');
	my $blocked = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3 e4/], black => [qw/a1 d1 g1 b4 e5/],
	));
	refused($blocked, 'e4-e5', 'occupied', 'not_adjacent', "onto black's man next door");
	refused($blocked, 'a7-a1', 'occupied', 'not_adjacent', 'occupied is said before too far');

	my $placing = Game::Merrills->new;
	$placing->move('d2');
	refused($placing, 'd2', 'occupied', 'not_legal', "placing on the other side's man");
	$placing->move('f4');
	refused($placing, 'd2', 'occupied', 'not_legal', 'placing on your own');
};

subtest 'not_adjacent' => sub {
	my $game = moving();
	refused($game, 'a7-g7', 'not_adjacent', 'not_legal', 'past a man to the far corner');
	refused($game, 'c3-b6', 'not_adjacent', 'not_legal', 'across the board');
	refused($game, 'c3-b6xb4', 'not_adjacent', 'nothing_to_remove', 'and it is said before anything about the capture');

	my $three = position_of(white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2 c3/]);
	isa_ok(Game::Merrills->new(position => $three)->move('a7-e3'), 'Game::Merrills::Move',
		'a side that flies is not refused');
	refused(Game::Merrills->new(position => $three, flying => 0), 'a7-e3',
		'not_adjacent', 'not_legal', 'and with flying off it is');
};

subtest 'must_remove' => sub {
	my $game = moving();
	refused($game, 'g4-g7', 'must_remove', 'not_legal', 'closing the top row and naming no man');
	my $error = $game->move('g4-g7');
	is_deeply([ map { $_->notation } @{ $error->legal } ], [qw/g4-g7xe5 g4-g7xb4/],
		'the refusal offers that move with each man it could take');

	my $placing = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7/], black => [qw/a1 b4/], hand => { white => 7, black => 7 },
	));
	refused($placing, 'g7', 'must_remove', 'not_legal', 'a placement that closes one');

	my $flying = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 c3/], black => [qw/a1 d2 f4 e5/],
	));
	refused($flying, 'c3-g7', 'must_remove', 'not_adjacent',
		'a flight that closes one: the man flew, so it is not too far, it is unfinished');
};

subtest 'nothing_to_remove' => sub {
	my $game = moving();
	refused($game, 'c3-c4xb4', 'nothing_to_remove', 'not_legal', 'a quiet move that names a man');
	refused($game, 'c3-c4xb6', 'nothing_to_remove', 'no_man_there', 'said before whether a man is there');
	refused($game, 'd7-d6xb4', 'nothing_to_remove', 'man_in_mill', 'stepping out of a row closes nothing');

	my $placing = Game::Merrills->new;
	$placing->move('d2');
	$placing->move('f4');
	refused($placing, 'd6xf4', 'nothing_to_remove', 'not_legal', 'a placement that closes nothing');
};

subtest 'no_man_there' => sub {
	my $game = moving();
	refused($game, 'g4-g7xb6', 'no_man_there', 'man_in_mill', 'taking from an empty point');
	refused($game, 'g4-g7xc3', 'no_man_there', 'not_legal', 'taking your own man');
	refused($game, 'g4-g7xa7', 'no_man_there', 'man_in_mill', 'taking your own man out of the new mill');
};

subtest 'man_in_mill' => sub {
	my $game = moving();
	refused($game, "g4-g7x$_", 'man_in_mill', 'not_legal', "$_ is in black's bottom row")
		for qw/a1 d1 g1/;
	isa_ok($game->clone->move('g4-g7xb4'), 'Game::Merrills::Move', 'b4, outside it, can be taken');

	my $all_safe = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3 e3/], black => [qw/a1 d1 g1/],
	));
	isa_ok($all_safe->move('g4-g7xd1'), 'Game::Merrills::Move',
		'with every black man in the mill, one of them can');
};

subtest 'no_offer and nothing_to_undo' => sub {
	my $game = Game::Merrills->new;
	my $accept = $game->accept_draw;
	is($accept->code, 'no_offer', 'accepting a draw nobody offered');
	ok(!$accept->game_over, 'which is not game_over');
	my $undo = $game->undo;
	is($undo->code, 'nothing_to_undo', 'taking back a move nobody played');
	ok(!$undo->not_legal, 'which is not not_legal');
	is($game->to_position, '........................ w 9 9 0 0', 'and the game is as it began');
};

subtest 'a hashref is a move too, by number or by name' => sub {
	my $game = moving();
	my $by_name = $game->clone->move({ from => 'G4', to => 'g7', remove => 'b4' });
	is($by_name->notation, 'g4-g7xb4', 'coordinates, in either case');
	my $by_number = $game->clone->move({ from => p('g4'), to => p('g7'), remove => p('b4') });
	is($by_number->notation, 'g4-g7xb4', 'point numbers');
	my $undefs = $game->clone->move({ from => p('c3'), to => p('c4'), remove => undef });
	is($undefs->notation, 'c3-c4', 'an undef part is a part that is not there');
	my $object = $game->clone->move($game->legal_moves->[0]);
	is($object->notation, $game->legal_moves->[0]->notation, 'and a Move plays as itself');
	is($game->clone->move({ from => 'g4', to => 'g7' })->code, 'must_remove',
		'a hashref is refused for the same reasons as a string');
};

subtest 'what is played is the legal move itself, never one built from the request' => sub {
	my $game = moving();
	my ($legal) = grep { $_->notation eq 'g4-g7xb4' } @{ $game->legal_moves };
	my $played = $game->move('G4 - G7 x B4');
	is($played, $legal, 'the very object from legal_moves');
	is($game->history->[-1], $legal, 'and it is what the history holds');
	is($played->closes, 1, 'so it knows what the request never said');
};

subtest 'not_legal is never the answer: 20,000 requests, each accepted or refused by name' => sub {
	my $next = stream(1010);
	my ($asked, $accepted, $wrong, $fallback, $changed) = (0, 0, 0, 0, 0);
	my %codes;
	for my $n (1 .. 200) {
		my $game = Game::Merrills->new(flying => $n % 4 ? 1 : 0);
		my $stop = $next->(70);
		while ($game->status eq 'active' && $game->ply < $stop) {
			my $legal = $game->legal_moves;
			$game->move($legal->[ $next->(scalar @{$legal}) ]);
		}
		next unless $game->status eq 'active';
		my %legal = map { $_->notation => 1 } @{ $game->legal_moves };
		my $before = $game->to_position;

		for (1 .. 100) {
			my %want = (to => $next->(24));
			$want{from} = $next->(24) if $next->(3);
			$want{remove} = $next->(24) if $next->(3) == 0;
			my $text = join '', defined $want{from} ? "$want{from}-" : '', $want{to},
				defined $want{remove} ? "x$want{remove}" : '';
			my $key = eval { Game::Merrills::Notation::format_move(\%want) };
			my $trial = $game->clone;
			my $answer = $trial->move(\%want);
			$asked++;
			if (ref $answer eq 'Game::Merrills::Move') {
				$accepted++;
				$wrong++ unless $legal{$key};
			}
			else {
				$wrong++ if $legal{$key};
				$fallback++ if $answer->code eq 'not_legal';
				$codes{ $answer->code }++;
				$changed++ unless $trial->to_position eq $before;
			}
		}
	}
	cmp_ok($asked, '>', 15000, "$asked requests");
	cmp_ok($accepted, '>', 300, "$accepted of them were legal and were played");
	is($wrong, 0, 'accepted exactly when the move is in legal_moves');
	is($fallback, 0, 'and no refusal fell through to not_legal');
	is($changed, 0, 'nor did any refusal change the game');
	for my $code (qw/men_in_hand no_men_in_hand not_your_man occupied not_adjacent
		must_remove nothing_to_remove no_man_there man_in_mill/) {
		cmp_ok($codes{$code} || 0, '>', 0, "$code came up " . ($codes{$code} || 0) . ' times');
	}
};

done_testing;
