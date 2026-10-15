#!perl

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Bot;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

my $SEED = "go\x00\xffseed";

sub apply {
	my ($g, $move) = @_;
	my $kind = $move->kind;
	my $c    = $move->colour;
	return $g->play($c, $move->point)      if $kind eq 'play';
	return $g->pass($c)                    if $kind eq 'pass';
	return $g->mark($c, $move->point)      if $kind eq 'mark' || $kind eq 'unmark';
	return $g->mark_seki($c, $move->point) if $kind eq 'seki' || $kind eq 'unseki';
	return $g->done($c)                    if $kind eq 'done';
	return $g->accept($c)                  if $kind eq 'accept';
	return $g->dispute($c)                 if $kind eq 'dispute';
	die "no such kind '$kind'";
}

sub legal_list {
	my ($g) = @_;
	return [ map {
		my $c = $_;
		map { join ':', $c, $_->kind, ($_->point // '-') } @{ $g->legal($c) }
	} $g->seats ];
}

sub bot_moves {
	my ($g, $n) = @_;
	my $bot = Game::Go::Bot->new(level => 1, seed => 'rt');
	my @seen;
	for (1 .. $n) {
		my ($who) = $g->waiting_on or last;
		my $move = $bot->choose($g, $who) or last;
		push @seen, join ':', $move->colour, $move->kind, ($move->point // '-');
		my $out = apply($g, $move);
		die $out->message if ref $out eq 'Game::Go::Error';
	}
	return \@seen;
}

sub round_trip {
	my ($g, $name) = @_;
	subtest $name => sub {
		my $text = $g->to_text;
		ok(defined $text && !ref $text, 'to_text is a plain string');

		my $l = Game::Go->from_text($text);
		isa_ok($l, 'Game::Go');
		is($l->to_text, $text, 'save(load(save)) is save');
		is_deeply(legal_list($l), legal_list($g), 'the same legal moves');
		is($l->status, $g->status, 'the same status');
		is($l->phase, $g->phase, 'the same phase');
		is($l->turn, $g->turn, 'the same turn');
		is_deeply($l->prisoners, $g->prisoners, 'the same prisoners');
		is($l->ko_point, $g->ko_point, 'the same ko point');
		is($l->board->to_text, $g->board->to_text, 'the same board');

		my $other = Game::Go->from_text($text);
		bot_moves($other, 3);
		is($g->to_text, $text, 'playing on a loaded game leaves the original alone');

		is_deeply(bot_moves(Game::Go->from_text($text), 3), bot_moves($g, 3),
			'the next three bot moves are the same');
		done_testing();
	};
}

subtest 'clone keeps a simple ko rule' => sub {
	my $g = Game::Go->new(size => 9, ko => 'simple', seed => $SEED);
	$g->play($B, $g->point(2, 2));
	my $c = eval { $g->clone };
	ok($c, 'the clone was built') or diag $@;
	is($c && $c->ko, 'simple', 'with the simple rule');
	done_testing();
};

subtest 'clone keeps the setup stones' => sub {
	my $g = Game::Go->new(size => 9, setup => { b => [[2, 2], [3, 3]], w => [[6, 6]] });
	$g->play($B, $g->point(4, 4));
	my $c = eval { $g->clone };
	ok($c, 'the clone was built') or diag $@;
	is($c && $c->board->to_text, $g->board->to_text, 'with the same stones');
	is_deeply($c && $c->events, $g->events, 'and the same log');
	done_testing();
};

subtest 'clone keeps who was told to move first' => sub {
	my $g = Game::Go->new(size => 9, first => 'w');
	is(eval { $g->clone }->turn, $W, 'white to move before a move is made');

	$g->play($W, $g->point(4, 4));
	my $c = eval { $g->clone };
	ok($c, 'the clone was built after a move') or diag $@;
	is($c && $c->turn, $B, 'and black is to move');

	my $h = Game::Go->new(size => 9, handicap => 3, first => 'b');
	is($h->clone->turn, $B, 'a handicap game told black moves first stays so');
	is(Game::Go->new(size => 9, handicap => 3)->clone->turn, $W,
		'and one not told gives white the move');
	done_testing();
};

round_trip(Game::Go->new(size => 9, seed => $SEED), 'at the start');

{
	my $g = Game::Go->new(size => 9, seed => $SEED);
	$g->play($B, $g->point(2, 2));
	$g->play($W, $g->point(6, 6));
	$g->play($B, $g->point(2, 6));
	round_trip($g, 'after three moves');
}

{
	my $g = Game::Go->new(size => 9, seed => $SEED);
	$g->play($B, $g->point(1, 0));
	$g->play($W, $g->point(0, 0));
	$g->play($B, $g->point(0, 1));
	is($g->prisoners->{$B}, 1, 'black has taken a stone');
	round_trip($g, 'after a capture');
}

{
	my $g = Game::Go->new(size => 9, seed => $SEED);
	$g->play($B, $g->point(1, 0));
	$g->play($W, $g->point(2, 0));
	$g->play($B, $g->point(0, 1));
	$g->play($W, $g->point(1, 1));
	$g->play($B, $g->point(2, 1));
	$g->play($W, $g->point(0, 0));
	isnt($g->ko_point, -1, 'a ko is live');
	round_trip($g, 'with a ko live');
}

round_trip(
	Game::Go->new(size => 9, ko => 'simple', komi => 5.5, first => 'w',
		setup => { b => [[2, 2]], w => [[6, 6], [6, 2]] }, seed => $SEED),
	'with every constructor option',
);

{
	my $g = Game::Go->new(size => 9, handicap => 4, seed => $SEED);
	$g->play($W, $g->point(4, 4));
	round_trip($g, 'a handicap game');
}

sub stopped {
	my $g = Game::Go->new(size => 9, seed => $SEED);
	$g->play($B, $g->point(2, 2));
	$g->play($W, $g->point(6, 6));
	$g->pass($B);
	$g->pass($W);
	return $g;
}

{
	my $g = stopped();
	is($g->phase, 'marking', 'the game is being counted');
	round_trip($g, 'in the marking phase');

	$g = stopped();
	$g->done($g->marking->proposer);
	round_trip($g, 'with a proposal made');
}

{
	my $g = Game::Go->new(size => 9, seed => $SEED);
	$g->play($B, $g->point(2, 2));
	$g->resign($W);
	round_trip($g, 'after a resignation');
	is(Game::Go->from_text($g->to_text)->winner, $B, 'and the winner survives');
	is(Game::Go->from_text($g->to_text)->seed, $SEED, 'and so does the seed');
}

{
	my $g = Game::Go->new(size => 9, seed => $SEED);
	$g->timeout($B);
	round_trip($g, 'after a timeout');
}

{
	my $g = Game::Go->new(size => 9, seed => $SEED);
	my $bot = Game::Go::Bot->new(level => 1, seed => 'late');
	my @texts;
	my $guard = 0;
	while ($g->status eq 'active' && $guard++ < 400) {
		my ($who) = $g->waiting_on;
		my $move = $bot->choose($g, $who) or last;
		my $out = apply($g, $move);
		die $out->message if ref $out eq 'Game::Go::Error';
		push @texts, $g->to_text;
	}
	is($g->status, 'finished', 'the bot played the game to its end');
	my $late = Game::Go->from_text($texts[-10]);
	round_trip($late, 'late in a bot game');
	round_trip($g, 'at the end of a bot game');
	is(Game::Go->from_text($g->to_text)->result, $g->result, 'the result survives');
}

subtest 'a game with no seed' => sub {
	my $g = Game::Go->new(size => 13);
	$g->play($B, $g->point(3, 3));
	my $l = Game::Go->from_text($g->to_text);
	is($l->to_text, $g->to_text, 'round-trips');
	$l->resign($W);
	is($l->seed, undef, 'and still has none');
	done_testing();
};

subtest 'malformed text is refused with a sentence' => sub {
	my $g = Game::Go->new(size => 9, seed => $SEED);
	$g->play($B, $g->point(2, 2));
	my $good = $g->to_text;

	my @bad = (
		[ undef,                                   qr/wants the string/ ],
		[ [],                                      qr/wants the string/ ],
		[ '',                                      qr/not a saved game/ ],
		[ "chess 1\n",                             qr/not a saved game/ ],
		[ "game-go 1\n",                           qr/no events/ ],
		[ "game-go 1\nseed abc\n",                 qr/seed line/ ],
		[ "game-go 1\nb play pt=3\n",              qr/'sys start'/ ],
		[ $good =~ s/size=9/size=10/r,             qr/size '10'/ ],
		[ $good =~ s/b play/x play/r,              qr/event 2 is not an actor/ ],
		[ $good =~ s/pt=(\d+)/pt=$1;/r,            qr/not a value/ ],
		[ $good =~ s/pt=/pt /r,                    qr/not a key=value/ ],
		[ $good =~ s/pt=(\d+)/pt=$1 pt=$1/r,       qr/twice/ ],
		[ $good =~ s/pt=(\d+)/pt=0/r,              qr/refused/ ],
		[ $good =~ s/ko=positional/ko=sideways/r,  qr/ko must be/ ],
		[ $good . "b play caps=[] pt=40\n",        qr/refused/ ],
	);
	for my $case (@bad) {
		my ($text, $want) = @$case;
		my $label = defined $text ? (ref $text ? 'a reference' : "'" . substr($text, 0, 30) . "'") : 'undef';
		$label =~ s/\n/\\n/g;
		ok(!eval { Game::Go->from_text($text); 1 }, "$label is refused");
		like($@, $want, 'with a message saying why');
		like($@, qr/\AGame::Go/, 'in the engine\'s own voice');
	}
	done_testing();
};

done_testing();
