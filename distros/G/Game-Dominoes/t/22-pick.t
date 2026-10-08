#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Bot;
use Game::Dominoes::Hand;
use Game::Dominoes::Terminal;
use Game::Dominoes::Tile;

plan tests => 14;

sub tile { Game::Dominoes::Tile->of(@_) }

# Every one of these runs without a terminal: the keys come from `keysource`,
# so nothing here needs a tty, a pipe, or Term::ReadKey to be installed. The
# same arrangement as Game::Checkers' and Game::Oware's pick tests, and it is
# the only way a key loop gets tested rather than described in POD.
#
# Nothing here is interactive, so `_clear` never fires and the captured output
# has no screen-clearing escape in it to grep past.
sub pick_term {
	my (%args) = @_;

	my @chars = split //, defined $args{keys} ? $args{keys} : '';
	my $input = $args{input} // '';
	my $output = '';

	open my $in, '<', \$input or die $!;
	open my $out, '>', \$output or die $!;

	my $term = Game::Dominoes::Terminal->new(
		game      => $args{game},
		bots      => $args{bots} || {},
		in        => $in,
		out       => $out,
		colour    => $args{colour} ? 1 : 0,
		ascii     => 1,
		width     => 200,
		handover  => (exists $args{handover} ? $args{handover} : 0),
		picking   => (exists $args{picking} ? $args{picking} : 1),
		keysource => (exists $args{keysource} ? $args{keysource}
			: sub { shift @chars }),
	);

	return ($term, \$output, \@chars);
}

sub game {
	return Game::Dominoes->new(seed => 'a' x 32, @_);
}

sub bots {
	my ($game, @seats) = @_;
	return { map { $_ => Game::Dominoes::Bot->new(level => 2, seed => $_ * 7919) }
		@seats };
}

subtest 'a key at a time, named' => sub {
	plan tests => 1;

	my ($term) = pick_term(game => game(),
		keys => "k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");

	my @got;
	while (defined(my $key = $term->read_key)) {
		push @got, $key eq ' ' ? 'space' : $key;
	}

	is_deeply \@got, [ qw/ k up down right left page_up home enter tab backspace
		interrupt eof space q escape page_down / ],
		'a character comes back as itself and a sequence as a name';
};

# The escape key and the first byte of an arrow key are the same byte, and the
# only thing telling them apart is whatever comes next.
subtest 'an escape does not eat the key behind it' => sub {
	plan tests => 2;

	my ($term) = pick_term(game => game(), keys => "\eq");

	is $term->read_key, 'escape', 'the escape is an escape';
	is $term->read_key, 'q', 'and the keystroke behind it survives';
};

subtest 'the arrow keys choose a move, and enter plays it' => sub {
	plan tests => 3;

	my $g = game(players => 2);
	my ($term, $out) = pick_term(game => $g, bots => bots($g, 2),
		keys => "\e[B\r");

	my $wanted = $g->legal($g->turn)->[1];
	my $expect = $wanted->{tile}->stringify . '@' . $wanted->{arm};

	$term->start;

	my ($played) = grep { $_->{kind} eq 'play' } @{ $g->history };
	is $played->{play}->tile->stringify . '@' . $played->{play}->arm, $expect,
		'the second option, one press down from the first';

	like ${$out}, qr/arrows to choose/, 'the keys were on the screen';
	like ${$out}, qr/if you play \d-\d on [LRUD]:/, 'and so was a preview';
};

subtest 'the cursor wraps, both ways' => sub {
	plan tests => 2;

	for my $case ([ "\e[A\r", -1, 'up from the first is the last' ],
		[ "\r", 0, 'and enter on the first is the first' ]) {
		my ($keys, $index, $why) = @$case;
		my $g = game(players => 2);
		my ($term) = pick_term(game => $g, bots => bots($g, 2), keys => $keys);
		my $wanted = $g->legal($g->turn)->[$index];
		my $expect = $wanted->{tile}->stringify . '@' . $wanted->{arm};

		$term->start;

		my ($played) = grep { $_->{kind} eq 'play' } @{ $g->history };
		is $played->{play}->tile->stringify . '@' . $played->{play}->arm,
			$expect, $why;
	}
};

