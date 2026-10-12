package Game::Snake;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Snake::Error;
use Game::Snake::Result;

our $VERSION = '0.12';

our @DIRECTIONS = qw/ up down left right /;

my %DELTA = (
	up    => [ 0, -1 ],
	down  => [ 0, 1 ],
	left  => [ -1, 0 ],
	right => [ 1, 0 ],
);

my %OPPOSITE = (
	up    => 'down',
	down  => 'up',
	left  => 'right',
	right => 'left',
);

my %IS_DIRECTION = map { $_ => 1 } @DIRECTIONS;

has cols => (
	is      => 'ro',
	isa     => Int,
	default => 40
);

has rows => (
	is      => 'ro',
	isa     => Int,
	default => 28
);

has seed => (
	is      => 'ro',
	isa     => Str,
	default => 'Game::Snake'
);

has start_length => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has food_score => (
	is      => 'ro',
	isa     => Int,
	default => 10
);

has start_speed => (
	is      => 'ro',
	isa     => Int,
	default => 2
);

has _body => (
	is      => 'rw',
	isa     => ArrayRef,
	default => sub { [] },
	private => 1
);

has _queue => (
	is      => 'rw',
	isa     => ArrayRef,
	default => sub { [] },
	private => 1
);

has _heading => (is => 'rw', private => 1);
has _food    => (is => 'rw', private => 1);
has _cause   => (is => 'rw', private => 1);
has _error   => (is => 'rw', private => 1);

has _grow => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

has _score => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

has _ticks => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

has _status => (
	is      => 'rw',
	isa     => Str,
	default => 'ready',
	private => 1
);

has _placed => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

has _last_rise => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

has _speed => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

my $place_food = sub {
	my ($self) = @_;
	my @free = $self->free_cells;
	return 0 unless @free;
	my $k = $self->_placed;
	my $hash = Digest::SHA::sha256($self->seed . "snake:food:$k");
	my $index = unpack('N', substr($hash, 0, 4)) % @free;
	$self->_food($free[$index]);
	$self->_placed($k + 1);
	return 1;
};

my $lay = sub {
	my ($self) = @_;
	my $x = int($self->cols * 0.375);
	my $y = int($self->rows * 0.643);
	$self->_body([ map { [ $x + $_, $y ] } 0 .. $self->start_length - 1 ]);
	$self->_heading('left');
	$self->_queue([]);
	$self->_food(undef);
	$self->_cause(undef);
	$self->_error(undef);
	$self->_grow(0);
	$self->_score(0);
	$self->_ticks(0);
	$self->_status('ready');
	$self->_placed(0);
	$self->_last_rise($self->food_score);
	$self->_speed($self->start_speed);
	$self->$place_food;
	return $self;
};

my $refuse = sub {
	my ($self, $code) = @_;
	$self->_error(Game::Snake::Error->of($code));
	return 0;
};

my $finish = sub {
	my ($self, $cause) = @_;
	$self->_status('finished');
	$self->_cause($cause);
	$self->_queue([]);
	return { moved => 0, ate => 0, grew => 0, died => $cause };
};

sub BUILD {
	my ($self) = @_;

	for my $name (qw/ cols rows start_length food_score start_speed /) {
		my $value = $self->$name;
		Carp::croak("Game::Snake: $name must be a whole number, not "
			. (defined $value ? "'$value'" : 'undef'))
			unless defined $value && $value =~ /\A[0-9]+\z/;
	}

	Carp::croak('Game::Snake: a board is at least 6 by 6')
		if $self->cols < 6 || $self->rows < 6;
	Carp::croak('Game::Snake: a snake starts at least 2 long')
		if $self->start_length < 2;
	Carp::croak('Game::Snake: the speed starts at 1 or more')
		if $self->start_speed < 1;
	Carp::croak('Game::Snake: food is worth 1 or more')
		if $self->food_score < 1;
	Carp::croak('Game::Snake: a seed is a string with something in it')
		unless defined $self->seed && CORE::length $self->seed;
	Carp::croak('Game::Snake: a snake ' . $self->start_length
		. ' long does not fit a board ' . $self->cols . ' wide')
		if int($self->cols * 0.375) + $self->start_length > $self->cols;

	$self->$lay;
	return;
}

sub turn {
	my ($self, $direction) = @_;

	Carp::croak("Game::Snake: '" . (defined $direction ? $direction : 'undef')
		. "' is not a direction")
		unless defined $direction && $IS_DIRECTION{$direction};

	return $self->$refuse('not_active') if $self->_status eq 'finished';

	my $queue = $self->_queue;
	my $against = @$queue ? $queue->[0] : $self->_heading;

	return $self->$refuse('same_direction') if $direction eq $against;
	return $self->$refuse('reverse') if $direction eq $OPPOSITE{$against};

	if (@$queue >= 2) {
		$queue->[1] = $direction;
	}
	else {
		push @$queue, $direction;
	}

	$self->_error(undef);
	return 1;
}

