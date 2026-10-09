#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills::Points;

my $P = 'Game::Merrills::Points';

# The tables in Points.pm are typed by hand. Everything below is worked out a
# second way, from the shape of the board alone: three squares, ring 0 the
# outer one, each with a point at every corner and every midpoint.

my %derived_at;
my @derived;
for my $ring (0 .. 2) {
	my ($low, $high) = ($ring, 6 - $ring);
	for my $spot ([$low, $low], [3, $low], [$high, $low], [$low, 3],
		[$high, 3], [$low, $high], [3, $high], [$high, $high]) {
		my ($col, $row) = @{$spot};
		my $name = chr(ord('a') + $col) . (7 - $row);
		$derived_at{"$col,$row"} = $name;
		push @derived, $name;
	}
}

sub runs {
	my ($across) = @_;
	my @mills;
	for my $fixed (0 .. 6) {
		my @line;
		for my $moving (0 .. 6) {
			my ($col, $row) = $across ? ($moving, $fixed) : ($fixed, $moving);
			if ($col == 3 && $row == 3) {
				push @mills, [@line] if @line;
				@line = ();
				next;
			}
			push @line, $derived_at{"$col,$row"} if $derived_at{"$col,$row"};
		}
		push @mills, [@line] if @line;
	}
	return @mills;
}

my @derived_mills = (runs(1), runs(0));
my %derived_edge;
for my $mill (@derived_mills) {
	for my $i (0, 1) {
		my ($one, $two) = @{$mill}[ $i, $i + 1 ];
		$derived_edge{ join '-', sort $one, $two } = 1;
	}
}

sub mill_key {
	return join ' ', sort @_;
}

my @points = Game::Merrills::Points::all_points();

subtest 'twenty-four points, each with one name' => sub {
	is(scalar @points, 24, 'twenty-four of them');
	is(Game::Merrills::Points::POINTS, 24, 'and the constant says so');
	is_deeply(
		[ sort map { Game::Merrills::Points::name($_) } @points ],
		[ sort @derived ],
		'the names are the corners and midpoints of three squares'
	);
	for my $n (@points) {
		my $name = Game::Merrills::Points::name($n);
		is(Game::Merrills::Points::point($name), $n, "$name is point $n");
	}
	is(Game::Merrills::Points::point('A7'), 0, 'a name is found in either case');
	is(Game::Merrills::Points::point('d4'), undef, 'the centre is not a point');
	is(Game::Merrills::Points::point('a2'), undef, 'nor is a2');
	is(Game::Merrills::Points::point('h1'), undef, 'nor anything off the board');
	is(Game::Merrills::Points::point(undef), undef, 'nor undef');
};

subtest 'the numbers run in reading order from the top' => sub {
	my @order = sort {
		Game::Merrills::Points::row_of($a) <=> Game::Merrills::Points::row_of($b)
			|| Game::Merrills::Points::col_of($a) <=> Game::Merrills::Points::col_of($b)
	} @points;
	is_deeply(\@order, \@points, 'row by row, left to right');
	is(Game::Merrills::Points::name(0), 'a7', 'a7 first');
	is(Game::Merrills::Points::name(23), 'g1', 'g1 last');
	for my $n (@points) {
		my $name = Game::Merrills::Points::name($n);
		my $rebuilt = chr(ord('a') + Game::Merrills::Points::col_of($n))
			. (7 - Game::Merrills::Points::row_of($n));
		is($rebuilt, $name, "$name sits where its name says");
	}
};

subtest 'sixteen mills, and they are the derived ones' => sub {
	my @mills = Game::Merrills::Points::mills();
	is(scalar @mills, 16, 'sixteen');
	is(scalar @derived_mills, 16, 'and sixteen derived');

	my %have = map {
		mill_key(map { Game::Merrills::Points::name($_) } @{$_}) => 1
	} @mills;
	my %want = map { mill_key(@{$_}) => 1 } @derived_mills;
	is_deeply(\%have, \%want, 'the same sixteen');
	is(scalar keys %have, 16, 'no mill listed twice');

	my ($across, $down) = (0, 0);
	for my $mill (@mills) {
		my %row = map { Game::Merrills::Points::row_of($_) => 1 } @{$mill};
		my %col = map { Game::Merrills::Points::col_of($_) => 1 } @{$mill};
		$across++ if keys %row == 1 && keys %col == 3;
		$down++ if keys %col == 1 && keys %row == 3;
	}
	is($across, 8, 'eight across');
	is($down, 8, 'eight down');

	ok(!$have{ mill_key(qw/b4 c4 e4/) }, 'b4 c4 e4 crosses the centre and is no mill');
	ok(!$have{ mill_key(qw/d3 d5 d6/) }, 'nor is d3 d5 d6');
	ok($have{ mill_key(qw/a4 b4 c4/) }, 'a4 b4 c4 is');
	ok($have{ mill_key(qw/e4 f4 g4/) }, 'and so is e4 f4 g4');
};

