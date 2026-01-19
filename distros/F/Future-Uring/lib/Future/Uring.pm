package Future::Uring;
$Future::Uring::VERSION = '0.001';
use 5.020;
use warnings;
use experimental 'signatures';

use IO::Uring
	qw/IOSQE_ASYNC IOSQE_IO_LINK IOSQE_IO_HARDLINK IOSQE_IO_DRAIN/,
	qw/IORING_TIMEOUT_ABS IORING_TIMEOUT_BOOTTIME IORING_TIMEOUT_REALTIME IORING_TIMEOUT_ETIME_SUCCESS/,
	qw/AT_SYMLINK_FOLLOW RENAME_EXCHANGE RENAME_NOREPLACE AT_REMOVEDIR/,
	qw/P_PID P_PGID P_PIDFD P_ALL WEXITED WSTOPPED WCONTINUED WNOWAIT/;
use Carp 'croak';
use Errno qw/ETIME/;
use Fcntl qw/O_RDONLY O_RDWR O_WRONLY O_APPEND O_CREAT O_DIRECT O_DSYNC O_EXCL O_NOFOLLOW O_SYNC O_TMPFILE/;
use Socket qw/AF_INET AF_INET6 AF_UNIX SOCK_STREAM SOCK_DGRAM SOCK_SEQPACKET SOCK_RAW/;
use IO::File;
use IO::Socket;
use Signal::Info qw/CLD_EXITED CLD_DUMPED/;
use Time::Spec;

use Future::Uring::Handle;
use Future::Uring::Exception;

