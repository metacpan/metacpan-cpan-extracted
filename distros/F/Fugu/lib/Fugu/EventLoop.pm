# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::EventLoop;
our $VERSION = '0.1.2';

use IO::Select;
use Time::HiRes ();

use Fugu::Log;

# Fugu::EventLoop - one select loop for a daemon with one process.
#
# A daemon watches descriptors and it does work on a schedule. Written
# by hand, those two become one while(1) with a poll interval chosen
# for the schedule, an epoch comparison for each periodic job, and no
# way out but exit inside a signal handler. This module is that loop,
# written once.
#
# The loop is registrations. A caller adds a descriptor with a
# callback, adds timers, and calls run. The select timeout comes from
# the next timer deadline, so a loop with a one-second job does not
# wake ten times a second, and a loop with a 250 ms job does not miss
# it by an interval.
#
# There are no threads, per the project rules. A callback runs in the
# process that called run, between passes, and nothing else runs while
# it does. A callback that blocks blocks the loop.

# The longest a pass ever sleeps, even with no timer due. The loop
# must come back often enough to see a stop request and an interrupt
# flag, and a caller must not have to add a timer to get that.
use constant MAX_TIMEOUT => 1;

# Fugu::EventLoop->new(%args):
#	log    => $logger	default Fugu::Log->default
#	signal => $signal	a Fugu::Signal whose interrupt flag
#				ends the loop after the current pass
sub new ( $class, %args )
{
	return bless {
		select   => IO::Select->new,
		handlers => {},
		timers   => [],
		next_id  => 1,
		running  => 0,
		log      => $args{log},
		signal   => $args{signal},
	}, $class;
}

# $self->add_fd($fh, %args):
#	Watch a descriptor. The loop calls the read callback with the
#	handle when it is readable.
#
#	%args:
#		read => $code	the callback, necessary
#
#	A second add_fd on the same handle replaces the callback. A
#	caller that re-registers thus does not get two calls for one
#	readable event.
sub add_fd ( $self, $fh, %args )
{
	my $read = $args{read};
	die 'read callback required' unless ref $read eq 'CODE';

	my $key = fileno $fh;
	die 'handle has no descriptor' unless defined $key;

	$self->{select}->remove($fh) if exists $self->{handlers}{$key};
	$self->{select}->add($fh);
	$self->{handlers}{$key} = { handle => $fh, read => $read };

	return $self;
}

# $self->remove_fd($fh):
#	Stop watching a descriptor. The loop does not close it: the
#	owner of a handle closes it.
sub remove_fd ( $self, $fh )
{
	my $key = fileno $fh;

	$self->{select}->remove($fh);
	delete $self->{handlers}{$key} if defined $key;

	return $self;
}

# $self->every($seconds, $code):
#	Run the callback every $seconds. The method returns a handle
#	for cancel.
sub every ( $self, $seconds, $code )
{
	return $self->_add_timer( $seconds, $code, 1 );
}

# $self->after($seconds, $code):
#	Run the callback one time, $seconds from now. The method
#	returns a handle for cancel.
#
#	A caller that schedules the same work again before it runs gets
#	two runs. Keep the handle and cancel, or check it first.
sub after ( $self, $seconds, $code )
{
	return $self->_add_timer( $seconds, $code, 0 );
}

# $self->cancel($handle):
#	Drop a timer. Cancelling a timer that already ran, or one that
#	was cancelled, does nothing. The method returns 1 when it
#	removed a timer and 0 when there was none.
sub cancel ( $self, $handle )
{
	return 0 unless defined $handle;

	my $before = scalar @{ $self->{timers} };
	$self->{timers} = [ grep { $_->{id} != $handle } @{ $self->{timers} } ];

	return $before == scalar @{ $self->{timers} } ? 0 : 1;
}

# $self->stop:
#	End the loop after the current pass. A callback calls this to
#	stop the loop it runs inside.
sub stop ($self)
{
	$self->{running} = 0;
	return $self;
}

# $self->is_running:
#	Report if the loop is between the start and the end of run.
sub is_running ($self)
{
	return $self->{running};
}

