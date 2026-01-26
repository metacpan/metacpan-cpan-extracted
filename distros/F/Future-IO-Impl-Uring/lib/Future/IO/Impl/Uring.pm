package Future::IO::Impl::Uring;
$Future::IO::Impl::Uring::VERSION = '0.006';
use 5.020;
use warnings;
use experimental 'signatures';

use parent 'Future::IO::ImplBase';
__PACKAGE__->APPLY;

use IO::Uring qw/IORING_TIMEOUT_ABS IORING_TIMEOUT_REALTIME IORING_TIMEOUT_ETIME_SUCCESS P_PID P_PGID P_ALL WEXITED/;
use Errno 'ETIME';
use Signal::Info qw/CLD_EXITED/;
use Time::Spec;
use IO::Socket;
use IO::Poll qw/POLLIN POLLOUT/;

my $ring = $Future::Uring::ring // IO::Uring->new(128);

sub accept($self, $fh) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $class = ref($fh);
	my $id = $ring->accept($fh, 0, sub($res, $flags) {
		if ($res >= 0) {
			my $accepted_fd = $class->new_from_fd($res, 'r+');
			$future->done($accepted_fd);
		} else {
			local $! = -$res;
			$future->fail("Accept: $!\n", accept => $fh, $!)
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub alarm($self, $seconds) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $time_spec = Time::Spec->new($seconds);
	my $id = $ring->timeout($time_spec, 0, IORING_TIMEOUT_REALTIME | IORING_TIMEOUT_ABS, 0, sub($res, $flags) {
		if ($res != -ETIME) {
			local $! = -$res;
			$future->fail("alarm: $!\n");
		} else {
			$future->done;
		}
		$time_spec;
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub connect($self, $fh, $name) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $id = $ring->connect($fh, $name, 0, sub($res, $flags) {
		if ($res < 0) {
			local $! = -$res;
			$future->fail("connect: $!\n", connect => $fh, $!);
		} else {
			$future->done;
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub poll($self, $fh, $mask) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $id = $ring->poll($fh, $mask, 0, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($res);
		} else {
			local $! = -$res;
			$future->fail("poll: $!\n", poll => $fh, $!);
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub recv($self, $fh, $length, $flags) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $buffer = "\0" x $length;
	$flags //= 0;
	my $id = $ring->recv($fh, $buffer, $flags, 0, 0, sub($res, $flags) {
		if ($res > 0) {
			$future->done($res == $length ? $buffer : substr($buffer, 0, $res));
		} elsif ($res == 0) {
			$future->done;
		} else {
			local $! = -$res;
			$future->fail("recv: $!\n", recv => $fh, $!);
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub send($self, $fh, $buffer, $flags, $to) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $callback = sub($res, $flags) {
		if ($res >= 0) {
			$future->done($res);
		} else {
			local $! = -$res;
			$future->fail("send: $!\n", send => $fh, $!);
		}
		$buffer;
	};
	$flags //= 0;
	my $id;
	if (defined $to) {
		$id = $ring->sendto($fh, $buffer, $flags, $to, 0, 0, $callback);
	} else {
		$id = $ring->send($fh, $buffer, $flags, 0, 0, $callback);
	}
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub sleep($self, $seconds) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $time_spec = Time::Spec->new($seconds);
	my $id = $ring->timeout($time_spec, 0, 0, 0, sub($res, $flags) {
		if ($res != -ETIME) {
			local $! = -$res;
			$future->fail("sleep: $!\n");
		} else {
			$future->done;
		}
		$time_spec;
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub sysread($self, $fh, $length) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $buffer = "\0" x $length;
	my $id = $ring->read($fh, $buffer, -1, 0, sub($res, $flags) {
		if ($res > 0) {
			$future->done($res == $length ? $buffer : substr($buffer, 0, $res));
		} elsif ($res == 0) {
			$future->done;
		} else {
			local $! = -$res;
			$future->fail("sysread: $!\n", sysread => $fh, $!);
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub syswrite($self, $fh, $buffer) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $id = $ring->write($fh, $buffer, -1, 0, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($res);
		} else {
			local $! = -$res;
			$future->fail("syswrite: $!\n", syswrite => $fh, $!);
		}
		$buffer;
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub waitpid($self, $pid) {
	my $future = Future::IO::Impl::Uring::_Future->new;
	my $info = Signal::Info->new;
	my ($type, $arg) = $pid > 0 ? (P_PID, $pid) : $pid < 0 ? (P_PGID, -$pid) : (P_ALL, 0);
	my $id = $ring->waitid($type, $arg, $info, WEXITED, 0, 0, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($info->code == CLD_EXITED ? ($info->status << 8) : $info->status);
		} else {
			local $! = -$res;
			$future->fail("waitpid: $!", waitpid => $pid, $!);
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

package
	Future::IO::Impl::Uring::_Future;

use parent 'Future';

sub await($self) {
	$ring->run_once until $self->is_ready;
	return $self;
}

1;

# ABSTRACT: A Future::IO implementation for IO::Uring

__END__

=pod

=encoding UTF-8

=head1 NAME

Future::IO::Impl::Uring - A Future::IO implementation for IO::Uring

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This module provides an implementation for L<Future::IO> which uses L<IO::Uring>.

There are no additional methods to use in this module; it simply has to be
loaded, and it will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::Uring;

   my $f = Future::IO->sleep(5);
   ...

It requires Linux kernel 6.7 or higher to function.

If L<Future::Uring> has been loaded before this module is, they will share their backend.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
