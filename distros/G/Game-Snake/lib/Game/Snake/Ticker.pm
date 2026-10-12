package Game::Snake::Ticker;

use 5.014;
use strict;
use warnings;

use Carp ();
use Time::HiRes ();
use Object::Proto::Sugar -types;

our $VERSION = '0.12';

has clock => (
	is      => 'ro',
	isa     => Any,
	default => sub { \&Time::HiRes::time }
);

has next => (is => 'rw');

has ticks => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has late => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;
	Carp::croak('Game::Snake::Ticker: the clock is a code reference returning seconds')
		unless ref $self->clock eq 'CODE';
	return;
}

sub start {
	my ($self, $period) = @_;
	$self->next($self->clock->() + $period);
	return $self;
}

sub remaining {
	my ($self) = @_;
	return 0 unless defined $self->next;
	my $left = $self->next - $self->clock->();
	return $left > 0 ? $left : 0;
}

sub due {
	my ($self) = @_;
	return $self->remaining <= 0 ? 1 : 0;
}

sub tick {
	my ($self, $period) = @_;
	my $now = $self->clock->();
	my $next = (defined $self->next ? $self->next : $now) + $period;
	if ($next < $now) {
		$next = $now + $period;
		$self->late($self->late + 1);
	}
	$self->next($next);
	$self->ticks($self->ticks + 1);
	return $self;
}

1;

__END__

=head1 NAME

Game::Snake::Ticker - when the next tick is due

=head1 VERSION

Version 0.12

=head1 SYNOPSIS

    my $ticker = Game::Snake::Ticker->new;
    $ticker->start(1 / $game->speed);

    while (...) {
        wait_for_a_key($ticker->remaining);
        if ($ticker->due) {
            $game->tick;
            $ticker->tick(1 / $game->speed);
        }
    }

=head1 DESCRIPTION

The schedule both front ends tick the engine on. It is given the period on
every call because the game's speed rises as it goes.

Lost time is dropped, never caught up: a tick that is overdue fires once and
the schedule restarts from now, counted in C<late>. A burst of unseen moves
after a stall is how a snake game kills you for the machine's sins.

=head1 METHODS

=head2 new

    Game::Snake::Ticker->new(clock => sub { ... });

C<clock> is a code reference returning seconds; the default reads
L<Time::HiRes>. A test hands in a clock of its own.

=head2 start

    $ticker->start($period);

The next tick is one period from now.

=head2 remaining

Seconds until the next tick, never negative.

=head2 due

True once the next tick's time has come.

=head2 tick

    $ticker->tick($period);

Counts a tick and moves the schedule on by one period, or, when that time
has already passed, to one period from now.

=head2 clock, next, ticks, late

The clock, when the next tick is due, how many ticks have been counted, and
how many were late.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