sub tick {
	my ($self) = @_;

	return { moved => 0 } if $self->_status eq 'finished';

	$self->_status('active');
	$self->_ticks($self->_ticks + 1);

	my $queue = $self->_queue;
	$self->_heading(shift @$queue) if @$queue;

	my $body = $self->_body;
	my ($dx, $dy) = @{ $DELTA{ $self->_heading } };
	my ($x, $y) = ($body->[0][0] + $dx, $body->[0][1] + $dy);

	return $self->$finish('wall')
		if $x < 0 || $y < 0 || $x >= $self->cols || $y >= $self->rows;

	my $growing = $self->_grow > 0;
	my $last = $growing ? $#$body : $#$body - 1;
	for my $i (0 .. $last) {
		return $self->$finish('body')
			if $body->[$i][0] == $x && $body->[$i][1] == $y;
	}

	unshift @$body, [ $x, $y ];
	if ($growing) {
		$self->_grow($self->_grow - 1);
	}
	else {
		pop @$body;
	}

	my $step = { moved => 1, ate => 0, grew => ($growing ? 1 : 0), died => undef };

	my $food = $self->_food;
	if ($food && $food->[0] == $x && $food->[1] == $y) {
		$step->{ate} = 1;
		$self->_grow($self->_grow + 1);
		my $score = $self->_score + $self->food_score;
		$self->_score($score);
		if ($score >= 2 * $self->_last_rise) {
			$self->_speed($self->_speed + 1);
			$self->_last_rise($score);
		}
		$self->_food(undef);
		unless ($self->$place_food) {
			$self->$finish('full');
			$step->{died} = 'full';
		}
	}

	return $step;
}

sub quit {
	my ($self) = @_;
	return 0 if $self->_status eq 'finished';
	$self->$finish('quit');
	return 1;
}

sub reset {
	my ($self) = @_;
	return $self->$lay;
}

sub _direction_from {
	my ($from, $to) = @_;
	my ($dx, $dy) = ($to->[0] - $from->[0], $to->[1] - $from->[1]);
	for my $direction (@DIRECTIONS) {
		my $delta = $DELTA{$direction};
		return $direction if $delta->[0] == $dx && $delta->[1] == $dy;
	}
	return undef;
}

sub segments {
	my ($self) = @_;

	my $body = $self->_body;
	my $n = $#$body;

	my @dir;
	for my $i (0 .. $n - 1) {
		$dir[$i] = _direction_from($body->[ $i + 1 ], $body->[$i]);
	}
	$dir[0] = $self->_heading;
	$dir[$n] = $dir[ $n - 1 ];

	my @segments;
	for my $i (0 .. $n) {
		my $bend = $i > 0 && $dir[ $i - 1 ] ne $dir[$i] ? $dir[ $i - 1 ] : 0;
		push @segments, {
			x    => $body->[$i][0],
			y    => $body->[$i][1],
			dir  => $dir[$i],
			bend => $bend,
			last => ($i == $n ? 1 : 0),
		};
	}

	return \@segments;
}

sub at {
	my ($self, $x, $y) = @_;

	my $body = $self->_body;
	for my $i (0 .. $#$body) {
		next unless $body->[$i][0] == $x && $body->[$i][1] == $y;
		return 'head' if $i == 0;
		return 'tail' if $i == $#$body;
		return 'body';
	}

	my $food = $self->_food;
	return 'food' if $food && $food->[0] == $x && $food->[1] == $y;

	return undef;
}

sub free_cells {
	my ($self) = @_;

	my %taken;
	$taken{ $_->[0] . ',' . $_->[1] }++ for @{ $self->_body };

	my @free;
	for my $y (0 .. $self->rows - 1) {
		for my $x (0 .. $self->cols - 1) {
			push @free, [ $x, $y ] unless $taken{"$x,$y"};
		}
	}

	return @free;
}

sub food {
	my ($self) = @_;
	my $food = $self->_food;
	return $food ? [ @$food ] : undef;
}

sub length  { return scalar @{ $_[0]->_body } }
sub growing { return $_[0]->_grow }
sub heading { return $_[0]->_heading }
sub status  { return $_[0]->_status }
sub score   { return $_[0]->_score }
sub speed   { return $_[0]->_speed }
sub ticks   { return $_[0]->_ticks }
sub error   { return $_[0]->_error }

