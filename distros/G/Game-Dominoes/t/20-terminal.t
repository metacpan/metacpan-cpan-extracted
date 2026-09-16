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

plan tests => 11;

sub tile { Game::Dominoes::Tile->of(@_) }

# Drive the terminal through in-memory handles, which is the whole reason the
# handles are properties rather than bare STDIN and STDOUT.
sub run {
	my (%args) = @_;
	my $input = $args{input} // '';
	my $output = '';

	open my $in, '<', \$input or die $!;
	open my $out, '>', \$output or die $!;

	my $term = Game::Dominoes::Terminal->new(
		game => $args{game},
		bots => $args{bots} || {},
		in => $in,
		out => $out,
		colour => 0,
		(exists $args{handover} ? (handover => $args{handover}) : ()),
		(exists $args{compact} ? (compact => $args{compact}) : ()),
	);
	my $result = $term->start;
	close $in;
	close $out;
	return ($output, $result, $term);
}

sub game {
	return Game::Dominoes->new(seed => 'a' x 32, @_);
}

subtest 'the tiles are drawn, and a double is drawn across its run' => sub {
	plan tests => 7;

	my $g = game(players => 2);
	my $term = Game::Dominoes::Terminal->new(game => $g, colour => 0, ascii => 1);
	my $layout = $g->layout;

	# 5-5 opens as the spinner, the line runs through it both ways, and then
	# both perpendicular arms are open
	$layout->place(tile(5, 5), 'L');
	$layout->place(tile(5, 2), 'R');
	$layout->place(tile(5, 3), 'L');

	my @rows = $term->table({ layout => $layout });

	is scalar @rows, 9,
		'the line is nine rows tall, because the double stands across it';
	like $rows[0], qr/\A\s+\+---\+\s*\z/,
		'the double reaches above the tiles either side of it';
	like $rows[2], qr/\+---\+---\+.*\+---\+---\+/,
		'which lie lengthwise, their two halves side by side';
	like $rows[4], qr/\|\+---\+\|/,
		"and the double's own two halves are stacked on the middle row";

	# the arms come out of the spinner's short ends, so they start at its own
	# column with a stroke joining them to it
	$layout->place(tile(5, 1), 'U');
	$layout->place(tile(5, 6), 'D');
	my @armed = $term->table({ layout => $layout });
	like join("\n", @armed), qr/\n\s+\|\n/, 'an arm hangs off the spinner on a stem';
	is index($armed[0], '+'), index($armed[6], '+'),
		'and starts at the column the spinner is drawn in';

	$term->compact(1);
	my @plain = $term->table({ layout => $layout });
	is scalar @plain, 3, 'compact goes back to one line an arm';
};

subtest 'a hand is drawn with what to type under each tile' => sub {
	plan tests => 3;

	my $g = game(players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(0, 0) ]);
	my $term = Game::Dominoes::Terminal->new(game => $g, colour => 0, ascii => 1);

	my @rows = $term->hand_lines($g->view(1));
	like $rows[0], qr/your tiles/, 'it says whose they are';
	like join("\n", @rows), qr/6-4\s+0-0/, 'each tile is labelled with what to type';

	# a blank half is a blank half: no pips, and still a tile
	my ($blank) = grep { m/\|\s{3}\|\s{3}\|/ } @rows;
	ok $blank, 'the double blank is drawn empty rather than left out';
};

subtest 'a whole game against the bot, in process' => sub {
	plan tests => 3;

	my $g = game(players => 2, target => 40);
	my ($out, $result) = run(
		game => $g,
		bots => { 1 => Game::Dominoes::Bot->new(level => 1, seed => 1),
		          2 => Game::Dominoes::Bot->new(level => 1, seed => 2) },
	);

	isa_ok $result, 'Game::Dominoes::Result', 'start returned a result';
	is $g->status, 'finished', 'and the game finished';
	like $out, qr/wins by/, 'the transcript says who won';
};

subtest 'start returns the result and never calls exit' => sub {
	plan tests => 2;

	# If start() called exit, this test file would stop here and the plan
	# would come up short, which is how it would be noticed.
	my $g = game(players => 2, target => 20);
	my (undef, $result) = run(
		game => $g,
		bots => { 1 => Game::Dominoes::Bot->new(level => 1, seed => 1),
		          2 => Game::Dominoes::Bot->new(level => 1, seed => 2) },
	);

	ok $result, 'we are still here, and holding a result';
	is $result->reason, 'target', 'which says how the game ended';
};

subtest 'end of file quits cleanly' => sub {
	plan tests => 2;

	# No input at all: the first prompt gets undef and the loop stops without
	# dying and without spinning.
	my $g = game(players => 2);
	my ($out, $result) = run(game => $g, input => '', handover => 0);

	is $result, undef, 'no result, because nobody finished the game';
	like $out, qr/stopped/, 'and it said so rather than dying';
};

