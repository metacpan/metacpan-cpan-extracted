package Game::Floppy::Raylib;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use File::Basename ();
use File::Spec ();
use Time::HiRes ();
use Object::Proto::Sugar -types;

use Game::Floppy;
use Game::Floppy::Bot;
use Game::Floppy::Ticker;

our $VERSION = '0.09';

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
	32  => 'flap', 265 => 'flap', 257 => 'flap', 87 => 'flap', 75 => 'flap',
	80  => 'pause',
	81  => 'quit', 256 => 'quit',
);

my $INSET = 20;

my %SPRITE = (
	background => [ 288, 512 ],
	bird       => [ 136, 24 ],
	pipe       => [ 52, 320 ],
);

my ($BIRD_FRAMES, $BIRD_W, $BIRD_H) = (4, 34, 24);

sub key_for {
	my ($class, $code) = @_;
	return defined $code ? $KEY{$code} : undef;
}

sub inset { return $INSET }

sub frame_for {
	my ($class, $ticks) = @_;
	return $ticks % $BIRD_FRAMES;
}

sub source_for {
	my ($class, $frame) = @_;
	return [ $BIRD_W * ($frame % $BIRD_FRAMES), 0, $BIRD_W, $BIRD_H ];
}

sub pipe_at {
	my ($class, $tube) = @_;
	my ($w, $h) = @{ $SPRITE{pipe} };
	return {
		top    => [ $tube->{x} + $w, $tube->{gap_top} + $INSET, 180 ],
		bottom => [ $tube->{x}, $tube->{gap_bottom} - $INSET, 0 ],
	};
}

sub sheet {
	my ($class, $name) = @_;
	my %file = (background => 'background-day.png', bird => 'bluebird.png', pipe => 'pipe-green.png');
	Carp::croak("Game::Floppy::Raylib: '" . (defined $name ? $name : 'undef') . "' is not a sprite")
		unless defined $name && $file{$name};
	return File::Spec->catfile(File::Basename::dirname(__FILE__), 'resources', $file{$name});
}

sub sprite_size {
	my ($class, $name) = @_;
	return $SPRITE{$name} ? [ @{ $SPRITE{$name} } ] : undef;
}

has seed => (
	is      => 'ro',
	isa     => Str,
	default => ''
);

has level => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has watch => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has fps => (
	is      => 'ro',
	isa     => Int,
	default => 20
);

has title => (
	is      => 'ro',
	isa     => Str,
	default => 'Floppy'
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

has best => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;

	Game::Floppy::Bot->describe($self->level);

	for my $name (qw/ fps max_ticks /) {
		my $value = $self->$name;
		Carp::croak("Game::Floppy::Raylib: $name must be a whole number, not '$value'")
			unless defined $value && $value =~ /\A[0-9]+\z/;
	}
	Carp::croak('Game::Floppy::Raylib: the frame rate is at least 1') if $self->fps < 1;
	Carp::croak('Game::Floppy::Raylib: the clock is a code reference')
		unless ref $self->clock eq 'CODE';

	unless ($self->game) {
		my $seed = $self->seed;
		$seed = Digest::SHA::sha256_hex(join ':', $self->clock->(), $$)
			unless CORE::length $seed;
		$self->game(Game::Floppy->new(seed => $seed));
	}

	$self->ticker(Game::Floppy::Ticker->new(clock => $self->clock)) unless $self->ticker;

	return;
}

my $rectangle = sub {
	my ($x, $y, $w, $h) = @_;
	return Raylib::FFI::Rectangle->new(x => $x, y => $y, width => $w, height => $h);
};

my $origin;

my $draw = sub {
	my ($self, $textures, $paused) = @_;
	my $game = $self->game;
	my ($width, $height) = ($game->width, $game->height);

	Raylib::FFI::ClearBackground(Raylib::Color::BLACK());

	my ($bw, $bh) = @{ $SPRITE{background} };
	Raylib::FFI::DrawTexturePro($textures->{background},
		$rectangle->(0, 0, $bw, $bh), $rectangle->(0, 0, $width, $height),
		$origin, 0, Raylib::Color::WHITE());

	my ($pw, $ph) = @{ $SPRITE{pipe} };
	for my $tube (@{ $game->tubes }) {
		my $at = __PACKAGE__->pipe_at($tube);
		for my $end (qw/ top bottom /) {
			my ($x, $y, $rotation) = @{ $at->{$end} };
			Raylib::FFI::DrawTexturePro($textures->{pipe},
				$rectangle->(0, 0, $pw, $ph), $rectangle->($x, $y, $pw, $ph),
				$origin, $rotation, Raylib::Color::WHITE());
		}
	}

	my $bird = $game->bird;
	my $source = __PACKAGE__->source_for(__PACKAGE__->frame_for($game->ticks));
	Raylib::FFI::DrawTexturePro($textures->{bird},
		$rectangle->(@$source), $rectangle->($bird->{x}, $bird->{y}, $bird->{radius}, $bird->{radius}),
		$origin, $bird->{tilt}, Raylib::Color::WHITE());

	Raylib::FFI::DrawText(sprintf('Current Score: %d High Score: %d', $game->score, $self->best),
		10, 10, 22, Raylib::Color::WHITE());

	if ($game->status eq 'finished') {
		Raylib::FFI::DrawText('Game Over', 10, 40, 22, Raylib::Color::WHITE());
		Raylib::FFI::DrawText($game->result->stringify, 10, 70, 22, Raylib::Color::WHITE());
		Raylib::FFI::DrawText('Press space to try again', 10, 100, 22, Raylib::Color::WHITE());
	}
	elsif ($paused) {
		Raylib::FFI::DrawText('Paused', 10, 40, 22, Raylib::Color::WHITE());
	}
	return;
};