# THE TABLE ABOVE THE LIST IS THE ONE THE MOVE WOULD MAKE. Game::Oware shipped
# the Checkers behaviour first, drawing the live position with the candidate's
# marks over it, and on a board of counts it contradicted itself. Here the
# question is where a tile goes and what the count becomes, so the preview has
# to be the result or it answers nothing.
subtest 'the preview is the table the move would make, and plays nothing' => sub {
	plan tests => 5;

	my $g = game(players => 2);
	$g->layout->place(tile(5, 5), 'L');
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(5, 0), tile(6, 4) ]);
	$g->turn(1);

	my ($term, $out) = pick_term(game => $g, keys => 'q');
	$term->start;

	like ${$out}, qr/if you play 5-0 on [LRUD]:/, 'it says which move it shows';

	# THE ORACLE IS THE GAME, not arithmetic retyped here. A second game set
	# up the same way plays the move for real, and the count the preview
	# printed must be the count that game then reports. Working the All Fives
	# count out by hand in the test would be asserting this code against my
	# own sums, and the first draft of this subtest got them wrong.
	my $real = game(players => 2);
	$real->layout->place(tile(5, 5), 'L');
	$real->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(5, 0), tile(6, 4) ]);
	$real->turn(1);
	my $played = $real->play(1, { tile => tile(5, 0), arm => 'L' });

	like ${$out}, qr/count \Q@{[ $real->count ]}\E\b/,
		'with the count the move really does leave';
	like ${$out}, qr/scores \Q@{[ $played->points ]}\E\b/,
		'and what it really does score';

	is $g->layout->count, 1, 'the real table still holds only the opening tile';
	is $g->status, 'active', 'and the previewed game played nothing';
};

subtest 'the three frames are told apart without colour' => sub {
	plan tests => 4;

	my $g = game(players => 2);
	$g->layout->place(tile(5, 5), 'L');
	$g->layout->place(tile(5, 2), 'R');
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(5, 0) ]);
	$g->turn(1);

	# Mark 5-2 as just played, the way a bot's turn would.
	my ($term, $out) = pick_term(game => $g, keys => 'q');
	$term->remember(2, Game::Dominoes::Play->new(tile => tile(5, 2), arm => 'R'));

	$term->start;

	my $text = ${$out};
	like $text, qr/\+---\+/, 'a settled tile keeps the light frame';
	like $text, qr/#===#/, 'one played since you looked takes the double';
	like $text, qr/\+===\+/, 'and the candidate the heavy one';

	# All three at once is the point: a single marked style would make the
	# candidate and the tiles that landed while you were away look alike.
	my ($frame) = ($text =~ /(if you play.*?\n(?:.*\n){1,12}?)\n/);
	ok $frame && $frame =~ /#===#/ && $frame =~ /\+===\+/,
		'and both marked styles appear in the same frame as each other';
};

subtest 'the just-played marks survive stepping into the picker' => sub {
	plan tests => 2;

	my $g = game(players => 2);
	my ($term, $out) = pick_term(game => $g, bots => bots($g, 2),
		keys => "\r\e[Bq");

	$term->start;

	# After seat 2 replies there is a tile to mark, and the frame drawn for
	# the next pick must still carry it. The first version replaced the marks
	# with the preview's own and lost them.
	cmp_ok scalar @{ $term->recent }, '>', 0, 'a play was remembered';
	my $marks = $term->table_marks;
	cmp_ok scalar keys %$marks, '>', 0, 'and it is marked on the table';
};

subtest 'the round so far is reprinted on every frame' => sub {
	plan tests => 2;

	my $g = game(players => 4);

	# Play one move so the other three seats take a turn: on the opening pick
	# there is nothing behind the player yet to reprint.
	my ($term, $out) = pick_term(game => $g, bots => bots($g, 2, 3, 4),
		keys => "\r\e[Bq");

	$term->start;

	# Clearing the screen destroys the narration of the plays this is a reply
	# to, and at four seats that is three tiles the player never read.
	my ($second) = (${$out} =~ /(if you play .*)\z/s);
	ok $second, 'the player got a second turn to pick on' or diag ${$out};

	my $said = () = ($second || '') =~ /seat \d played \d-\d on [LRUD]/g;
	cmp_ok $said, '>=', 2,
		'and the frame says what the other seats did while they were away';
};

subtest 'v swaps the preview for the table as it stands' => sub {
	plan tests => 3;

	my $g = game(players => 2);

	# One move first, so the live view has a table to draw and a mark on it.
	my ($term, $out) = pick_term(game => $g, bots => bots($g, 2), keys => "\rvq");

	$term->start;

	# Only the frame under that heading, not the whole transcript: the frames
	# either side of it are previews and are supposed to carry a candidate.
	my ($live) = (${$out} =~ /the table as it stands:\n(.*?)\n\n/s);
	ok $live, 'v draws the live position' or diag ${$out};
	unlike $live, qr/\+===\+/,
		'with no candidate on it, because none is being shown';
	like $live, qr/#===#/, 'but the tile just played is still marked';
};