# $self->signal($manager):
#	Set or read the Fugu::Signal whose interrupt flag ends the
#	loop. A caller that builds the loop before the manager uses
#	this instead of the constructor argument.
sub signal ( $self, @manager )
{
	$self->{signal} = $manager[0] if @manager;

	return $self->{signal};
}

# $self->run:
#	Watch and dispatch until something stops the loop. The method
#	returns the object.
#
#	Three things stop it: a callback that calls stop, an interrupt
#	flag on the signal manager the caller gave, and a loop with no
#	descriptor and no timer left, which has nothing to wait for.
sub run ($self)
{
	$self->{running} = 1;

	while ( $self->{running} ) {
		last if $self->{signal} && $self->{signal}->interrupted;
		last unless $self->{select}->count || @{ $self->{timers} };

		$self->_pass;
	}
	$self->{running} = 0;

	return $self;
}

# $self->_pass:
#	One pass: wait for a descriptor or the next deadline, dispatch
#	what is readable, then run what is due.
sub _pass ($self)
{
	my @ready = $self->{select}->can_read( $self->_timeout );

	for my $fh (@ready) {
		my $key     = fileno $fh;
		my $handler = defined $key ? $self->{handlers}{$key} : undef;

		# A callback earlier in this pass can have removed the
		# handle. can_read already gave the list.
		next unless $handler;

		$self->_call( $handler->{read}, 'read handler', $fh );
	}

	$self->_run_timers;

	return;
}

# $self->_timeout:
#	How long the next select may wait. This is the time to the
#	nearest deadline, bounded so that a loop with no timer still
#	comes back and sees a stop request.
sub _timeout ($self)
{
	my $timeout = MAX_TIMEOUT;

	my $now = Time::HiRes::time();
	for my $timer ( @{ $self->{timers} } ) {
		my $wait = $timer->{deadline} - $now;
		$timeout = $wait if $wait < $timeout;
	}

	return $timeout > 0 ? $timeout : 0;
}

# $self->_run_timers:
#	Run every timer that is due, in deadline order. A periodic
#	timer is rescheduled before its callback runs, so a callback
#	that cancels the timer wins.
#
#	The next deadline is one interval from now, not from the old
#	deadline. A callback that overran must not then run again at
#	once, several times, to catch up.
sub _run_timers ($self)
{
	my $now = Time::HiRes::time();
	my @due =
	    sort { $a->{deadline} <=> $b->{deadline} }
	    grep { $_->{deadline} <= $now } @{ $self->{timers} };

	for my $timer (@due) {

		# An earlier callback in this pass can have cancelled it
		next unless grep { $_ == $timer } @{ $self->{timers} };

		if ( $timer->{repeat} ) {
			$timer->{deadline} =
			    Time::HiRes::time() + $timer->{interval};
		}
		else {
			$self->cancel( $timer->{id} );
		}

		$self->_call( $timer->{code}, 'timer' );
	}

	return;
}

# $self->_add_timer($seconds, $code, $repeat):
#	Register a timer and return its handle.
sub _add_timer ( $self, $seconds, $code, $repeat )
{
	die 'timer callback required' unless ref $code eq 'CODE';
	die 'timer interval must be positive'
	    unless defined $seconds && $seconds > 0;

	my $id = $self->{next_id}++;
	push @{ $self->{timers} },
	    {
		id       => $id,
		interval => $seconds,
		deadline => Time::HiRes::time() + $seconds,
		repeat   => $repeat ? 1 : 0,
		code     => $code,
	    };

	return $id;
}

# $self->_call($code, $what, @args):
#	Run one callback. A callback that dies must not take the daemon
#	with it: the loop logs the reason and carries on. A daemon that
#	exits because one connection misbehaved is a daemon that a peer
#	can stop.
sub _call ( $self, $code, $what, @args )
{
	eval { $code->(@args); 1 } or do {
		my $error = $@ || 'unknown error';
		chomp $error;
		$self->_log->error( 'Event loop %s died: %s', $what, $error );
	};

	return;
}

# $self->_log:
#	The logger of this loop.
sub _log ($self)
{
	return $self->{log} // Fugu::Log->default;
}

1;
