package Game::Terminal::Kit::Ticker;

use 5.014;
use strict;
use warnings;

use Time::HiRes ();
use Object::Proto::Sugar -types;

our $VERSION = '0.05';

has clock => (
	is => 'rw',
	isa => CodeRef
);

has next => (
	is => 'rw'
);

has [qw/ticks late/] => (
	is => 'rw',
	isa => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;
	$self->clock(\&Time::HiRes::time) unless $self->clock;
	return $self;
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

Game::Terminal::Kit::Ticker - when the next step of a game that moves is due

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Ticker;

    my $ticker = Game::Terminal::Kit::Ticker->new;
    $ticker->start(1 / $speed);

    while ($playing) {
        unless ($ticker->due) {
            my $key = $keys->read_key($ticker->remaining);
            steer($key) if defined $key;
            next;
        }
        advance();
        $ticker->tick(1 / $speed);
        draw();
    }

=head1 DESCRIPTION

A game that moves on its own steps at a steady rate however long each frame
took to draw and however many keys were pressed in between. The ticker keeps
the time of the next step. Between steps the game waits on the keyboard for
exactly as long as is left, so a key is acted on at once and a step is never
late for the sake of one.

Each step is scheduled from when the last one was due, not from when it
happened, so the rate does not drift. When the game falls a whole step
behind, the schedule starts again from now and the step is counted in
L</late>: a burst of steps nobody saw is how a game punishes the player for
a slow machine.

=head1 ATTRIBUTES

=head2 clock

A code reference returning the time in seconds. C<Time::HiRes::time> by
default; a test gives its own.

=head2 next

When the next step is due, by that clock.

=head2 ticks

How many steps have been taken.

=head2 late

How many of them were more than a whole step behind.

=head1 METHODS

=head2 start

    $ticker->start($period);

The first step is due one period from now. Returns the ticker.

=head2 remaining

Seconds until the next step is due; 0 when it is due, overdue, or the ticker
was never started. Never negative.

=head2 due

True when nothing remains.

=head2 tick

    $ticker->tick($period);

A step has been taken; the next is due one period after this one was. The
period is given each time because a game speeds up. Returns the ticker.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Keys>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
