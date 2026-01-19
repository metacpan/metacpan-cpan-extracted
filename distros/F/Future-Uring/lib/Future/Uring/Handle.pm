package Future::Uring::Handle;
$Future::Uring::Handle::VERSION = '0.001';
use 5.020;
use warnings;
use experimental 'signatures';

require Future::Uring;

*ring = *Future::Uring::ring;
our $ring;

use IO::Uring qw/
	IORING_FSYNC_DATASYNC IOSQE_ASYNC IOSQE_IO_LINK IOSQE_IO_HARDLINK IOSQE_IO_DRAIN IORING_RECVSEND_POLL_FIRST
	IORING_TIMEOUT_ABS IORING_TIMEOUT_BOOTTIME IORING_TIMEOUT_REALTIME
	/;
use IO::Poll qw/POLLIN POLLOUT/;

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

sub new($class, $fh) {
	return bless { fh => $fh }, $class;
}

sub inner($self) {
	return $self->{fh};
}

sub accept($self, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $class = $args{class} // ref $self->{fh};
	my $id = $ring->accept($self->{fh}, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			my $fh = $class->new_from_fd($res, 'w+');
			$future->done(Future::Uring::Handle->new($fh));
		} else {
			$future->fail(Future::Uring::Exception->new('accept', $res, $sourcename, $line));
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub allocate($self, $offset, $length, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->fallocate($self->{fh}, $offset, $length, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('allocate', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub bind($self, $name, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->bind($self->{fh}, $name, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('bind', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub close($self, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->close($self->{fh}, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('close', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub connect($self, $name, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->connect($self->{fh}, $name, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('connect', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub listen($self, $size, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->listen($self->{fh}, $size, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('listen', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub poll($self, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $mask = $args{mask} // 0;
	$mask |= POLLIN if $args{read};
	$mask |= POLLOUT if $args{write};
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->poll($self->{fh}, $mask, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('poll', $res, $sourcename, $line));
		} else {
			$future->done($res);
		}
	});
	if ($args{mutable}) {
		bless $future, 'Future::Uring::_PollFuture';
		$future->set_udata('uring_id', $id);
		$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	}
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub recv($self, $length, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $buffer = "\0" x $length;
	my $flags = $args{flags} // 0;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $p_flags = $args{poll_first} ? IORING_RECVSEND_POLL_FIRST : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->recv($self->{fh}, $buffer, $flags, $p_flags, $s_flags, sub($res, $flags) {
		if ($res > 0) {
			$future->done($res == $length ? $buffer : substr($buffer, 0, $res));
		} elsif ($res == 0) {
			$future->done;
		} else {
			$future->fail(Future::Uring::Exception->new('recv', $res, $sourcename, $line));
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub read($self, $length, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $buffer = "\0" x $length;
	my $offset = $args{offset} // -1;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->read($self->{fh}, $buffer, $offset, $s_flags, sub($res, $flags) {
		if ($res > 0) {
			$future->done($res == $length ? $buffer : substr($buffer, 0, $res));
		} elsif ($res == 0) {
			$future->done;
		} else {
			$future->fail(Future::Uring::Exception->new('read', $res, $sourcename, $line));
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub send($self, $buffer, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $flags = $args{flags} // 0;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $p_flags = $args{poll_first} ? IORING_RECVSEND_POLL_FIRST : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->send($self->{fh}, $buffer, $flags, $p_flags, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($res);
		} else {
			$future->fail(Future::Uring::Exception->new('send', $res, $sourcename, $line));
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub sendto($self, $buffer, $name, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $flags = $args{flags} // 0;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $p_flags = $args{poll_first} ? IORING_RECVSEND_POLL_FIRST : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->sendto($self->{fh}, $buffer, $flags, $name, $p_flags, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($res);
		} else {
			$future->fail(Future::Uring::Exception->new('sendto', $res, $sourcename, $line));
		}
		($buffer, $name);
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub shutdown($self, $how, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->shutdown($self->{fh}, $how, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('shutdown', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub splice($self, $out, $nbytes, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $off_in = $args{off_in} // -1;
	my $fh = $out->isa('Future::Uring::Handle') ? $out->inner : $out;
	my $off_out = $args{off_out} // -1;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->splice($self->{fh}, $off_in, $fh, $off_out, 0, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('splice', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub sync($self, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $flags = $args{datasync} ? IORING_FSYNC_DATASYNC : 0;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->fsync($self->{fh}, $flags, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('sync', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub tee($self, $out, $nbytes, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $fh = $out->isa('Future::Uring::Handle') ? $out->inner : $out;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->tee($self->{fh}, $fh, $nbytes, 0, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('tee', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub truncate($self, $length, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->ftruncate($self->{fh}, $length, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('truncate', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

sub write($self, $buffer, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $offset = $args{offset} // -1;
	my $s_flags = %args ? to_sflags(\%args) : 0;
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->write($self->{fh}, $buffer, $offset, $s_flags, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($res);
		} else {
			$future->fail(Future::Uring::Exception->new('write', $res, $sourcename, $line));
		}
		$buffer;
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

package
	Future::Uring::_PollFuture;

use parent -norequire, 'Future::Uring::_Future';

use IO::Uring qw/IORING_POLL_UPDATE_EVENTS/;
use IO::Poll qw/POLLIN POLLOUT/;

sub update($original, %args) {
	my $future = Future::Uring::_Future->new;
	my (undef, $sourcename, $line) = caller;
	my $old_id = $original->udata('uring_id');
	my $s_flags = %args ? to_sflags(\%args) : 0;
	my $mask = $args{mask} // 0;
	$mask |= POLLIN if $args{read};
	$mask |= POLLOUT if $args{write};
	$ring->submit if $args{timeout} && $ring->sq_space_left < 2;
	my $id = $ring->poll_update($old_id, undef, $mask, IORING_POLL_UPDATE_EVENTS, $s_flags, sub($res, $flags) {
		if ($res < 0) {
			$future->fail(Future::Uring::Exception->new('poll_update', $res, $sourcename, $line));
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) }) if $args{mutable};
	add_timeout($ring, \%args) if $args{timeout};
	return $future;
}

1;

# ABSTRACT: A Uring filehandle

__END__

=pod

=encoding UTF-8

=head1 NAME

Future::Uring::Handle - A Uring filehandle

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 while (1) {
   my $buffer = await $input->recv(512, timeout => 60);
   my $result = await $output->send($buffer, timeout => 10);
 }

=head1 DESCRIPTION

This is a Future::Uring handle. It offers fully asynchronous IO on a filehandle. Generally speaking its methods are the same as their well known symmetric counterparts (e.g. C<send>, C<listen>), though some have subtly different semantics (e.g. C<poll> taking only one filehandle).

=head1 METHODS

=head2 new

 my $handle = Future::Uring::Handle->new($fh)

This will create a new Uring handle based on a Perl handle C<$fh>.

=head2 inner

 my $fh = $handle->inner;

This will return the Perl filehandle inside the Uring handle.

=head2 accept

 my $conn = await $handle->accept(%options);

This will accept a new connection on a listening socket.

=head2 allocate

 await $handle->allocate($offset, $length, %options)

This will allocate space in the file.

=head2 bind

 await $handle->bind($sockaddr, %options)

Bind the socket to C<$sockaddr>.

=head2 connect

 await $handle->connect($sockaddr, %options)

Connect the socket to C<$sockaddr>.

=head2 listen

 await $handle->listen(%options);

Make the socket listen for new connections.

=head2 poll

 my $mask = await $handle->poll(%options);

This will poll the filehandle, it takes the following additional options.

=over 4

=item * mask

The polling mask, defaulting to C<0>.

=item * read

If true, it will add readability to the poll mask.

=item * write

If true, it will add writeability  to the poll mask.

=back

You probably need either C<mask>, or C<read>/C<write>. In any case, it will poll for hangup and other errors.

=head2 read

 my $data = await $handle->read($size, %options)

This will read up to C<$size> bytes from the handle.

It takes one additional named parameter, C<offset>, for the optional offset in the file.

=head2 recv

 my $data = await $handle->recv($size, %options)

Receive C<$size> bytes of data from a socket.

This takes two additional named arguments.

=over 4

=item * C<poll_first>.

If set io_uring will assume the socket is currently empty and attempting to receive data will be unsuccessful. For this case, io_uring will arm internal poll and trigger a receive of the data when the socket has data to be read. This initial receive attempt can be wasteful for the case where the socket is expected to be empty, setting this flag will bypass the initial receive attempt and go straight to arming poll. If poll does indicate that data is ready to be received, the operation will proceed.

=item * flags

This is the standard recv flags argument (e.g. C<MSG_WAITALL>, C<MSG_TRUNC>).

=back

=head2 send / sendto

 await $handle->send($data, %options)
 await $handle->sendto($data, $address, %options)

Send C<$data> over a socket.

This takes two additional named arguments.

=over 4

=item * C<poll_first>.

If set io_uring will assume the socket is currently full and attempting to send data will be unsuccessful. For this case, io_uring will arm internal poll and trigger a send of the data when the socket has space available. If poll does indicate that space is available in the socket, the operation will proceed immediately.

=item * flags

This is the standard recv flags argument (e.g. C<MSG_WAITALL>, C<MSG_TRUNC>).

=back

=head2 shutdown

 await $handle->shutdown($how, %options)

This shuts down one half of a connection. It's C<$how> argument takes the same values as the C<shutdown> builtin.

=head2 splice

 await $handle->splice($out, $nbytes, %options)

Splice data from the current handle to C<$out>. Either the input or the output must be a pipe. It optionally takes two additional named parameters:

=over 4

=item * off_in

The offset in the input file

=item * off_out

The offset in the output file

=back

=head2 sync

 await $handle->sync(%options)

This synchronizes a file to disk much like the C<fsync> system call does.

This takes one additional named argument, C<datasync> that makes it behave like C<fdatasync> instead.

=head2 tee($out_fh, $nbytes, %options)

 await $handle->tee($out, $nbytes, %options)

This copies C<$nbytes> bytes from the current handle to C<$out>.

=head2 truncate

 await $handle->truncate($length, %options)

This truncates a file to C<$length> bytes.

=head2 write

 await $handle->write($data, %options)

This writes C<$data> to C<$handle>.

It takes one additional named parameter, C<offset>, for the optional offset in the file.

=for Pod::Coverage close

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