my $flap = sub {
	my ($self) = @_;
	my $game = $self->game;
	if ($game->status eq 'finished') {
		$game->reset;
		$self->ticker->start(1 / 20);
		return;
	}
	return if $self->watch;
	$self->refused($self->refused + 1) unless $game->flap;
	return;
};

sub start {
	my ($self) = @_;
	return undef unless $self->available;

	my $game = $self->game;
	my $period = 1 / 20;
	$origin ||= Raylib::FFI::Vector2D->new(x => 0, y => 0);

	Raylib::FFI::InitWindow($game->width, $game->height, $self->title);
	Raylib::FFI::SetTargetFPS($self->fps);
	Raylib::FFI::SetExitKey(0);
	my %textures = map { $_ => Raylib::FFI::LoadTexture($self->sheet($_)) } qw/ background bird pipe /;

	my $ticker = $self->ticker->start($period);
	my ($paused, $quit) = (0, 0);

	until ($quit || Raylib::FFI::WindowShouldClose()) {
		while (my $code = Raylib::FFI::GetKeyPressed()) {
			my $key = $KEY{$code} or next;
			if ($key eq 'quit') {
				$quit = 1;
			}
			elsif ($key eq 'pause') {
				$paused = !$paused;
				$ticker->start($period) unless $paused;
			}
			else {
				$self->$flap;
			}
		}
		$self->$flap if Raylib::FFI::IsMouseButtonReleased(0);

		if (!$paused && $game->status ne 'finished' && $ticker->due) {
			$game->flap if $self->watch && Game::Floppy::Bot->choose($game, level => $self->level);
			$game->tick;
			$ticker->tick($period);
			$self->best($game->score) if $game->score > $self->best;
		}

		last if $self->max_ticks && $ticker->ticks >= $self->max_ticks;

		Raylib::FFI::BeginDrawing();
		$self->$draw(\%textures, $paused);
		Raylib::FFI::EndDrawing();
		$self->frames($self->frames + 1);
	}

	Raylib::FFI::UnloadTexture($_) for values %textures;
	Raylib::FFI::CloseWindow();

	$game->quit unless $game->status eq 'finished';
	return $game->result;
}

1;

__END__

=head1 NAME

Game::Floppy::Raylib - Floppy in a window, when raylib is there

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Game::Floppy::Raylib;

    if (Game::Floppy::Raylib->available) {
        my $result = Game::Floppy::Raylib->new(seed => 'anything')->start;
    }
    else {
        warn Game::Floppy::Raylib->why_not;
    }

Or, from a shell:

    floppy --raylib

=head1 DESCRIPTION

The window of release 0.08, drawn from the same three sprites at the same
size, with the engine and the bot of this release behind it. L<Raylib::FFI>
is loaded when the window is asked for, never when this module is, so the
module compiles and the distribution's tests run on a machine without
raylib. C<Raylib::FFI> itself needs perl 5.38 or later; the rest of this
distribution does not. Loading it prints a warning that
C<builtin::export_lexically> is experimental and one for each raylib
function the installed library lacks; those are its, not ours, and cannot be
silenced from here. Raylib also logs to the terminal of its own accord.

The window runs at twenty frames a second and ticks the engine once a frame,
which is exactly 0.08's loop. Space, up, Enter, w and k flap, as does a
mouse release; p pauses; q, Escape or closing the window quits; after a
death, space or a click plays again.

0.08 drew its pipes 20 pixels inside the gap it collided with and its bird
from the top-left corner of the circle it collided with. The engine
transcribes the collision; this module draws 0.08's picture over it, so the
window looks and plays as 0.08 did. The inset is one constant, C<inset>.

=head1 CLASS METHODS

=head2 available, why_not

Whether L<Raylib::FFI> and L<Raylib::Color> can be loaded, and one sentence
on why not, with no file and line in it.

=head2 frame_for, source_for

    my $frame = Game::Floppy::Raylib->frame_for($game->ticks);    # 0 .. 3
    my ($x, $y, $w, $h) = @{ Game::Floppy::Raylib->source_for($frame) };

The bird's frame for a tick count, cycling through the four on the sheet,
and the sheet rectangle for a frame.

=head2 pipe_at

    my $at = Game::Floppy::Raylib->pipe_at($tube);    # { top => [x, y, 180], bottom => [x, y, 0] }

Where the two pipe sprites are drawn for a tube of L<Game::Floppy/tubes>,
with their rotation: the top pipe rotated 180 about its drawn corner, as 0.08
drew it, 20 pixels inside each lip of the collision gap.

=head2 key_for

The name of a key code: C<flap>, C<pause>, C<quit> or undefined.

=head2 sheet, sprite_size, inset

The path of a sprite (C<background>, C<bird> or C<pipe>), its size in pixels,
and the inset.

=head1 METHODS

=head2 new

    Game::Floppy::Raylib->new(seed => '...', level => 3, watch => 0, fps => 20, title => 'Floppy', max_ticks => 0);

Every argument has a default, shown. A missing seed is made fresh.

=head2 start

Opens the window, plays until a quit or the cap, closes the window and
returns the last game's L<Game::Floppy::Result>, or undefined when raylib is
not available.

=head2 seed, level, watch, fps, title, max_ticks, game, clock, ticker, frames, refused, best

The arguments, the game, the clock and the ticker, and the counts.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
