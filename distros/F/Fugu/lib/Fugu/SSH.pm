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
our $VERSION = '0.3.0';

use Fcntl     qw(O_RDONLY O_WRONLY O_CREAT O_TRUNC);
use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::Log;
use Fugu::Process;
use Fugu::Timeout;

# Fugu::SSH - run a command on another machine over SSH.
#
# The module wraps Net::SSH2 for the things a provisioning tool does:
# run a command and capture its output, write a file, and read a file
# back. An interactive session falls back to ssh(1), because Net::SSH2
# does not give correct TTY control.
#
# Net::SSH2 loads at connect time, not at compile time. Thus the
# module keeps the Fugu core-Perl load contract, and an
# installation without the library still loads it and fails with a
# clear message at the first connect.

use constant {
	DEFAULT_TIMEOUT => 10,
	BUFFER_SIZE     => 32768,

	# The default size cap of read_file. The method holds the whole
	# file in memory, and a guest can hand back a disk image, so the
	# cap fails closed. A caller that needs more names a larger
	# $max_size.
	MAX_READ_SIZE => 64 * 1024 * 1024,
};

sub new ( $class, %args )
{
	my $self = bless {
		host        => $args{host} // '127.0.0.1',
		port        => $args{port} // 22,
		user        => $args{user} // 'root',
		password    => $args{password},
		timeout     => $args{timeout} // DEFAULT_TIMEOUT,
		known_hosts => $args{known_hosts},
		strict      => $args{strict} // 0,
	}, $class;

	return $self;
}

# $self->_connect:
#	Open the SSH connection. In the strict mode, verify the host
#	key between the connect and the authentication: the fallback
#	sends the password, and a password that reaches the wrong host
#	is a lost password. Authenticate with the SSH agent first, then
#	with the password as a fallback. The method returns a Net::SSH2
#	object on success.
sub _connect ($self)
{
	eval { require Net::SSH2; 1 }
	    or die "Fugu::SSH needs Net::SSH2: $@";

	# Net::SSH2 0.60 renamed the check method, and it fixed the
	# argument order to (policy, known_hosts_path). The test is
	# static, so it runs before the connect.
	if ( $self->{strict} && !Net::SSH2->can('check_hostkey') ) {
		die "The strict mode needs Net::SSH2 0.60 or later\n";
	}

	my $ssh2 = Net::SSH2->new;
	$ssh2->timeout( $self->{timeout} * 1000 );    # milliseconds

	if ( !$ssh2->connect( $self->{host}, $self->{port} ) ) {
		return;
	}

	if ( $self->{strict} ) {

		# The known hosts file of the back end when the caller
		# names none.
		my $file = $self->{known_hosts} // '~/.ssh/known_hosts';

		my @check = ( Net::SSH2::LIBSSH2_HOSTKEY_POLICY_STRICT() );
		push @check, $self->{known_hosts}
		    if defined $self->{known_hosts};

		unless ( $ssh2->check_hostkey(@check) ) {

			# The error of the back end tells a wrong key
			# from a file that holds no key for the host.
			my $reason = ( $ssh2->error )[2];
			$reason = 'no verified key'
			    unless defined $reason && length $reason;

			$ssh2->disconnect;
			die sprintf "Cannot verify the host key of %s"
			    . " port %d against %s: %s\n",
			    $self->{host}, $self->{port}, $file, $reason;
		}
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

# $self->_ssh_argv:
#	The ssh(1) argument list of interactive. The list always holds
#	more than one element, so perl runs no shell. The permissive
#	mode lowers the log level to hide the line that reports a new
#	key. The strict mode must show the host-key diagnosis, so it
#	keeps the level. ssh(1) also reads /etc/ssh/ssh_known_hosts: an
#	entry that an administrator wrote is a local trust decision, so
#	the list never sets GlobalKnownHostsFile.
sub _ssh_argv ($self)
{
	my @options;
	if ( $self->{strict} ) {
		push @options, '-o', 'StrictHostKeyChecking=yes';
		push @options, '-o', "UserKnownHostsFile=$self->{known_hosts}"
		    if defined $self->{known_hosts};
	}
	else {
		push @options,
		    '-o', 'StrictHostKeyChecking=no',
		    '-o', 'UserKnownHostsFile=/dev/null',
		    '-o', 'LogLevel=ERROR';
	}

	return ( 'ssh', @options, '-p', $self->{port},
		"$self->{user}\@$self->{host}",
	);
}

sub interactive ($self)
{
	# For interactive sessions, fall back to the system ssh command.
	# Net::SSH2 does not give correct TTY control for interactive
	# use. ssh(1) itself refuses the session for a host key that
	# does not verify, and returns 255.
	#
	# Return the child's exit code, not the raw wait status. The
	# callers, and finally the fuguvm exit status, expect a 0-255
	# code. A raw status of 256 for a remote exit code of 1 would
	# become exit(256) -> 0. That result silently turns a failed
	# remote command into success, for example a failed `prove` run
	# driven over stdin.
	return Fugu::Process->exit_code( system( $self->_ssh_argv ) );
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
			# worse than one that never arrived. _write_all
			# reports a total short of the length as a
			# failure.
			my $written = $self->_write_all( $remote_fh, $content );
			undef $remote_fh;    # Close the file handle

			return EXIT_ERROR if !$written;

			return EXIT_SUCCESS;
		} );

	return $result // EXIT_ERROR;
}

