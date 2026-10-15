package Game::Floppy;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Floppy::Error;
use Game::Floppy::Result;

our $VERSION = '0.10';

has width => (
	is      => 'ro',
	isa     => Int,
	default => 516
);

has height => (
	is      => 'ro',
	isa     => Int,
	default => 400
);

has seed => (
	is      => 'ro',
	isa     => Str,
	default => 'Game::Floppy'
);

has bird_x => (
	is      => 'ro',
	isa     => Int,
	default => 80
);

has bird_radius => (
	is      => 'ro',
	isa     => Int,
	default => 24
);

has gravity => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has lift => (
	is      => 'ro',
	isa     => Int,
	default => 30
);

has tube_every => (
	is      => 'ro',
	isa     => Int,
	default => 100
);

has tube_speed => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has tube_width => (
	is      => 'ro',
	isa     => Int,
	default => 52
);

has gap => (
	is      => 'ro',
	isa     => Int,
	default => 140
);

has tube_score => (
	is      => 'ro',
	isa     => Int,
	default => 100
);

has _tubes => (
	is      => 'rw',
	isa     => ArrayRef,
	default => sub { [] },
	private => 1
);

has _y     => (is => 'rw', private => 1);
has _cause => (is => 'rw', private => 1);
has _error => (is => 'rw', private => 1);

has _flap => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

has _tilt => (
	is      => 'rw',
	isa     => Int,
	default => 0,
	private => 1
);

