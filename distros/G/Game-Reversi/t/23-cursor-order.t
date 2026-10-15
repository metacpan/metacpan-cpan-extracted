#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Terminal;

sub picker {
	my ($keys, @moves) = @_;
	open my $in, '<', \(my $script = "quit\n") or die $!;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my @chars = split //, $keys;

	my $t = Game::Reversi::Terminal->new(
		in => $in, out => $out, variant => 'othello', seed => 'order',
		level => 1, ascii => 1, ansi => 0, picking => 1,
		keysource => sub { shift @chars },
	);
	my $game = Game::Reversi->new(variant => 'othello', seed => 'order');
	$t->game($game);
	$t->remember($game->play($game->turn, $_)) for @moves;
	return ($t, $game, \$text);
}

sub drawn {
	my ($text) = @_;
	my @names;
	for my $line (split /\n/, $text) {
		last if @names && $line =~ /discs:/;
		my ($rank, $row) = $line =~ /^ ([1-8]) \|(.*)\| [1-8]$/ or next;
		my @cells = split /\|/, $row, -1;
		for my $col (0 .. 7) {
			push @names, ('a' .. 'h')[$col] . $rank
				if $cells[$col] eq ' * ' || $cells[$col] =~ /^>.<$/;
		}
	}
	return @names;
}

sub visited {
	my ($text) = @_;
	return $text =~ /^  ([a-h][1-8]): /mg;
}

sub from {
	my ($start, @ring) = @_;
	my ($at) = grep { $ring[$_] eq $start } 0 .. $#ring;
	return @ring[ map { ($at + $_) % @ring } 0 .. $#ring ];
}

subtest 'right walks the starred squares in the order they are drawn' => sub {
	my ($t, $game, $text) = picker(("\e[C" x 5) . 'q');
	$t->enter_raw;
	$t->pick_square($game, 'b');

	my @drawn = drawn($$text);
	my @seen = visited($$text);

	is(scalar @drawn, 4, 'four squares are starred');
	is($seen[0], $drawn[0], 'with no last move the cursor starts on the first');
	is_deeply(\@seen, [ @drawn, @drawn[0, 1] ],
		'and right visits them as they read, and goes round')
		or diag "drawn: @drawn\nvisited: @seen";
	done_testing();
};

subtest 'left walks them backwards' => sub {
	my ($t, $game, $text) = picker(("\e[D" x 4) . 'q');
	$t->enter_raw;
	$t->pick_square($game, 'b');

	my @drawn = drawn($$text);
	my @seen = visited($$text);

	is_deeply(\@seen, [ $drawn[0], reverse @drawn ],
		'the same ring the other way')
		or diag "drawn: @drawn\nvisited: @seen";
	done_testing();
};

subtest 'every key that moves the cursor moves it along the same ring' => sub {
	for my $pair ([ "\e[B", 1 ], [ "\t", 1 ], [ "\e[A", -1 ], [ "\e[Z", -1 ]) {
		my ($key, $way) = @$pair;
		my ($t, $game, $text) = picker(($key x 3) . 'q');
		$t->enter_raw;
		$t->pick_square($game, 'b');

		my @drawn = drawn($$text);
		my @ring = $way > 0 ? @drawn : ($drawn[0], reverse @drawn[1 .. $#drawn]);
		my @seen = visited($$text);
		(my $name = $key) =~ s/\e/ESC/;
		$name =~ s/\t/TAB/;
		is_deeply(\@seen, [ @ring[0 .. 3] ], "$name follows the drawn order")
			or diag "drawn: @drawn\nvisited: @seen";
	}
	done_testing();
};

subtest 'after a move the cursor starts nearest it and the ring is still the drawn one' => sub {
	my $probe = Game::Reversi->new(variant => 'othello', seed => 'order');
	my @opening;
	for (1 .. 2) {
		my @legal = sort { $a <=> $b } map { $_->square } @{ $probe->legal($probe->turn) };
		push @opening, $legal[-1];
		$probe->play($probe->turn, $legal[-1]);
	}

	my ($t, $game, $text) = picker(("\e[C" x 8) . 'q', @opening);
	$t->enter_raw;
	$t->pick_square($game, 'b');

	my @drawn = drawn($$text);
	my @seen = visited($$text);
	cmp_ok(scalar @drawn, '>=', 3, 'there are several squares to walk');

	my $last = $t->last_move->square;
	my %gap = map {
		$_ => abs(Game::Reversi::Board->square_of(split //, $_) - $last)
	} @drawn;
	my ($nearest) = sort { $gap{$a} <=> $gap{$b} } @drawn;
	is($seen[0], $nearest, 'the cursor starts on the square nearest the last move');
	isnt($seen[0], $drawn[0], 'which is not the first drawn, so the start is a real choice');

	my @ring = from($seen[0], @drawn);
	my @want = map { $ring[ $_ % @ring ] } 0 .. 8;
	is_deeply(\@seen, \@want, 'and from there right reads on through the drawn order')
		or diag "drawn: @drawn\nvisited: @seen";
	done_testing();
};

done_testing();