# $self->read_file($remote_path, $max_size):
#	Read a remote file over SFTP and return its bytes. The method
#	reads the size first, and it refuses a size above $max_size
#	before it reads one byte. It returns undef for every failure,
#	and it reports the reason on the debug level. An empty remote
#	file returns the empty string, so a caller tests defined.
sub read_file ( $self, $remote_path, $max_size = MAX_READ_SIZE )
{
	my $connected = 0;

	my $result = $self->_with_connection(
		sub ($ssh2) {
			$connected = 1;

			my $sftp = $ssh2->sftp;
			if ( !defined $sftp ) {
				Fugu::Log->default->debug(
					'Cannot open an SFTP session to %s',
					$self->{host} );
				return;
			}

			my $attrs = $sftp->stat($remote_path);
			if ( !defined $attrs ) {
				Fugu::Log->default->debug( 'Cannot stat %s',
					$remote_path );
				return;
			}

			my $size = $attrs->{size};
			if ( $size > $max_size ) {
				Fugu::Log->default->debug(
					'%s holds %d bytes, the cap is %d',
					$remote_path, $size, $max_size );
				return;
			}

			my $remote_fh = $sftp->open( $remote_path, O_RDONLY );
			if ( !defined $remote_fh ) {
				Fugu::Log->default->debug( 'Cannot open %s',
					$remote_path );
				return;
			}

			# A file that arrives half-read is worse than one
			# that never arrived, because the caller cannot see
			# the difference. _read_all reports a total that
			# differs from the size as a failure.
			my $content = $self->_read_all( $remote_fh, $size );
			undef $remote_fh;    # Close the file handle

			if ( !defined $content ) {
				Fugu::Log->default->debug(
					'Cannot read %d bytes from %s',
					$size, $remote_path );
				return;
			}

			return $content;
		} );

	Fugu::Log->default->debug( 'Cannot connect to %s port %d',
		$self->{host}, $self->{port} )
	    if !$connected;

	return $result;
}

# $self->_read_all($file, $size):
#	Read $size bytes from $file and return them. One read can give
#	less than the full size, so the method loops, and it stops at
#	$size. It returns undef when a read fails, and it returns undef
#	when the total differs from $size. A $size of 0 returns the
#	empty string.
# $self->_write_all($file, $content):
#	Write the whole content to $file. One SFTP write can accept
#	less than the full buffer, so the method loops, and it sends
#	the remainder again from the accepted offset. That is the
#	contract of libssh2_sftp_write(3). The method returns 1 when
#	every byte is accepted, and undef when a write fails. An empty
#	content returns 1, because the open already created the file.
sub _write_all ( $self, $file, $content )
{
	my $total = 0;

	while ( $total < length $content ) {
		my $len = $file->write( substr $content, $total );

		# undef is a failed write, and 0 makes no progress:
		# both would leave a short remote file.
		return if !defined $len || $len <= 0;

		$total += $len;
	}

	return 1;
}

sub _read_all ( $self, $file, $size )
{
	my $content = '';

	while ( length($content) < $size ) {
		my $want = $size - length($content);
		$want = BUFFER_SIZE if $want > BUFFER_SIZE;

		my $buf;
		my $len = $file->read( $buf, $want );

		# undef is a failed read, and 0 is an end of file before
		# $size: both leave a short total.
		return if !defined $len || $len <= 0;

		$content .= $buf;
	}

	return length($content) == $size ? $content : ();
}

sub is_available ($self)
{
	return $self->_with_connection( sub ($) { 1 } ) ? 1 : 0;
}

1;
