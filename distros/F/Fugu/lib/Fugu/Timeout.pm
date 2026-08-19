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

package Fugu::Timeout;
our $VERSION = '0.1.2';

use Fugu::Signal;
use Time::HiRes qw(time);

# Fugu::Timeout - run something under a time limit.
#
# The module holds the two ways to do that: bounded sets an alarm, and
# wait_until polls. An alarm interrupts a blocking syscall that a poll
# loop cannot reach, and a poll loop leaves a signal handler alone.
# Neither can do the other's job, so both are here.
#
# The functions are plain functions, not methods. They keep no state
# and they never log.

# How often wait_until looks again when the caller gives no interval.
use constant DEFAULT_INTERVAL => 0.25;

# bounded($seconds, $code):
#	Run $code under a hard wall-clock deadline. A blocked call in
#	$code cannot stall the caller for longer than $seconds.
#
#	The function returns the return value of $code. It returns
#	undef when the deadline elapsed. A die inside $code propagates,
#	with the alarm already cleared.
#
#	The guard is an alarm, so it interrupts a blocking syscall that
#	a poll loop cannot reach. That is why it exists next to
#	wait_until, which cannot.
sub bounded ( $seconds, $code )
{
	my $result;
	my $ok = eval {
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm $seconds;
		$result = $code->();
		alarm 0;
		1;
	};
	my $error = $@;
	alarm 0;

	return $result if $ok;
	return         if $error eq "timeout\n";

	die $error;
}

# wait_until($timeout, $interval, $code):
#	Call $code until it returns true, or until $timeout seconds
#	pass. $interval is the pause between calls, and its default is
#	a quarter of a second.
#
#	The function returns the first true value that $code gave. It
#	returns undef on the timeout, and undef when a signal arrives:
#	a poll loop must not outlive the interrupt that told the
#	program to stop.
#
#	$code runs at least once, even with a timeout of 0. A caller
#	that asks "is it ready" always gets an answer about now.
sub wait_until ( $timeout, $interval, $code )
{
	$interval //= DEFAULT_INTERVAL;
	my $deadline = time + $timeout;

	while (1) {
		return if Fugu::Signal::check_interrupted();

		my $result = $code->();
		return $result if $result;

		my $left = $deadline - time;
		return if $left <= 0;

		select undef, undef, undef,
		    $left < $interval ? $left : $interval;
	}
}

1;
