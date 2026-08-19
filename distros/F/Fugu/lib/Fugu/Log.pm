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

package Fugu::Log;
our $VERSION = '0.1.2';

use IO::Handle;
use Sys::Syslog qw(:standard :macros);

# Fugu::Log - Unified logging for syslog and stderr
#
# The module gives one logging interface for both syslog (for
# daemons) and stderr (for CLI tools). It filters messages by level
# and formats them printf-style.
#
# The levels are debug, info, notice, warning and error. Each one is
# a method of the same name.
#
# The module also holds one process default. Library code that gets no
# logger asks for it, so no library has to die for the lack of one.

# The mode decides where a message goes. MODE_SYSLOG is for a daemon,
# MODE_STDERR for a program with a terminal, and MODE_QUIET drops
# every message.
use constant {
	MODE_SYSLOG => 'syslog',
	MODE_STDERR => 'stderr',
	MODE_QUIET  => 'quiet',
};

# The process default. Fugu::Log->default creates a stderr logger
# on the first call, so the accessor always answers with a logger.
my $default;

# Level parsing and mapping. One spelling per level: the five method
# names above are the whole vocabulary, and the daemon validates its
# configuration against them at startup.
my %level_map = (
	debug   => 0,
	info    => 1,
	notice  => 2,
	warning => 3,
	error   => 4,
);

my %priority_map = (
	debug   => LOG_DEBUG,
	info    => LOG_INFO,
	notice  => LOG_NOTICE,
	warning => LOG_WARNING,
	error   => LOG_ERR,
);

my %facility_map = (
	daemon => LOG_DAEMON,
	user   => LOG_USER,
	local0 => LOG_LOCAL0,
	local1 => LOG_LOCAL1,
	local2 => LOG_LOCAL2,
	local3 => LOG_LOCAL3,
	local4 => LOG_LOCAL4,
	local5 => LOG_LOCAL5,
	local6 => LOG_LOCAL6,
	local7 => LOG_LOCAL7,
);

# _parse_level($level):
#	The canonical level name. An unknown one falls back to info:
#	the boundary validates, and the library stays usable.
sub _parse_level ($level)
{
	$level = lc($level);
	return exists $level_map{$level} ? $level : 'info';
}

sub _level_to_priority ($level)
{
	$level = lc($level);
	return $priority_map{$level} // LOG_INFO;
}

sub _parse_facility ($facility)
{
	$facility = lc($facility);
	return $facility_map{$facility} // LOG_DAEMON;
}

sub new ( $class, %args )
{
	my $mode  = $args{mode}  // MODE_STDERR;
	my $level = $args{level} // 'info';
	my $ident = $args{ident} // 'fugu';

	# Validate the mode
	unless ( $mode =~ /^(syslog|stderr|quiet)$/ ) {
		die "Invalid log mode: $mode";
	}

	# Convert the facility string to a constant if necessary
	my $facility = $args{facility} // LOG_DAEMON;
	if ( ref($facility) eq '' && $facility =~ /^\w+$/ ) {
		$facility = _parse_facility($facility);
	}

	my $name = _parse_level($level);

	my $self = bless {
		mode       => $mode,
		level      => $level_map{$name},
		level_name => $name,
		ident      => $ident,
		facility   => $facility,
		opened     => 0,
	}, $class;

	if ( $mode eq MODE_SYSLOG ) {
		openlog( $ident, 'ndelay,pid', $self->{facility} );
		$self->{opened} = 1;
	}
	elsif ( $mode eq MODE_STDERR ) {

		# A daemonized process has a buffered stderr, because
		# the descriptor is a dup of the redirected stdout. An
		# unflushed diagnostic that arrives after the crash it
		# describes is worse than no diagnostic.
		STDERR->autoflush(1);
	}

	return $self;
}

# Fugu::Log->default:
#	Return the process default logger. The first call creates a
#	stderr logger, so the method never returns undef.
sub default ($class)
{
	$default //= $class->new( mode => MODE_STDERR );
	return $default;
}

# Fugu::Log->set_default($log):
#	Replace the process default logger. A program sets this once at
#	startup, and again after a privilege drop. The method returns
#	the new default.
sub set_default ( $class, $log )
{
	$default = $log;
	return $default;
}

sub DESTROY ($self)
{
	if ( $self->{opened} && $self->{mode} eq MODE_SYSLOG ) {
		closelog();
	}
}

# Logging methods
sub debug   ( $self, $fmt, @args ) { $self->_log( 'debug',   $fmt, @args ); }
sub info    ( $self, $fmt, @args ) { $self->_log( 'info',    $fmt, @args ); }
sub notice  ( $self, $fmt, @args ) { $self->_log( 'notice',  $fmt, @args ); }
sub warning ( $self, $fmt, @args ) { $self->_log( 'warning', $fmt, @args ); }
sub error   ( $self, $fmt, @args ) { $self->_log( 'error',   $fmt, @args ); }

# $self->_log($level, $fmt, @args):
#	Internal logging method
sub _log ( $self, $level, $fmt, @args )
{
	return if $self->{mode} eq MODE_QUIET;

	return if $level_map{$level} < $self->{level};

	my $message = @args ? sprintf( $fmt, @args ) : $fmt;

	if ( $self->{mode} eq MODE_SYSLOG ) {
		my $priority = _level_to_priority($level);
		syslog( $priority, '%s', $message );
	}
	elsif ( $self->{mode} eq MODE_STDERR ) {
		my $timestamp = _timestamp();
		my $level_str = uc($level);
		printf STDERR "[%s] %s: %s\n", $timestamp, $level_str, $message;
	}
}

# $self->set_level($level):
#	Change the minimum log level
sub set_level ( $self, $level )
{
	my $name = _parse_level($level);

	$self->{level}      = $level_map{$name};
	$self->{level_name} = $name;
}

# $self->level:
#	Return the minimum log level by name, one of the five levels.
sub level ($self)
{
	return $self->{level_name};
}

# $self->mode:
#	Return the mode, one of the MODE_* constants.
sub mode ($self)
{
	return $self->{mode};
}

# $self->reopen:
#	Close and open the log again with the same settings. A daemon
#	calls this after it drops privileges: the syslog connection
#	belongs to the user that opened it. In the other modes the
#	method does nothing and returns the object.
sub reopen ($self)
{
	if ( $self->{mode} eq MODE_SYSLOG ) {
		closelog() if $self->{opened};
		openlog( $self->{ident}, 'ndelay,pid', $self->{facility} );
		$self->{opened} = 1;
	}

	return $self;
}

sub _timestamp()
{
	my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime;
	return sprintf(
		'%04d-%02d-%02d %02d:%02d:%02d',
		$year + 1900,
		$mon + 1, $mday, $hour, $min, $sec
	);
}

1;
