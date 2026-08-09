package Ereshkigal::App::Command::start;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;
use Ereshkigal             ();
use Net::Server::Daemonize qw( daemonize );

=head1 NAME

Ereshkigal::App::Command::start - Start the manager and all the configured kur instances.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ereshkigal start
    ereshkigal start --foreground
    ereshkigal start --config /usr/local/etc/ereshkigal.toml

=head1 DESCRIPTION

Starts the manager and every kur the config defines. The manager reads the
config, brings up a kur process per instance, and listens on its unix
socket. Each kur builds its firewall setup and re-bans whatever its tablet
was carrying, so bans that had not run out survive the restart; anything that
expired while it was down is unbanned instead, in case the firewall still had
the rule. A kur that dies is restarted with a backoff, doubling to a cap of a
minute.

It daemonizes unless C<--foreground> is given. Either way it refuses to start
over a manager that is already running, and waits briefly first for a
previous one still shutting down, so restart style invocations do not race.

Building firewall state means this generally has to run as root.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... abstract, description,
usage_desc, opt_spec, validate_args, and execute.

=cut

sub abstract { return 'start the manager and all the configured kur instances' }

sub description {
	return <<'DESCRIPTION';
Start the manager and every kur the config defines.

The manager reads the config, brings up a kur process per instance, and
listens on its unix socket. Each kur builds its firewall setup and re-bans
whatever its tablet was carrying, so bans that had not run out survive the
restart. Anything whose sentence expired while it was down is unbanned
instead, in case the firewall still had the rule.

A kur that dies is restarted with a backoff, doubling to a cap of a
minute.

It daemonizes unless -f is given. Either way it refuses to start over a
manager that is already running, and waits briefly first for a previous
one that is still shutting down, so "restart" style invocations do not
race.

This needs to be able to build firewall state, which in practice means
root.

  ereshkigal start
  ereshkigal start -f --config ./ereshkigal.toml    # foreground, for a look
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c start %o'; }

sub opt_spec {
	return (
		[ 'config=s',     'path of the config file', { default => '/usr/local/etc/ereshkigal.toml' } ],
		[ 'foreground|f', 'do not daemonize' ],
	);
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} ) {
		$self->usage_error('start does not take any args');
	}

	return;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $ereshkigal = Ereshkigal->new( 'config' => $opt->config );

	# A previous manager may still be tearing down. `ereshkigal stop`, and thus
	# `service ereshkigal restart`, returns as soon as the shutdown is requested,
	# so the following start can race the old process. The manager unlinks its
	# PID file only once it has fully exited, so wait briefly for a live PID to
	# clear rather than letting daemonize() abort with
	# "Pid_file already exists for running process".
	$self->_wait_for_pid_clear( $ereshkigal->pid_path );

	if ( $opt->foreground ) {
		# the daemonize branch gets this from daemonize() itself, so make sure
		# the foreground branch does not clobber the PID file of a live manager
		if ( -e $ereshkigal->pid_path && open( my $old_pid_fh, '<', $ereshkigal->pid_path ) ) {
			my $old_pid = <$old_pid_fh>;
			close($old_pid_fh);
			if ( defined($old_pid) && $old_pid =~ /^\s*([0-9]+)\s*$/ ) {
				$old_pid = $1;
				# kill 0 is true while the process exists, and EPERM means it
				# exists but is not ours to signal
				if ( kill( 0, $old_pid ) || $!{EPERM} ) {
					die(      'A manager already appears to be running with PID '
							. $old_pid
							. ' per the PID file "'
							. $ereshkigal->pid_path
							. '"' );
				}
			} ## end if ( defined($old_pid) && $old_pid =~ /^\s*([0-9]+)\s*$/)
		} ## end if ( -e $ereshkigal->pid_path && open( my ...))

		open( my $pid_fh, '>', $ereshkigal->pid_path )
			|| die( 'Failed to open the PID file "' . $ereshkigal->pid_path . '"... ' . $! );
		print $pid_fh $$;
		close($pid_fh);
	} else {
		daemonize( $>, ( split( /\s+/, $) ) )[0], $ereshkigal->pid_path );
	}

	$ereshkigal->start_server;

	unlink( $ereshkigal->pid_path ) if -e $ereshkigal->pid_path;

	return;
} ## end sub execute

# Waits, briefly, for a previous manager to finish going away, so that a
# restart does not race its own predecessor. This exists because
# "ereshkigal stop" returns as soon as the shutdown has been requested
# rather than once it has finished, which means "service ereshkigal
# restart", and anything else that stops and immediately starts, can reach
# start while the old manager is still tearing its kurs down. Without this
# the start aborts with daemonize's "Pid_file already exists for running
# process" for a manager that was a half second from being gone.
#
# It polls rather than watching for anything, up to forty times with a
# quarter second between, so a little over ten seconds in the worst case. It
# returns the moment any of four things is true... the PID file is gone, it
# cannot be opened, it holds nothing that looks like a PID, or the PID it
# holds names a process that is neither running nor merely unsignalable by
# us. The first three are all a stale PID file, which daemonize happily
# reclaims on its own.
#
# Deliberately does not decide anything. If a live manager is still there
# when the polling runs out it returns anyway and leaves refusing the start
# to daemonize, or to the foreground branch's own liveness check... this only
# ever buys time, and never turns a running manager into a startable one.
#
# Args, one, positional and required...
#
#     $pid_path :: Full path of the manager PID file to watch, in practice
#                  always $ereshkigal->pid_path. It need not exist... a
#                  missing file is the state being waited for and returns at
#                  once.
#
# Returns nothing meaningful, an empty return. There is no telling from the
# return whether the wait succeeded or timed out, deliberately, as the
# caller does not act on it either way.
#
#     $self->_wait_for_pid_clear( $ereshkigal->pid_path );
#     # returns at once if nothing is running, or after up to ~10s if a
#     # previous manager is still shutting down
sub _wait_for_pid_clear {
	my ( $self, $pid_path ) = @_;

	for ( 1 .. 40 ) {
		last if !-e $pid_path;

		open( my $pid_fh, '<', $pid_path ) or last;
		my $pid = <$pid_fh>;
		close($pid_fh);

		last if !defined($pid) || $pid !~ /^\s*([0-9]+)\s*$/;
		$pid = $1;

		# kill 0 is true while the process exists, and EPERM means it exists
		# but is not ours to signal; once both go false the old manager is
		# gone. matching the foreground branch, which checks EPERM the same
		# way, so a manager owned by another user is still waited on.
		last if !kill( 0, $pid ) && !$!{EPERM};

		# 0.25s nap without pulling in Time::HiRes.
		select( undef, undef, undef, 0.25 );    ## no critic (BuiltinFunctions::ProhibitSleepViaSelect)
	} ## end for ( 1 .. 40 )

	return;
} ## end sub _wait_for_pid_clear

1;