subtest 'every point is in exactly two mills, one across and one down' => sub {
	for my $n (@points) {
		my $name = Game::Merrills::Points::name($n);
		my @of = Game::Merrills::Points::mills_of($n);
		is(scalar @of, 2, "$name is in two");
		is(scalar(grep { grep { $_ == $n } @{$_} } @of), 2, "and $name is in both");
		my @rows = map {
			my %row = map { Game::Merrills::Points::row_of($_) => 1 } @{$_};
			scalar keys %row;
		} @of;
		is_deeply([ sort @rows ], [ 1, 3 ], "one across and one down through $name");
	}
};

subtest 'no two points share more than one mill' => sub {
	my %shared;
	for my $mill (Game::Merrills::Points::mills()) {
		my @in = sort { $a <=> $b } @{$mill};
		$shared{"$in[0],$in[1]"}++;
		$shared{"$in[0],$in[2]"}++;
		$shared{"$in[1],$in[2]"}++;
	}
	is(scalar keys %shared, 48, 'forty-eight pairs');
	is(scalar(grep { $_ > 1 } values %shared), 0, 'none of them twice');
};

subtest 'thirty-two lines, the same from either end' => sub {
	my %edge;
	my $ends = 0;
	for my $n (@points) {
		my @near = Game::Merrills::Points::adjacent($n);
		is_deeply(\@near, [ sort { $a <=> $b } @near ],
			Game::Merrills::Points::name($n) . ' lists its neighbours in order');
		for my $other (@near) {
			$ends++;
			isnt($other, $n, 'no point is its own neighbour');
			ok(Game::Merrills::Points::is_adjacent($other, $n),
				Game::Merrills::Points::name($other) . ' and '
				. Game::Merrills::Points::name($n) . ' agree');
			$edge{ join '-', sort map { Game::Merrills::Points::name($_) } $n, $other } = 1;
		}
	}
	is($ends, 64, 'sixty-four line ends');
	is(scalar keys %edge, 32, 'thirty-two lines');
	is_deeply(\%edge, \%derived_edge, 'and they are the derived ones');
	ok(!Game::Merrills::Points::is_adjacent(0, 2), 'a7 and g7 are not neighbours');
	ok(!Game::Merrills::Points::is_adjacent(11, 12), 'nor are c4 and e4, across the centre');
};

subtest 'twelve corners, eight threes, four fours' => sub {
	my %degree;
	my @four;
	for my $n (@points) {
		my $count = () = Game::Merrills::Points::adjacent($n);
		$degree{$count}++;
		push @four, Game::Merrills::Points::name($n) if $count == 4;
	}
	is_deeply(\%degree, { 2 => 12, 3 => 8, 4 => 4 }, 'by number of neighbours');
	is_deeply([ sort @four ], [qw/b4 d2 d6 f4/], 'the fours are the middle square');
};

subtest 'what is handed back is a copy' => sub {
	my ($mill) = Game::Merrills::Points::mills();
	$mill->[0] = 99;
	my ($again) = Game::Merrills::Points::mills();
	is($again->[0], 0, 'mills');
	my ($of) = Game::Merrills::Points::mills_of(0);
	$of->[0] = 99;
	my ($of_again) = Game::Merrills::Points::mills_of(0);
	is($of_again->[0], 0, 'mills_of');
};

subtest 'a number that is not a point dies' => sub {
	for my $bad (24, -1, 'a7', 1.5, undef, '') {
		my $shown = defined $bad ? "'$bad'" : 'undef';
		for my $function (qw/name row_of col_of adjacent mills_of/) {
			my $died = !eval { $P->can($function)->($bad); 1 };
			ok($died, "$function($shown)");
		}
		ok(!eval { Game::Merrills::Points::is_adjacent(0, $bad); 1 }, "is_adjacent(0, $shown)");
	}
	like(
		(eval { Game::Merrills::Points::name(24); 1 } ? '' : $@),
		qr/^point must be 0 \.\. 23, got '24'/,
		'and says what it was given'
	);
};

done_testing;