our $ring = IO::Uring->new(our $ring_size //= 128);

my sub to_sflags($args) {
	my $result = 0;
	$result |= IOSQE_ASYNC       if $args->{async};
	$result |= IOSQE_IO_LINK     if $args->{link} || $args->{timeout};
	$result |= IOSQE_IO_HARDLINK if $args->{hardlink};
	$result |= IOSQE_IO_DRAIN    if $args->{drain};
	return $result;
}

my %clocks = (
	monotonic => 0,
	boottime  => IORING_TIMEOUT_BOOTTIME,
	realtime  => IORING_TIMEOUT_REALTIME,
);

my sub add_timeout($ring, $args) {
	my $time_spec = ref $args->{timeout} ? $args->{timeout} : Time::Spec->new($args->{timeout});
	my ($flags, $s_flags) = (0, 0);
	$flags |= $clocks{$args->{timeout_clock}} // croak("No such clock $args->{timeout_clock}") if $args->{timeout_clock};
	$flags |= IORING_TIMEOUT_ABS if $args->{timeout_absolute};
	$s_flags |= IOSQE_IO_LINK    if $args->{link};
	$ring->link_timeout($time_spec, $flags, $s_flags);
}

sub to_handle($fh) {
	return Future::Uring::Handle->new($fh);
}

sub run_once($timeout = undef) {
	if (defined $timeout) {
		if ($timeout == 0) {
			$ring->run_once(0);
		} else {
			my $timespec = ref($timeout) ? $timeout : Time::Spec->new($timeout);
			$ring->run_once(1, $timespec);
		}
	} else {
		$ring->run_once(1);
	}
}

sub submit() {
	return $ring->submit;
}

sub submissions_available() {
	return $ring->sq_space_left;
}

sub link($old_path, $new_path, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $flags = $args{follow_symlink} ? AT_SYMLINK_FOLLOW : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->link($old_path, $new_path, $flags, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('link', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub linkat($old_dir, $old_path, $new_dir, $new_path, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $flags = $args{follow_symlink} ? AT_SYMLINK_FOLLOW : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->linkat($old_dir, $old_path, $new_dir, $new_path, $flags, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('linkat', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub mkdir($path, $mode, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->mkdir($path, $mode, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('mkdir', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub mkdirat($dir, $path, $mode, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->mkdirat($dir, $path, $mode, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('mkdirat', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

my %main_flags = (
	'<'   => O_RDONLY,
	'+<'  => O_RDWR,
	'>'   => O_WRONLY,
	'+>'  => O_RDWR | O_CREAT,
	'>>'  => O_APPEND,
);

my %extra_flags = (
	direct    => O_DIRECT,
	d_sync    => O_DSYNC,
	exclusive => O_EXCL,
	no_follow => O_NOFOLLOW,
	sync      => O_SYNC,
	tempfile  => O_TMPFILE
);

use subs 'open';

sub open($filename, $open_mode = '<', %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = to_sflags(\%args);
	my $flags = $main_flags{$open_mode} // croak("Unknown mode '$open_mode'");
	for my $key (keys %extra_flags) {
		$flags |= $extra_flags{$key} if $args{$key};
	}
	my $mode = $args{mode} || 0777;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->open($filename, $flags, $mode, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			open my $fh, "$open_mode&=", $res;
			$future->done(Future::Uring::Handle->new($fh));
		} else {
			$future->fail(Future::Uring::Exception->new('open', $res, $sourcename, $line));
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub openat($base_dir, $filename, $open_mode = '<', %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = to_sflags(\%args);
	my $flags = $main_flags{$open_mode} // croak("Unknown mode '$open_mode'");
	for my $key (keys %extra_flags) {
		$flags |= $extra_flags{$key} if $args{$key};
	}
	my $mode = $args{mode} || 0777;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->openat($base_dir, $filename, $flags, $mode, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			open my $fh, "$open_mode&=", $res;
			$future->done(Future::Uring::Handle->new($fh));
		} else {
			$future->fail(Future::Uring::Exception->new('openat', $res, $sourcename, $line));
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub rename($old_path, $new_path, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $flags = 0;
	$flags |= RENAME_EXCHANGE if $args{exchange};
	$flags |= RENAME_NOREPLACE if $args{no_replace};
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->rename($old_path, $new_path, $flags, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('rename', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub renameat($old_dir, $old_path, $new_dir, $new_path, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $flags = $args{follow_symlink} ? AT_SYMLINK_FOLLOW : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->renameat($old_dir, $old_path, $new_dir, $new_path, $flags, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('renameat', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub rmdir($path, %args) {
	my $future = Future::Uring::_Future->new;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->unlink($path, AT_REMOVEDIR, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(exception('rmdir', $res));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub rmdirat($dir, $path, %args) {
	my $future = Future::Uring::_Future->new;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->unlinkat($dir, $path, AT_REMOVEDIR, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(exception('rmdirat', $res));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

my %family_for = (
	inet   => AF_INET,
	inet6  => AF_INET6,
	unix   => AF_UNIX,
);

my %type_for = (
	stream    => SOCK_STREAM,
	datagram  => SOCK_DGRAM,
	seqpacket => SOCK_SEQPACKET,
	raw       => SOCK_RAW,
);

sub socket($family_name, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $domain = $family_for{$family_name} // croak "No address family '$family_name' known";
	my $type = defined $args{type} ? $type_for{$args{type}} : SOCK_STREAM;
	my $protocol = defined $args{protocol} ? getprotobyname($args{protocol}) : 0;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $class = $args{class} // 'IO::Socket';
	my $id = $ring->socket($domain, $type, $protocol, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			my $fh = $class->new_from_fd($res);
			$future->done(Future::Uring::Handle->new($fh));
		} else {
			$future->fail(Future::Uring::Exception->new('socket', $res, $sourcename, $line));
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub timeout_for($seconds, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $time_spec = ref $seconds ? $seconds : Time::Spec->new($seconds);
	my $clock_id = $args{clock} ? $clocks{$args{clock}} // croak("No such clock $args{clock}") : 0;
	my $flags = $clock_id | IORING_TIMEOUT_ETIME_SUCCESS;
	my $counter = $args{counter} // 0;
	my $s_flags = to_sflags(\%args);
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->timeout($time_spec, $counter, $flags, $s_flags, sub($res, $flags) {
		if ($res != -ETIME) {
			$future->fail(Future::Uring::Exception->new('timeout', $res, $sourcename, $line));
		} else {
			$future->done;
		}
		$time_spec;
	});
	if ($args{mutable}) {
		bless $future, 'Future::Uring::_TimeoutFuture';
		$future->set_udata('uring_id', $id);
		$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	}
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub timeout_until($seconds, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $time_spec = ref $seconds ? $seconds : Time::Spec->new($seconds);
	my $clock_id = $args{clock} ? $clocks{$args{clock}} // croak("No such clock $args{clock}") : IORING_TIMEOUT_REALTIME;
	my $flags = $clock_id | IORING_TIMEOUT_ETIME_SUCCESS | IORING_TIMEOUT_ABS;
	my $counter = $args{counter} // 0;
	my $s_flags = to_sflags(\%args);
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->timeout($time_spec, $counter, $flags, $s_flags, sub($res, $flags) {
		if ($res != -ETIME) {
			$future->fail(Future::Uring::Exception->new('timeout', $res, $sourcename, $line));
		} else {
			$future->done;
		}
		$time_spec;
	});
	if ($args{mutable}) {
		bless $future, 'Future::Uring::_TimeoutFuture';
		$future->set_udata('uring_id', $id);
		$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	}
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub unlink($path, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->unlink($path, 0, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('unlink', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub unlinkat($dir, $path, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->unlinkat($dir, $path, 0, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('unlinkat', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

my %types = (
	pid   => P_PID,
	pgid  => P_PGID,
	pidfd => P_PIDFD,
	all   => P_ALL,
);

my %events = (
	exited    => WEXITED,
	stopped   => WSTOPPED,
	continued => WCONTINUED,
);

sub waitid($type_name, $id, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $type = $types{$type_name} // croak "Unknown wait type $type_name";
	my $info = Signal::Info->new;
	my $s_flags = to_sflags(\%args);
	my $event = defined $args{event} ? $events{$args{event}} // croak("No such event $args{event}") : WEXITED;
	$event |= WNOWAIT if $args{nowait};
	$id = $id->fileno if $type_name eq 'pidfd' && Scalar::Util::blessed($id) && $id->isa('Linux::FD::Pid');
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;

	my $ident = $ring->waitid($type, $id, $info, $event, 0, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($info);
		} else {
			$future->fail(Future::Uring::Exception->new('waitid', $res, $sourcename, $line));
		}
	});

	$future->on_cancel(sub { $ring->cancel($ident, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub waitpid($pid, %args) {
	my $first = waitid('pid', $pid, %args);
	return $first->then(sub($info) {
		my $second = Future->new;
		my $status = $info->code == CLD_EXITED ? ($info->status << 8) :
			$info->code == CLD_DUMPED ? $info->status | 128 : $info->status;
		$second->done($status);
	});
}

# ABSTRACT: Future-returning io_uring functions

package
	Future::Uring::_Future;

use parent 'Future';

sub await($self) {
	$ring->run_once until $self->is_ready;
	return $self;
}

package
	Future::Uring::_TimeoutFuture;

use parent -norequire, 'Future::Uring::_Future';

sub update($original, $seconds, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $id = $original->udata('uring_id');

	my $time_spec = ref $seconds ? $seconds : Time::Spec->new($seconds);
	my $flags = $args{flags} // 0;
	my $s_flags = to_sflags(\%args);
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	$ring->timeout_update($time_spec, $id, $flags, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('timeout_update', $res, $sourcename, $line));
		} else {
			$future->done;
		}
		$time_spec;
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}


1;

# ABSTRACT: Future returning uring methods

__END__

=pod

=encoding UTF-8

=head1 NAME

Future::Uring - Future-returning io_uring functions

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Future::Uring;
 use Future::AsyncAwait;

 my $handle = await Future::Uring::open("input.txt");
 my $result = await $handle->write($buffer);

=head1 DESCRIPTION

B<NOTE: This module is an early/experimental release, API stability is not guaranteed yet>.

This module is an end-user friendly wrapper around Linux' C<io_uring> mechanism. Uring is based on two sets of ring buffers, the submission queue and the completion queue. For every I/O request you need to make (like to read a file, write a file, accept a socket connection, etc), you create a submission queue entry, that describes the I/O operation you need to get done and add it to the tail of the submission queue (SQ). Most functions have the same name name as their synchronous counterparts.

All IO functions take the following optional named parameters (many take additional ones):

=over 4

=item * async

Normal operation for io_uring is to try and issue a submission as non-blocking first, and if that fails, execute it in an async manner. To support more efficient overlapped operation of requests that the application knows/assumes will always (or most of the time) block, the application can ask for a submission to be issued async from the start. Note that this flag immediately causes the submission event to be offloaded to an async helper thread with no initial non-blocking attempt. This may be less efficient and should not be used liberally or without understanding the performance and efficiency tradeoffs.

=item * link

When this flag is specified, the submission event forms a link with the next submission event in the submission ring. That next submission event will not be started before the previous request completes. This, in effect, forms a chain of submission events, which can be arbitrarily long. The tail of the chain is denoted by the first submission event that does not have this flag set. Chains are not supported across submission boundaries. Even if the last submission event in a submission has this flag set, it will still terminate the current chain. This flag has no effect on previous submission event submissions, nor does it impact submission events that are outside of the chain tail. This means that multiple chains can be executing in parallel, or chains and individual submission events. Only members inside the chain are serialized. A chain of submission events will be broken if any request in that chain ends in error.

=item * hardlink

Like C<link>, except the links aren't severed if an error or unexpected result occurs.

=item * drain

When this flag is specified, the submission event will not be started before previously submitted submission events have completed, and new submission events will not be started before this one completes.

=item * timeout

This adds a link timeout to the request

=item * timeout_clock

This sets the timeout clock. It defaults to C<monotonic>.

=item * timeout_absolute

If set, the passed timeout will not be a relative time

=back

Several functions have two versions, the second one ending in C<at> (e.g. C<open> and C<openat>). In such cases the latter takes an additional directory descriptor as argument for each path argument; this will be used as base instead of the current directory. Passing undef is equivalent to passing it the current directory.

=head1 FUNCTIONS

=head2 run_once

 Future::Uring::run_once($timeout = undef)

This will submit all pending submission events. It will wait for C<$timeout> seconds for events, or indefinitely if it's undefined.

=head2 submit

 Future::Uring::submit;

This will submit all pending submissions to the kernel.

=head2 submissions_available

 Future::Uring::submissions_available;

Check the number of available submission queue events. One may need to submit pending entries before creating a chain, because all entries in a linked chains must be submitted together.

=head2 to_handle

 my $handle = Future::Uring::to_handle($fh)

This takes a Perl handle and turns it into a L<Future::Uring::Handle>.

=head2 link / linkat

 await Future::Uring::link($old_path, $new_path, %options)
 await Future::Uring::linkat($old_dirh, $old_path, $new_dir, $new_path, %options)

This creates a hard link from C<$new_path> to C<$old_path>.

This takes one additional named argument: C<follow_symlink>, if true and C<$oldpath> is a symlink, it will be followed before the operation.

=head2 mkdir / mkdirat

 await Future::Uring::mkdir($dirname, %options)
 await Future::Uring::mkdirat($dirh, $dirname, %options)

Make directory C<$dirname>.

=head2 open / openat

 my $handle = await Future::Uring::open($filename, $mode = '<', %options);
 my $handle = await Future::Uring::openat($dirh, $filename, $mode = '<', %options);

This opens a file, and returns it as a new L<handle|Future::Uring::Handle>.

This takes several additional options:

=over 4

=item * mode

The permission mode that will be used if the file is newly created (e.g. C<0644>).

=item * d_sync

If true, write operations on the file will complete according to the requirements of synchronized I/O data integrity completion.

=item * exclusive

Ensure that this call creates the file: if this flag is specified in conjunction with a creating C<$mode>, and path already exists, then open() fails with the error C<EEXIST>.

=item * no_follow

If the trailing component (i.e., basename) of path is a symbolic link, then the open fails with the error ELOOP. Symbolic links in earlier components of the pathname will still be followed.

=item * sync

If true write operations on the file will complete according to the requirements of synchronized I/O file integrity completion (by contrast with the synchronized I/O data integrity completion provided by C<d_sync>.

=item * tempfile

Create an unnamed temporary regular file. The path argument specifies a directory; an unnamed inode will be created in that directory's filesystem. Anything written to the resulting file will be lost when the last file descriptor is closed, unless the file is given a name.

=back

=head2 rename / renameat

 await Future::Uring::rename($old_path, $new_path, %options)
 await Future::Uring::renameat($old_dirh, $old_path, $new_dirh, $new_path, %options)

Rename the file at C<$old_path> to C<$new_path>.

=over 4

=item * exchange

Atomically exchange oldpath and newpath. Both pathnames must exist but may be of different types (e.g., one could be a non-empty directory and the other a symbolic link).

=item * no_replace

Don't overwrite newpath of the rename. Return an error if newpath already exists.

=back

=head2 rmdir / rmdirat

 await Future::Uring::rmdir($dir, %options)
 await Future::Uring::rmdirat($dirh, $dir, %options)

=head2 socket

 my $handle = await Future::Uring::socket($socket, $domain, $type = STREAM_SOCKET, $protocol = 0);

This creates a new L<handle|Future::Uring::Handle>, taking the same arguments as perl's built-in C<socket>.

=head2 timeout_for

 await Future::Uring::timeout_for($seconds, %options)

This creates a relative timeout for C<$seconds>. C<$seconds> must either be a number or a L<Time::Spec> object.

It takes one additional named argument: C<clock>, with allowed values are C<'monotonic'> (default), C<'boottime'> and C<'realtime'>.

=head2 timeout_until

 await Future::Uring::timeout_until($moment, %options)

This creates an absolute timeout for C<$moment>. C<$moment> must either be a number or a L<Time::Spec> object.

It takes one additional named argument: C<clock>, with allowed values are C<'monotonic'>, C<'boottime'> and C<'realtime'> (default).

=head2 unlink / unlinkat

 await Future::Uring::unlink($filename, %options)
 await Future::Uring::unlinkat($dirh, $filename, %options)

This will unlink the file at C<$filename>.

=head2 waitid

 await Future::Uring::waitid($type, $id, %options)

This will wait for a child process to terminate. It will return the status as a L<Signal::Info> object. The mechanism of process selection depends on the value of C<$type>.

=over 4

=item * C<'pid'>

It will wait for the process whose pid if C<$id>

=item * C<'pgid'>

It will wait for a child process from process group C<$id>.

=item * C<'pidfd'>

This will wait for the process behind pidfd C<$id>, which may be a L<Linux::FD::Pid> object instead of a descriptor.

=item * C<'all'>

This will ignore the value of C<$id>, and will wait for any child.

=back

It takes the following additional named arguments:

=over 4

=item * C<event>

The type of event what is waited for, it can be any of C<'exited'> (the default), C<'stopped'> or C<'continued'>.

=item * C<nowait>

If true, it will leave the child in a waitable state.

=back

=head2 waitpid

 await Future::Uring::waitpid($pid, %options)

This is a wrapper of C<waitid('pid', $pid, %options)>, except that it will return a conventional exit status instead of a L<Signal::Info> object.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
