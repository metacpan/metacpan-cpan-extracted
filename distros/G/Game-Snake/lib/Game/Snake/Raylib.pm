package Game::Snake::Raylib;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use File::Basename ();
use File::Spec ();
use Time::HiRes ();
use Object::Proto::Sugar -types;

use Game::Snake;
use Game::Snake::Bot;
use Game::Snake::Ticker;

our $VERSION = '0.12';

my $WHY;

sub available {
	return 1 if eval { require Raylib::FFI; require Raylib::Color; 1 };
	my $why = $@;
	$why =~ s/ at \S+ line \d+\.?\s*//g;
	$why =~ s/\n.*//s;
	$why = 'the window needs Raylib::FFI, which is not installed: cpanm Raylib::FFI, or play in the terminal without --raylib'
		if $why =~ /\ACan't locate Raylib/;
	$why =~ s/\s+\z//;
	$WHY = $why;
	return 0;
}

sub why_not { return $WHY }

my %KEY = (
	265 => 'up',    264 => 'down',  263 => 'left', 262 => 'right',
	87  => 'up',    83  => 'down',  65  => 'left', 68  => 'right',
	75  => 'up',    74  => 'down',  72  => 'left', 76  => 'right',
	80  => 'pause', 32  => 'pause',
	81  => 'quit',  256 => 'quit',
	257 => 'again',
);

my %TILE = (
	head => { up => [ 192, 0 ],   right => [ 256, 0 ],   left => [ 192, 64 ],  down => [ 256, 64 ] },
	tail => { up => [ 192, 128 ], right => [ 256, 128 ], left => [ 192, 192 ], down => [ 256, 192 ] },
	body => { horizontal => [ 64, 0 ], vertical => [ 128, 64 ] },
	bend => {
		'left:down'  => [ 0, 0 ],     'up:right'   => [ 0, 0 ],
		'right:down' => [ 128, 0 ],   'up:left'    => [ 128, 0 ],
		'left:up'    => [ 0, 64 ],    'down:right' => [ 0, 64 ],
		'right:up'   => [ 128, 128 ], 'down:left'  => [ 128, 128 ],
	},
	food => [ 0, 192 ],
);

my $TILE_SIZE = 64;

sub key_for {
	my ($class, $code) = @_;
	return defined $code ? $KEY{$code} : undef;
}

my $straight = sub {
	my ($segment) = @_;
	return $TILE{body}{ $segment->{dir} =~ /\A(?:left|right)\z/ ? 'horizontal' : 'vertical' };
};

sub tile_for {
	my ($class, $kind, $segment) = @_;
	return $TILE{food} if $kind eq 'food';
	return $TILE{head}{ $segment->{dir} } if $kind eq 'head';
	return $TILE{tail}{ $segment->{bend} || $segment->{dir} } if $segment->{last};
	return $TILE{bend}{ "$segment->{dir}:$segment->{bend}" } || $straight->($segment) if $segment->{bend};
	return $straight->($segment);
}

sub tiles { return { %TILE } }

sub sheet {
	return File::Spec->catfile(File::Basename::dirname(__FILE__), 'resources', 'snake-graphics.png');
}

has cols => (is => 'ro');
has rows => (is => 'ro');

has seed => (
	is      => 'ro',
	isa     => Str,
	default => ''
);

has level => (
	is      => 'ro',
	isa     => Int,
	default => 2
);

has watch => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has cell => (
	is      => 'ro',
	isa     => Int,
	default => 20
);

has top => (
	is      => 'ro',
	isa     => Int,
	default => 24
);

has fps => (
	is      => 'ro',
	isa     => Int,
	default => 60
);

has title => (
	is      => 'ro',
	isa     => Str,
	default => 'Snake'
);

has max_ticks => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has game => (
	is  => 'rw',
	isa => Object
);

has clock => (
	is      => 'ro',
	isa     => Any,
	default => sub { \&Time::HiRes::time }
);

has ticker => (
	is  => 'rw',
	isa => Object
);

