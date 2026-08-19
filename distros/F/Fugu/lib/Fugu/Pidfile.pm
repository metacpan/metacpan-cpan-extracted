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

package Fugu::Pidfile;
our $VERSION = '0.1.2';

use Fcntl qw(:flock O_CREAT O_RDWR SEEK_SET);
use Fugu::Process;

# Fugu::Pidfile - a locked PID file.
#
# The module manages one PID file and nothing else. Every write takes
# the lock before it truncates. Thus a concurrent reader never sees an
# empty file. The acquire method keeps the locked handle for the life
# of the process. Then "am I already running" has an authoritative
# answer. The module never logs. It keeps the last failure in ->error.

# Fugu::Pidfile->new(%args):
#	path => $file	the PID file (required)
sub new ( $class, %args )
{
	my $path = $args{path};
	die 'path parameter required'
	    unless defined $path && length $path;

	return bless {
		path  => $path,
		fh    => undef,
		error => undef,
	}, $class;
}

# $self->path:
#	Return the PID file path.
sub path ($self)
{
	return $self->{path};
}

# $self->error: the most recent failure.
sub error ($self)
{
	return $self->{error};
}

# $self->write_pid($pid):
#	Write the PID and drop the lock at once. The default PID is
#	the caller's. The method returns 1, or undef with ->error set.
sub write_pid ( $self, $pid = $$ )
{
	my $fh = $self->_open_locked(0) or return;

	my $ok = $self->_store( $fh, $pid );
	close $fh;

	return $ok;
}

# $self->acquire($pid):
#	Write the PID and keep the locked handle open. The lock lives
#	until the object is destroyed, or until the process exits. A
#	second acquire on
#	the same file, from any process, fails while the first holds
#	it. The method returns 1, or undef with ->error set.
sub acquire ( $self, $pid = $$ )
{
	if ( $self->{fh} ) {
		$self->{error} = "already acquired $self->{path}";
		return;
	}

	my $fh = $self->_open_locked(1) or return;

	unless ( $self->_store( $fh, $pid ) ) {
		close $fh;
		return;
	}

	$self->{fh} = $fh;

	return 1;
}

# $self->read_pid:
#	Read the PID from the file. The method returns the PID, or
#	undef when the file is absent or holds no decimal PID.
sub read_pid ($self)
{
	open my $fh, '<', $self->{path} or do {
		$self->{error} = "open $self->{path}: $!";
		return;
	};
	my $line = <$fh>;
	close $fh;

	return unless defined $line;
	chomp $line;
	return unless $line =~ /^\d+$/;

	return $line;
}

# $self->remove:
#	Remove the PID file. The method returns 1 when the file is
#	absent afterwards.
sub remove ($self)
{
	return 1 unless -e $self->{path};
	unless ( unlink $self->{path} ) {
		$self->{error} = "unlink $self->{path}: $!";
		return;
	}

	return 1;
}

# $self->is_running:
#	Return the PID from the file when that process is alive.
#	Otherwise return undef.
sub is_running ($self)
{
	my $pid = $self->read_pid;
	return unless defined $pid;
	return unless Fugu::Process->is_alive($pid);

	return $pid;
}

# $self->is_stale:
#	Report if the file names a process that is not alive now. An
#	absent PID file is not stale.
sub is_stale ($self)
{
	my $pid = $self->read_pid;
	return 0 unless defined $pid;

	return !Fugu::Process->is_alive($pid);
}

# $self->_open_locked($nonblocking):
#	Open the file for read and write, create it when it is absent,
#	and take the exclusive lock. The open must not truncate. A
#	truncate before the lock lets a concurrent reader see an empty
#	file.
sub _open_locked ( $self, $nonblocking )
{
	sysopen my $fh, $self->{path}, O_CREAT | O_RDWR, 0644 or do {
		$self->{error} = "open $self->{path}: $!";
		return;
	};

	my $how = $nonblocking ? LOCK_EX | LOCK_NB : LOCK_EX;
	unless ( flock $fh, $how ) {
		$self->{error} = "lock $self->{path}: $!";
		close $fh;
		return;
	}

	return $fh;
}

# $self->_store($fh, $pid):
#	Truncate the locked handle and write the PID. The write is a
#	syswrite, so the bytes reach the file with no flush.
sub _store ( $self, $fh, $pid )
{
	unless ( truncate $fh, 0 ) {
		$self->{error} = "truncate $self->{path}: $!";
		return;
	}
	unless ( defined sysseek( $fh, 0, SEEK_SET ) ) {
		$self->{error} = "seek $self->{path}: $!";
		return;
	}

	my $data    = "$pid\n";
	my $written = syswrite $fh, $data;
	unless ( defined $written && $written == length $data ) {
		$self->{error} = "write $self->{path}: $!";
		return;
	}

	return 1;
}

1;