sub result {
	my ($self) = @_;
	return undef unless $self->_status eq 'finished';
	return Game::Snake::Result->new(
		cause  => $self->_cause,
		score  => $self->_score,
		length => $self->length,
		ticks  => $self->_ticks,
		speed  => $self->_speed,
	);
}

1;

__END__

=head1 NAME

Game::Snake - the classic snake game, as an engine

=head1 VERSION

Version 0.12

=head1 SYNOPSIS

    use Game::Snake;

    my $game = Game::Snake->new(seed => 'anything');

    $game->turn('up');

    while ($game->status ne 'finished') {
        my $step = $game->tick;
        last if $step->{died};
    }

    print $game->result->stringify, "\n";

Or, from a shell:

    snake
    snake --raylib

=head1 DESCRIPTION

A snake on a grid, heading one of four ways, eating to grow and dying at a
wall or its own body. This class is the game and nothing else: it prints
nothing, reads nothing, sleeps never and calls C<rand> never. Every placement
of food comes from the seed, so the same seed and the same turns are the same
game twice.

The terminal game is L<Game::Snake::Terminal> and the window is
L<Game::Snake::Raylib>. They are separate modules so that this one can be
loaded by anything without pulling either in.

The board is C<cols> by C<rows> cells, C<x> from 0 at the left and C<y> from 0
at the top. The snake starts C<start_length> long, heading left, its head a
little left of centre and its body to the right.

=head1 METHODS

=head2 new

    my $game = Game::Snake->new(
        cols         => 40,
        rows         => 28,
        seed         => 'anything',
        start_length => 3,
        food_score   => 10,
        start_speed  => 2,
    );

Every argument has a default, shown. A board is at least six by six. The
seed is any string; the default seed plays the same game every time, so a
program that wants a different game each run makes its own seed.

Arguments are read by name, and a name this class does not know is dropped
in silence: C<new(colz =E<gt> 9)> builds the default board. Spell them
carefully.

=head2 turn

    $game->turn('up') or warn $game->error->message;

Queues a heading, one of C<up>, C<down>, C<left> and C<right>. Two headings
may wait at once: the first is what the next tick follows, and a third press
replaces the second. A heading the snake already has is refused as
C<same_direction>, the opposite of it as C<reverse>, and any turn on a
finished game as C<not_active>. Returns 1, or 0 with L</error> set. A word
that is not a direction is a programmer error and dies.

=head2 tick

    my $step = $game->tick;

Moves the snake one cell. Returns a hash with C<moved>, C<ate>, C<grew> and
C<died>, the last undefined or one of C<wall>, C<body> and C<full>. The snake
grows the tick after it eats, and the tail leaves its cell before the head
arrives, so a head may follow the tail into the cell it is leaving. The
speed rises by one each time the score reaches double what it was at the
last rise. A board with no free cell left ends the game as C<full>. A tick
on a finished game moves nothing.

=head2 segments

    for my $segment (@{ $game->segments }) {
        printf "%d,%d %s\n", $segment->{x}, $segment->{y}, $segment->{dir};
    }

The snake head first, each cell with its C<x>, C<y>, the direction C<dir> it
is heading, C<bend> (the heading of the cell in front when that differs, else
0) and C<last>, 1 on the tail. The tail's direction points at the cell in
front of it, so a renderer may draw it from C<dir> alone.

=head2 at

    my $what = $game->at($x, $y);

C<head>, C<body>, C<tail>, C<food> or undefined.

=head2 free_cells

Every cell the snake is not on, as C<[x, y]> pairs in row-major order.

=head2 food

The cell the food is on, as C<[x, y]>, or undefined once the board is full.

=head2 cols, rows, seed, start_length, food_score, start_speed

The arguments C<new> was given, or their defaults.

=head2 length, heading, status, score, speed, ticks, growing

How long the snake is, which way it is heading, C<ready>, C<active> or
C<finished>, the score, cells a second, ticks taken, and how many cells of
growth are owed from meals not yet grown into. While C<growing> is above
zero the tail stays where it is on the next tick.

=head2 error

The L<Game::Snake::Error> from the last refused turn, or undefined after a
turn that was taken.

=head2 result

A L<Game::Snake::Result> once the game has finished, else undefined.

=head2 quit

Finishes the game with the cause C<quit>. Returns 1, or 0 if it had already
finished.

=head2 reset

Puts the snake back at the start with the same seed, so the same game can be
played again.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-snake at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Snake>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Snake

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Snake>

=item * Search CPAN

L<https://metacpan.org/release/Game-Snake>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