has frames => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has refused => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has high => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;

	Game::Snake::Bot->describe($self->level);

	for my $name (qw/ cols rows cell top fps max_ticks /) {
		my $value = $self->$name;
		next unless defined $value;
		Carp::croak("Game::Snake::Raylib: $name must be a whole number, not '$value'")
			unless $value =~ /\A[0-9]+\z/;
	}
	Carp::croak('Game::Snake::Raylib: a cell is at least 4 pixels') if $self->cell < 4;
	Carp::croak('Game::Snake::Raylib: the frame rate is at least 1') if $self->fps < 1;
	Carp::croak('Game::Snake::Raylib: the clock is a code reference')
		unless ref $self->clock eq 'CODE';

	unless ($self->game) {
		my $seed = $self->seed;
		$seed = Digest::SHA::sha256_hex(join ':', $self->clock->(), $$)
			unless CORE::length $seed;
		$self->game(Game::Snake->new(
			cols => (defined $self->cols ? $self->cols : 40),
			rows => (defined $self->rows ? $self->rows : 28),
			seed => $seed,
		));
	}

	$self->ticker(Game::Snake::Ticker->new(clock => $self->clock)) unless $self->ticker;

	return;
}

my $rectangle = sub {
	my ($x, $y, $w, $h) = @_;
	return Raylib::FFI::Rectangle->new(x => $x, y => $y, width => $w, height => $h);
};

my $blit = sub {
	my ($self, $sheet, $tile, $x, $y) = @_;
	my $cell = $self->cell;
	Raylib::FFI::DrawTexturePro(
		$sheet,
		$rectangle->($tile->[0], $tile->[1], $TILE_SIZE, $TILE_SIZE),
		$rectangle->($cell * $x, $self->top + $cell * $y, $cell, $cell),
		Raylib::FFI::Vector2D->new(x => 0, y => 0),
		0,
		Raylib::Color::WHITE(),
	);
	return;
};

my $draw = sub {
	my ($self, $sheet, $paused) = @_;
	my $game = $self->game;
	my $cell = $self->cell;
	my ($cols, $rows) = ($game->cols, $game->rows);

	Raylib::FFI::ClearBackground(Raylib::Color::BLACK());

	for my $y (0 .. $rows - 1) {
		for my $x (0 .. $cols - 1) {
			Raylib::FFI::DrawRectangleRec(
				$rectangle->($cell * $x, $self->top + $cell * $y, $cell, $cell),
				($x + $y) % 2 ? Raylib::Color::GRAY() : Raylib::Color::DARKGRAY(),
			);
		}
	}

	if (my $food = $game->food) {
		$self->$blit($sheet, $TILE{food}, @$food);
	}

	my $segments = $game->segments;
	for my $i (0 .. $#$segments) {
		my $segment = $segments->[$i];
		my $tile = __PACKAGE__->tile_for($i == 0 ? 'head' : 'body', $segment);
		$self->$blit($sheet, $tile, $segment->{x}, $segment->{y});
	}

	Raylib::FFI::DrawText(
		sprintf('Score: %d   High score: %d   Speed: %d/s', $game->score, $self->high, $game->speed),
		10, 2, 20, Raylib::Color::WHITE());

	my ($w, $h) = ($cell * $cols, $self->top + $cell * $rows);
	if ($game->status eq 'finished') {
		Raylib::FFI::DrawText('Game Over', int($w / 2) - 110, int($h / 2) - 40, 40, Raylib::Color::WHITE());
		Raylib::FFI::DrawText($game->result->stringify, int($w / 2) - 160, int($h / 2) + 10, 20, Raylib::Color::WHITE());
		Raylib::FFI::DrawText('Enter plays again, q quits', int($w / 2) - 130, int($h / 2) + 40, 20, Raylib::Color::WHITE());
	}
	elsif ($paused) {
		Raylib::FFI::DrawText('Paused', int($w / 2) - 60, int($h / 2) - 20, 40, Raylib::Color::WHITE());
	}
	return;
};

my $bot_turn = sub {
	my ($self) = @_;
	my $game = $self->game;
	my $direction = Game::Snake::Bot->choose($game, level => $self->level);
	$game->turn($direction) if defined $direction && $direction ne $game->heading;
	return;
};