subtest 'a person can play a tile' => sub {
	plan tests => 3;

	my $g = game(players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(6, 2), tile(3, 3) ]);
	$g->turn(1);

	my ($out) = run(
		game => $g, handover => 0,
		bots => { 2 => Game::Dominoes::Bot->new(level => 1, seed => 1) },
		input => "6-4\nquit\n",
	);

	like $out, qr/played 6-4/, 'the play was accepted';
	like $out, qr/for 10/, 'and scored, because 6-4 as a lead counts ten';
	ok !$g->hand(1)->holds(tile(6, 4)), 'the tile left the hand';
};

subtest 'the commands answer' => sub {
	plan tests => 6;

	my $g = game(players => 2);
	my ($out) = run(
		game => $g, handover => 0,
		bots => { 2 => Game::Dominoes::Bot->new(level => 1, seed => 1) },
		input => "help\ntable\nhand\nscores\nlegal\nhint\nquit\n",
	);

	like $out, qr/arms are L and R/, 'help explains the arms';
	like $out, qr/nothing on the table yet/, 'table says the table is empty';
	like $out, qr/your tiles:/, 'hand lists the tiles';
	like $out, qr/seat 1: 0/, 'scores shows the score';
	like $out, qr/\d+\.\s+\d-\d\@/, 'legal numbers the moves';
	like $out, qr/try \d-\d\@/, 'hint suggests one';
};

subtest 'a bad move is refused in words, not by dying' => sub {
	plan tests => 3;

	my $g = game(players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->turn(1);

	my ($out) = run(
		game => $g, handover => 0,
		bots => { 2 => Game::Dominoes::Bot->new(level => 1, seed => 1) },
		input => "0-0\nwibble\nquit\n",
	);

	like $out, qr/no: you do not hold that tile/, 'a tile not held is refused';
	like $out, qr/I do not know 'wibble'/, 'and so is a word nobody defined';
	is $g->status, 'active', 'the game carried on regardless';
};

subtest 'the hand-over stops a shared screen leaking' => sub {
	plan tests => 2;

	# Two people at one screen. Without the hand-over, seat 2 sits down in
	# front of whatever seat 1 was looking at.
	my $g = game(players => 2);
	my $term = Game::Dominoes::Terminal->new(game => $g, bots => {});
	ok $term->handover, 'it is on by default when more than one person plays';

	my $solo = Game::Dominoes::Terminal->new(
		game => game(players => 2),
		bots => { 2 => Game::Dominoes::Bot->new(level => 1, seed => 1) },
	);
	ok !$solo->handover, 'and off when only one person is at the keyboard';
};

subtest 'THE LEAK: a hotseat transcript never shows another seat tiles' => sub {
	plan tests => 3;

	# The terminal draws from view($seat) and never from the game object. If
	# it reached into $game->hand(2), the clear-screen between turns would be
	# the only thing protecting a hand, and a scrollback buffer defeats that.
	#
	# So this greps the WHOLE transcript for every tile that was in somebody
	# else's hand at the moment it was their opponent's turn.
	my $g = game(players => 3);

	# Play a few human turns at seat 1 only, then stop. Seats 2 and 3 never
	# take a turn, so nothing of theirs may ever have been printed.
	my $seat2 = join ' ', map { $_->stringify } @{ $g->hand(2)->tiles };
	my $seat3 = join ' ', map { $_->stringify } @{ $g->hand(3)->tiles };

	# Once drawn and once compact. A drawn tile is pips and not '6-4', so the
	# compact run is the one this grep can see through: without it the test
	# would go on passing while saying less and less.
	my $input = "table\nhand\nlegal\nscores\nends\nquit\n";
	my ($out) = run(game => $g, handover => 0, bots => {}, input => $input);
	my ($plain) = run(
		game => game(players => 3), handover => 0, bots => {},
		compact => 1, input => $input,
	);

	my @leaked;
	for my $seat (2, 3) {
		for my $tile (@{ $g->hand($seat)->tiles }) {
			my $text = $tile->stringify;
			my $drawn = '[' . $tile->high . '|' . $tile->low . ']';
			# Only count it if seat 1 does not also hold that face pattern on
			# the table: a tile on the table is public.
			next if grep { $_->id == $tile->id } @{ $g->layout->tiles };
			next if grep { $_->id == $tile->id } @{ $g->hand(1)->tiles };
			push @leaked, "seat $seat holds $text"
				if $out =~ /\Q$text\E/ || $plain =~ /\Q$text\E/
				|| $plain =~ /\Q$drawn\E/;
		}
	}

	ok length $seat2, 'seat 2 was dealt tiles to leak';
	ok length $seat3, 'and so was seat 3';
	is_deeply \@leaked, [],
		'and not one of them appears anywhere in what seat 1 was shown';
};

subtest 'three and four seats play at a prompt' => sub {
	plan tests => 2;

	# The reason this phase is not last: a hotseat game is the only cheap way
	# to play three and four seat dominoes before a website can host it.
	for my $players (3, 4) {
		my $g = game(players => $players, target => 40);
		my %bots = map {
			$_ => Game::Dominoes::Bot->new(level => 1, seed => $_)
		} $g->seats;

		my (undef, $result) = run(game => $g, bots => \%bots);
		isa_ok $result, 'Game::Dominoes::Result',
			"a $players seat game finished at a prompt";
	}
};