has _spawned => (
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

my $spawn = sub {
	my ($self) = @_;
	my $k = $self->_spawned;
	my $hash = Digest::SHA::sha256($self->seed . "floppy:tube:$k");
	my $range = $self->height - 100;
	my $h = unpack('N', substr($hash, 0, 4)) % $range;
	my $top = $range - $h;
	push @{ $self->_tubes }, {
		x          => $self->width,
		gap_top    => $top,
		gap_bottom => $top + $self->gap,
		k          => $k,
	};
	$self->_spawned($k + 1);
	return;
};

my $lay = sub {
	my ($self) = @_;
	$self->_y(int($self->height / 2) - $self->bird_radius);
	$self->_tubes([]);
	$self->_flap(0);
	$self->_tilt(0);
	$self->_spawned(0);
	$self->_score(0);
	$self->_ticks(0);
	$self->_status('ready');
	$self->_cause(undef);
	$self->_error(undef);
	return $self;
};

my $refuse = sub {
	my ($self, $code) = @_;
	$self->_error(Game::Floppy::Error->of($code));
	return 0;
};

my $finish = sub {
	my ($self, $cause, $flapped) = @_;
	$self->_status('finished');
	$self->_cause($cause);
	$self->_flap(0);
	return { moved => 1, flapped => $flapped, passed => 0, died => $cause };
};

sub BUILD {
	my ($self) = @_;

	for my $name (qw/ width height bird_x bird_radius gravity lift tube_every tube_speed tube_width gap tube_score /) {
		my $value = $self->$name;
		Carp::croak("Game::Floppy: $name must be a whole number, not "
			. (defined $value ? "'$value'" : 'undef'))
			unless defined $value && $value =~ /\A[0-9]+\z/;
	}

	Carp::croak('Game::Floppy: a field is at least 200 high') if $self->height < 200;
	Carp::croak('Game::Floppy: a field ' . $self->width . ' wide has no room for a tube')
		if $self->width < $self->bird_x + $self->tube_width + 1;
	for my $name (qw/ bird_radius gravity lift tube_every tube_speed tube_width gap tube_score /) {
		Carp::croak("Game::Floppy: $name is 1 or more") if $self->$name < 1;
	}
	Carp::croak('Game::Floppy: a seed is a string with something in it')
		unless defined $self->seed && length $self->seed;

	$self->$lay;
	return;
}

sub circle_hits_rectangle {
	my ($class, $cx, $cy, $r, $x, $y, $w, $h) = @_;
	my ($hw, $hh) = ($w / 2, $h / 2);
	my $dx = abs($cx - ($x + $hw));
	my $dy = abs($cy - ($y + $hh));
	return 0 if $dx > $hw + $r || $dy > $hh + $r;
	return 1 if $dx <= $hw || $dy <= $hh;
	my ($ex, $ey) = ($dx - $hw, $dy - $hh);
	return $ex * $ex + $ey * $ey <= $r * $r ? 1 : 0;
}

sub flap {
	my ($self) = @_;
	return $self->$refuse('not_active') if $self->_status eq 'finished';
	return $self->$refuse('already_flapped') if $self->_flap;
	$self->_flap(1);
	$self->_error(undef);
	return 1;
}

sub tick {
	my ($self) = @_;

	return { moved => 0 } if $self->_status eq 'finished';

	$self->_status('active');
	$self->_ticks($self->_ticks + 1);

	my $y = $self->_y + $self->gravity;
	my $flapped = 0;
	if ($self->_flap) {
		$y -= $self->lift;
		$self->_flap(0);
		$self->_tilt(-45);
		$flapped = 1;
	}
	$self->_tilt($self->_tilt + 1) if $self->_tilt < 45;
	$self->_y($y);

	return $self->$finish('sky', $flapped) if $y < 0;
	return $self->$finish('ground', $flapped) if $y > $self->height;

	my $tubes = $self->_tubes;
	my ($cx, $r, $w) = ($self->bird_x, $self->bird_radius, $self->tube_width);
	my $passed = 0;
	my @kept;
	for my $tube (@$tubes) {
		$tube->{x} -= $self->tube_speed;
		return $self->$finish('tube', $flapped)
			if $self->circle_hits_rectangle($cx, $y, $r, $tube->{x}, 0, $w, $tube->{gap_top})
			|| $self->circle_hits_rectangle($cx, $y, $r, $tube->{x}, $tube->{gap_bottom}, $w, $self->height);
		if ($tube->{x} + $w < $cx) {
			$self->_score($self->_score + $self->tube_score);
			$passed = 1;
			next;
		}
		push @kept, $tube;
	}
	$self->_tubes(\@kept) if $passed;

	$self->$spawn if $self->_ticks % $self->tube_every == 0;

	return { moved => 1, flapped => $flapped, passed => $passed, died => undef };
}

sub quit {
	my ($self) = @_;
	return 0 if $self->_status eq 'finished';
	$self->$finish('quit', 0);
	return 1;
}

sub reset {
	my ($self) = @_;
	return $self->$lay;
}

sub bird {
	my ($self) = @_;
	return { x => $self->bird_x, y => $self->_y, radius => $self->bird_radius, tilt => $self->_tilt };
}

sub tubes {
	my ($self) = @_;
	return [ map { +{ %$_ } } @{ $self->_tubes } ];
}

sub passed { my ($self) = @_; return int($self->_score / $self->tube_score) }
sub score  { return $_[0]->_score }
sub ticks  { return $_[0]->_ticks }
sub status { return $_[0]->_status }
sub error  { return $_[0]->_error }

sub result {
	my ($self) = @_;
	return undef unless $self->_status eq 'finished';
	return Game::Floppy::Result->new(
		cause => $self->_cause,
		score => $self->_score,
		tubes => $self->passed,
		ticks => $self->_ticks,
	);
}

1;

__END__

=head1 NAME

Game::Floppy - Floppy bird, as an engine

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    use Game::Floppy;

    my $game = Game::Floppy->new(seed => 'anything');

    while ($game->status ne 'finished') {
        $game->flap if $game->bird->{y} > $game->height / 2;
        my $step = $game->tick;
        last if $step->{died};
    }

    print $game->result->stringify, "\n";

Or, from a shell:

    floppy
    floppy --raylib

=head1 DESCRIPTION

A bird falls, a flap lifts it, tubes come from the right with a gap in each,
and the bird dies on a tube, on the ground or off the top. This class is the
game and nothing else: it prints nothing, reads nothing, sleeps never and
calls C<rand> never. Every tube's gap comes from the seed, so the same seed
and the same flaps are the same game twice.

The terminal game is L<Game::Floppy::Terminal> and the window is
L<Game::Floppy::Raylib>. They are separate modules so that this one can be
loaded by anything without pulling either in.

The units are pixels, as release 0.08 drew them, at twenty ticks a second: a
field 516 wide and 400 high, the bird's centre at x 80 starting at y 176,
falling 3 a tick, lifted 30 by a flap on the tick after it is pressed, a
circle of radius 24 against each tube's two rectangles. A tube is 52 wide,
appears every 100 ticks at the right edge, moves left 3 a tick, and has a gap
140 high whose top is between 1 and 300; passing one scores 100.

=head1 METHODS

=head2 new

    my $game = Game::Floppy->new(
        width => 516, height => 400, seed => 'anything',
        bird_x => 80, bird_radius => 24, gravity => 3, lift => 30,
        tube_every => 100, tube_speed => 3, tube_width => 52, gap => 140,
        tube_score => 100,
    );

Every argument has a default, shown. A field is at least 200 high and wide
enough for a tube past the bird. The seed is any string; the default seed
plays the same game every time, so a program that wants a different game
each run makes its own seed.

Arguments are read by name, and a name this class does not know is dropped
in silence: C<new(widthz =E<gt> 9)> builds the default field. Spell them
carefully.

=head2 flap

    $game->flap or warn $game->error->message;

Asks for a flap on the next tick. One flap a tick: a second before the tick
is refused as C<already_flapped>, and any flap on a finished game as
C<not_active>. Returns 1, or 0 with L</error> set.

=head2 tick

    my $step = $game->tick;

One twentieth of a second. The bird falls by C<gravity>, or rises by C<lift>
less C<gravity> when a flap is pending; it dies C<sky> above the field and
C<ground> below it. Each tube then moves left, kills the bird if its circle
touches either pipe, and is passed and scored once it is wholly left of the
bird's centre. A tube appears when the tick count is a multiple of
C<tube_every>. Returns a hash with C<moved>, C<flapped>, C<passed> and
C<died>, the last undefined or C<sky>, C<ground> or C<tube>. A tick on a
finished game moves nothing.

=head2 bird

    my $bird = $game->bird;    # { x, y, radius, tilt }

Where the bird is, as a copy. C<tilt> is the angle a renderer may draw it at:
-45 on a flap, rising by one a tick to 45.

=head2 tubes

    for my $tube (@{ $game->tubes }) { ... }

The tubes on the field, oldest first, each C<{ x, gap_top, gap_bottom, k }>
as a copy. The top pipe is from the top of the field to C<gap_top>, the
bottom pipe from C<gap_bottom> down.

=head2 circle_hits_rectangle

    Game::Floppy->circle_hits_rectangle($cx, $cy, $r, $x, $y, $w, $h);

Whether a circle touches a rectangle, as raylib's C<CheckCollisionCircleRec>
decides it: touching counts.

=head2 width, height, seed, bird_x, bird_radius, gravity, lift, tube_every, tube_speed, tube_width, gap, tube_score

The arguments C<new> was given, or their defaults.

=head2 score, passed, ticks, status

The score, tubes passed, ticks taken, and C<ready>, C<active> or C<finished>.

=head2 error

The L<Game::Floppy::Error> from the last refused flap, or undefined.

=head2 result

A L<Game::Floppy::Result> once the game has finished, else undefined.

=head2 quit

Finishes the game with the cause C<quit>. Returns 1, or 0 if it had already
finished.

=head2 reset

Puts the bird back at the start with the same seed, so the same game can be
played again.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-floppy at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Floppy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Floppy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Floppy>

=item * Search CPAN

L<https://metacpan.org/release/Game-Floppy>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