subtest 'the numbers jump, and home and end go to the edges' => sub {
	plan tests => 2;

	my $g = game(players => 2);
	my ($term) = pick_term(game => $g, bots => bots($g, 2), keys => "2\r");
	my $wanted = $g->legal($g->turn)->[1];
	my $expect = $wanted->{tile}->stringify . '@' . $wanted->{arm};
	$term->start;
	my ($played) = grep { $_->{kind} eq 'play' } @{ $g->history };
	is $played->{play}->tile->stringify . '@' . $played->{play}->arm, $expect,
		'a digit is the option at that place';

	my $h = game(players => 2);
	my ($last) = pick_term(game => $h, bots => bots($h, 2), keys => "\e[F\r");
	my $end = $h->legal($h->turn)->[-1];
	my $want = $end->{tile}->stringify . '@' . $end->{arm};
	$last->start;
	my ($done) = grep { $_->{kind} eq 'play' } @{ $h->history };
	is $done->{play}->tile->stringify . '@' . $done->{play}->arm, $want,
		'and end is the last of them';
};

subtest 'a dud key says so, and q stops without playing' => sub {
	plan tests => 3;

	my $g = game(players => 2);
	my ($term, $out) = pick_term(game => $g, bots => bots($g, 2), keys => 'zq');

	$term->start;

	like ${$out}, qr/that key does nothing here/, 'the dud key said so';
	is $g->layout->count, 0, 'nothing reached the table';
	is $g->status, 'active', 'and the game is where it stood';
};

subtest 't and a colon hand the turn to the typed prompt' => sub {
	plan tests => 4;

	for my $key (qw/ t : /) {
		my $g = game(players => 2);
		my ($term, $out) = pick_term(game => $g, bots => bots($g, 2),
			keys => $key, input => "quit\n");

		$term->start;

		like ${$out}, qr/seat 1> /, "$key fell through to the typed prompt";
		is $term->raw, 0, 'and put the terminal back first';
	}
};

# Without Term::ReadKey and without a keysource there is nothing to read keys
# with, and the fallback has to be the typed game rather than a failure.
subtest 'no key source at all falls back to typing, once' => sub {
	plan tests => 3;

	my $g = game(players => 2);
	my ($term, $out) = pick_term(game => $g, bots => bots($g, 2),
		keysource => undef, picking => 1, input => "quit\n");

	is $term->keys_available, 0, 'nothing to read keys with';
	$term->start;
	like ${$out}, qr/seat 1> /, 'so it hands over to the typed turn';
	is $term->picking, 0, 'and does not try again next turn';
};

# THE LEAK, AGAIN, THROUGH THE PICKER. t/20 proves the typed game never prints
# another seat's tiles. The picker draws far more of the screen far more often,
# and it draws a position no game has been in, so it is a second place the
# invariant can be lost. The preview is built from view($seat) for exactly this
# reason.
subtest 'THE LEAK: a picked hotseat frame never shows another seat tiles' => sub {
	plan tests => 3;

	my $g = game(players => 3);

	# Seat 1 walks the whole option list and quits. Seats 2 and 3 never take a
	# turn, so nothing of theirs may ever have been printed.
	my $keys = ("\e[B" x 12) . 'v' . ("\e[A" x 6) . 'q';
	my ($term, $out) = pick_term(game => $g, keys => $keys, handover => 0);

	$term->start;

	my @leaked;
	for my $seat (2, 3) {
		for my $t (@{ $g->hand($seat)->tiles }) {
			next if grep { $_->id == $t->id } @{ $g->layout->tiles };
			next if grep { $_->id == $t->id } @{ $g->hand(1)->tiles };
			push @leaked, "seat $seat holds " . $t->stringify
				if ${$out} =~ /\Q@{[ $t->stringify ]}\E/;
		}
	}

	ok scalar @{ $g->hand(2)->tiles }, 'seat 2 was dealt tiles to leak';
	cmp_ok length ${$out}, '>', 1000, 'and a lot of screen was drawn';
	is_deeply \@leaked, [],
		'and not one of them appears anywhere in what seat 1 was shown';
};
