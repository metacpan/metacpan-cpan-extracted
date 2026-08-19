# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2025 Dick Olsson <hi@senzilla.io>
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

package Fugu::Daemon;
our $VERSION = '0.1.2';

use Fugu::Pidfile;
use POSIX qw(setsid);

# Fugu::Daemon - detach a program from its terminal, as daemon(3)
# does. The module keeps no state that a caller can see and has one
# class method. Every failure is a startup failure, so it dies.

# The daemon holds its PID file lock for the whole life of the process.
# A caller that discards the returned object must not release the lock.
# Thus the module keeps its own reference to it.
my $held_pidfile;

# $class->daemonize(%args):
#	Fork into the background. Detach from the terminal. Redirect
#	the standard file descriptors. The method returns in the child
#	process only. The parent process exits successfully.
#
#	%args:
#		logfile => $path  # Target of stdout/stderr (default: /dev/null)
#		pidfile => $path  # PID file the child acquires and holds
#
#	The method returns the Fugu::Pidfile object when the caller
#	gives a pidfile. Otherwise it returns nothing.
sub daemonize ( $class, %args )
{
	my $logfile = $args{logfile} // '/dev/null';
	my $pidfile = $args{pidfile};

	my $pid = fork;
	unless ( defined $pid ) {
		die "Cannot fork: $!";
	}

	# Parent process
	exit 0 if $pid;

	# Child process
	$DB::inhibit_exit = 0;
	setsid() or die "Cannot start new session: $!";

	# Redirect the standard file descriptors before the chdir. Then
	# a relative logfile keeps the meaning that the caller gave it.
	open STDIN,  '<',  '/dev/null' or die "Cannot read /dev/null: $!";
	open STDOUT, '>>', $logfile    or die "Cannot write to $logfile: $!";
	open STDERR, '>&', \*STDOUT    or die "Cannot dup STDOUT: $!";

	# Release the directory the caller started in, as daemon(3)
	# does. A daemon must never keep a filesystem busy.
	chdir '/' or die "Cannot chdir to /: $!";
	umask 022;

	return unless defined $pidfile;

	# Take the PID file after setsid, so the file holds the PID of
	# the session leader and not of the parent. The daemon holds the
	# lock for life and never removes the file: in a root-owned
	# directory the unlink needs a permission that the process gives
	# up at the privilege drop. Fugu::Pidfile->is_stale covers
	# the leftover.
	$held_pidfile = Fugu::Pidfile->new( path => $pidfile );
	$held_pidfile->acquire
	    or die 'Cannot acquire PID file: ' . $held_pidfile->error;

	return $held_pidfile;
}

1;