sub start {
	my ($self) = @_;
	return undef unless $self->available;

	my $game = $self->game;
	my $cell = $self->cell;
	Raylib::FFI::InitWindow($cell * $game->cols, $self->top + $cell * $game->rows, $self->title);
	Raylib::FFI::SetTargetFPS($self->fps);
	Raylib::FFI::SetExitKey(0);
	my $sheet = Raylib::FFI::LoadTexture($self->sheet);

	my $ticker = $self->ticker->start(1 / $game->speed);
	my ($paused, $quit) = (0, 0);

	until ($quit || Raylib::FFI::WindowShouldClose()) {
		while (my $code = Raylib::FFI::GetKeyPressed()) {
			my $key = $KEY{$code} or next;
			if ($key eq 'quit') {
				$quit = 1;
			}
			elsif ($key eq 'pause') {
				$paused = !$paused;
				$ticker->start(1 / $game->speed) unless $paused;
			}
			elsif ($key eq 'again') {
				next unless $game->status eq 'finished';
				$game->reset;
				$paused = 0;
				$ticker->start(1 / $game->speed);
			}
			elsif (!$self->watch && $game->status ne 'finished') {
				$self->refused($self->refused + 1) unless $game->turn($key);
			}
		}

		if (!$paused && $game->status ne 'finished' && $ticker->due) {
			$self->$bot_turn if $self->watch;
			$game->tick;
			$ticker->tick(1 / $game->speed);
			$self->high($game->score) if $game->score > $self->high;
		}

		last if $self->max_ticks && $ticker->ticks >= $self->max_ticks;

		Raylib::FFI::BeginDrawing();
		$self->$draw($sheet, $paused);
		Raylib::FFI::EndDrawing();
		$self->frames($self->frames + 1);
	}

	Raylib::FFI::UnloadTexture($sheet);
	Raylib::FFI::CloseWindow();

	$game->quit unless $game->status eq 'finished';
	return $game->result;
}

1;

__END__

=head1 NAME

Game::Snake::Raylib - snake in a window, when raylib is there

=head1 VERSION

Version 0.12

=head1 SYNOPSIS

    use Game::Snake::Raylib;

    if (Game::Snake::Raylib->available) {
        my $result = Game::Snake::Raylib->new(seed => 'anything')->start;
    }
    else {
        warn Game::Snake::Raylib->why_not;
    }

Or, from a shell:

    snake --raylib

=head1 DESCRIPTION

The game of 0.11, drawn from the same sprite sheet at the same size (a 20
pixel cell under a score line), with the engine and the bot of this release
behind it. L<Raylib::FFI> is loaded when the window is asked for, never when
this module is, so the module compiles and the distribution's tests run on a
machine without raylib. C<Raylib::FFI> itself needs perl 5.38 or later; the
rest of this distribution does not.

Loading C<Raylib::FFI> prints a warning that C<builtin::export_lexically> is
experimental, and one for each raylib function the installed library lacks.
Those are its, not ours, and cannot be silenced from here.

The window runs at C<fps> frames a second and ticks the engine when the
engine's speed says so, at most once a frame, so a key is seen on the frame
it is pressed whatever the speed. 0.11 ran the window at the snake's speed
and sampled the keys once a move.

Arrows, wasd and hjkl steer; p and space pause; Enter plays again after a
death; q, Escape or closing the window quits.

=head1 CLASS METHODS

=head2 available

True when L<Raylib::FFI> and L<Raylib::Color> can be loaded. False with
L</why_not> set.

=head2 why_not

One sentence on why the window cannot open, with no file and line in it.

=head2 tile_for

    my ($x, $y) = @{ Game::Snake::Raylib->tile_for('head', $segment) };

The top left corner of the 64 pixel tile on the sheet for a segment of
L<Game::Snake/segments>, or for C<food>. The tail's tile follows its C<bend>
when it has one and its C<dir> otherwise; a body segment with a C<bend> gets
the corner tile for that pair, or the straight tile for a pair that cannot
occur.

=head2 tiles

The whole tile table.

=head2 key_for

    my $name = Game::Snake::Raylib->key_for(265);    # up

The name of a key code: a direction, C<pause>, C<quit>, C<again> or
undefined.

=head2 sheet

The path of the sprite sheet.

=head1 METHODS

=head2 new

    Game::Snake::Raylib->new(cols => 40, rows => 28, seed => '...', level => 2,
        watch => 0, cell => 20, top => 24, fps => 60, title => 'Snake', max_ticks => 0);

Every argument has a default, shown. A missing seed is made fresh.

=head2 start

Opens the window, plays, closes the window and returns the game's
L<Game::Snake::Result>, or undefined when raylib is not available. The high
score for the run of the program is kept in C<high>.

=head2 cols, rows, seed, level, watch, cell, top, fps, title, max_ticks, game, clock, ticker, frames, refused, high

The arguments, the game, the clock and the ticker, and the counts.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
