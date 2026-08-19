# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2024 Dick Olsson <hi@senzilla.io>
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

package Fugu::SSH;
our $VERSION = '0.1.2';

use Fcntl     qw(O_RDONLY O_WRONLY O_CREAT O_TRUNC);
use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Process;
use Fugu::Timeout;

# Fugu::SSH - run a command on another machine over SSH.
#
# The module wraps Net::SSH2 for the two things a provisioning tool
# does: run a command and capture its output, and write a file. An
# interactive session falls back to ssh(1), because Net::SSH2 does not
# give correct TTY control.
#
# Net::SSH2 loads at connect time, not at compile time. Thus the
# module keeps the Fugu core-Perl load contract, and an
# installation without the library still loads it and fails with a
# clear message at the first connect.

use constant {
	DEFAULT_TIMEOUT => 10,
	BUFFER_SIZE     => 32768,
};

sub new ( $class, %args )
{
	my $self = bless {
		host     => $args{host} // '127.0.0.1',
		port     => $args{port} // 22,
		user     => $args{user} // 'root',
		password => $args{password},
		timeout  => $args{timeout} // DEFAULT_TIMEOUT,
	}, $class;

	return $self;
}

# $self->_connect:
#	Open the SSH connection. Authenticate with the SSH agent first,
#	then with the password as a fallback. The method returns a
#	Net::SSH2 object on success.
sub _connect ($self)
{
	eval { require Net::SSH2; 1 }
	    or die "Fugu::SSH needs Net::SSH2: $@";

	my $ssh2 = Net::SSH2->new;
	$ssh2->timeout( $self->{timeout} * 1000 );    # milliseconds

	if ( !$ssh2->connect( $self->{host}, $self->{port} ) ) {
		return;
	}

	# Try the SSH agent authentication first when SSH_AUTH_SOCK is set
	if ( defined $ENV{SSH_AUTH_SOCK} ) {
		if ( $ssh2->auth_agent( $self->{user} ) ) {
			return $ssh2;
		}
	}

	# Fall back to the password authentication when a password is
	# available
	if ( defined $self->{password} ) {
		if ( $ssh2->auth_password( $self->{user}, $self->{password} ) )
		{
			return $ssh2;
		}
	}

	$ssh2->disconnect;
	return;
}

# $self->wait_available($timeout):
#	Poll until the host takes an authenticated connection. The wait
#	stops early on an interrupt, through Fugu::Timeout. The method
#	returns 1 when the host answered, and 0 otherwise.
sub wait_available ( $self, $timeout = 120 )
{
	return Fugu::Timeout::wait_until( $timeout, 2,
		sub { $self->is_available } )
	    ? 1
	    : 0;
}

# $self->_with_connection($code):
#	Open the connection, run $code->($ssh2), disconnect, and
#	return what $code returned. The method returns undef when the
#	connect fails, so every remote operation shares one
#	connect-run-disconnect shape.
sub _with_connection ( $self, $code )
{
	my $ssh2 = $self->_connect;
	return unless defined $ssh2;

	my $result = $code->($ssh2);
	$ssh2->disconnect;

	return $result;
}

sub run_command ( $self, $command )
{
	my $result = $self->_with_connection(
		sub ($ssh2) {
			my $channel = $ssh2->channel;
			if ( !defined $channel ) {
				return {
					stdout    => '',
					stderr    => 'Failed to open channel',
					exit_code => 1,
				};
			}

			$channel->exec($command);

			my $stdout = '';
			my $stderr = '';

			# Read stdout
			while ( !$channel->eof ) {
				my $buf;
				my $len = $channel->read( $buf, BUFFER_SIZE );
				last if !defined $len || $len <= 0;
				$stdout .= $buf;
			}

			# Read stderr (ext=1)
			while (1) {
				my $buf;
				my $len =
				    $channel->read( $buf, BUFFER_SIZE, 1 );
				last if !defined $len || $len <= 0;
				$stderr .= $buf;
			}

			$channel->wait_closed;
			my $exit_code = $channel->exit_status // 255;

			$channel->close;

			return {
				stdout    => $stdout,
				stderr    => $stderr,
				exit_code => $exit_code,
			};
		} );

	return $result // {
		stdout    => '',
		stderr    => 'Failed to connect',
		exit_code => 1,
	};
}

sub interactive ($self)
{
	# For interactive sessions, fall back to the system ssh command.
	# Net::SSH2 does not give correct TTY control for interactive
	# use.
	my @cmd = (
		'ssh',
		'-o',
		'StrictHostKeyChecking=no',
		'-o',
		'UserKnownHostsFile=/dev/null',
		'-o',
		'LogLevel=ERROR',
		'-p',
		$self->{port},
		"$self->{user}\@$self->{host}",
	);

	# Return the child's exit code, not the raw wait status. The
	# callers, and finally the fuguvm exit status, expect a 0-255
	# code. A raw status of 256 for a remote exit code of 1 would
	# become exit(256) -> 0. That result silently turns a failed
	# remote command into success, for example a failed `prove` run
	# driven over stdin.
	return Fugu::Process->exit_code( system(@cmd) );
}

# $self->write_file($remote_path, $content, $mode):
#	Write the content directly to a remote file with SFTP
sub write_file ( $self, $remote_path, $content, $mode = 0644 )
{
	my $result = $self->_with_connection(
		sub ($ssh2) {
			my $sftp = $ssh2->sftp;
			return EXIT_ERROR if !defined $sftp;

			my $remote_fh =
			    $sftp->open( $remote_path,
				O_WRONLY | O_CREAT | O_TRUNC, $mode );
			return EXIT_ERROR if !defined $remote_fh;

			# A short write leaves a truncated remote file. A
			# provisioning script that arrives half-written is
			# worse than one that never arrived, so the return
			# value is checked.
			my $written = $remote_fh->write($content);
			undef $remote_fh;    # Close the file handle

			return EXIT_ERROR
			    if !defined $written
			    || $written != length $content;

			return EXIT_SUCCESS;
		} );

	return $result // EXIT_ERROR;
}

sub is_available ($self)
{
	return $self->_with_connection( sub ($) { 1 } ) ? 1 : 0;
}

1;
