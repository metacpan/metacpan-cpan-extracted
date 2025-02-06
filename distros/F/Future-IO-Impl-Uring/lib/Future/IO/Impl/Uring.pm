package Future::IO::Impl::Uring;
$Future::IO::Impl::Uring::VERSION = '0.001';
use 5.020;
use warnings;
use experimental 'signatures';

use parent 'Future::IO::ImplBase';
__PACKAGE__->APPLY;

use IO::Uring qw/IOSQE_ASYNC IORING_TIMEOUT_ABS IORING_TIMEOUT_REALTIME IORING_TIMEOUT_ETIME_SUCCESS P_PID WEXITED/;
use Errno 'ETIME';
use Signal::Info qw/CLD_EXITED/;
use Time::Spec;
use IO::Socket;

my $ring = IO::Uring->new(32);

sub accept($self, $fh) {
	my $future = Future::IO::Uring::_Future->new;
	$ring->accept($fh, 0, sub($res, $flags) {
		if ($res >= 0) {
			my $accepted_fd = IO::Socket->new->fdopen($res, 'r+');
			$future->done($accepted_fd);
		} else {
			local $! = -$res;
			$future->fail("Accept: $!\n", accept => $fh, $!)
		}
	});
	return $future;
}

sub alarm($self, $seconds) {
	my $future = Future::IO::Uring::_Future->new;
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
	my $future = Future::IO::Uring::_Future->new;
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

sub sleep($self, $seconds) {
	my $future = Future::IO::Uring::_Future->new;
	my $time_spec = Time::Spec->new($seconds);
	$ring->timeout($time_spec, 0, 0, IOSQE_ASYNC, sub($res, $flags) {
		if ($res != -ETIME) {
			local $! = -$res;
			$future->fail("sleep: $!\n");
		} else {
			$future->done;
		}
		$time_spec;
	});
	return $future;
}

sub sysread($self, $fh, $length) {
	my $future = Future::IO::Uring::_Future->new;
	my $buffer = "\0" x $length;
	my $id = $ring->read($fh, $buffer, -1, IOSQE_ASYNC, sub($res, $flags) {
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

sub _sysread($fh, $future, $id, $buffer, $length, $offset) {
	$$id = $ring->read($fh, substr($buffer, $offset), -1, 0, sub($res, $flags) {
		if ($res >= 0) {
			if ($offset + $res == $length) {
				$future->done($buffer);
				#				$future->done($length ? $buffer : ());
			} else {
				_sysread($fh, $future, $id, $buffer, $length, $offset + $res);
			}
		} elsif($offset > 0) {
			$future->done(substr($buffer, $offset));
		} else {
			local $! = -$res;
			$future->fail("sysread: $!\n", sysread => $fh, $!);
		}
	});
}

sub sysread_exactly($self, $fh, $length) {
	my $future = Future::IO::Uring::_Future->new;
	my $buffer = "\0" x $length;
	my $id;
	_sysread($fh, $future, \$id, $buffer, $length, 0);
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub syswrite($self, $fh, $buffer) {
	my $future = Future::IO::Uring::_Future->new;
	my $id = $ring->write($fh, $buffer, -1, IOSQE_ASYNC, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($res);
		} else {
			local $! = -$res;
			$future->fail("syswrite: $!\n", syswrite => $fh, $!);
		}
	});
	$future->on_cancel(sub { $ring->cancel($id, 0, 0) });
	return $future;
}

sub _subwrite($future, $fh, $buffer, $written) {
	$ring->write($fh, $buffer, -1, sub($res, $flags) {
		if ($res > 0) {

		} else {
			local $! = -$res;
			$future->fail("syswrite: $!\n", syswrite => $fh, $!);
		}
	});
}

sub syswrite_exactly($self, $fh, $buffer) {
	my $future = Future::IO::Uring::_Future->new;
	_syswrite($fh, $buffer, 0);
	return $future;
}

sub waitpid($self, $pid) {
	my $future = Future::IO::Uring::_Future->new;
	my $info = Signal::Info->new;
	$ring->waitid(P_PID, $pid, $info, WEXITED, 0, 0, sub($res, $flags) {
		if ($res >= 0) {
			$future->done($info->code == CLD_EXITED ? ($info->status << 8) : $info->status);
		} else {
			$future->fail("waitpid: $!");
		}
	});
	return $future;
}

package
	Future::IO::Uring::_Future;

use parent 'Future';

sub await($self) {
	$ring->run_once until $self->is_ready;
	return $self;
}

# ABSTRACT: A Future::IO implementation for IO::Uring

__END__

=pod

=encoding UTF-8

=head1 NAME

Future::IO::Impl::Uring - A Future::IO implementation for IO::Uring

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This module provides an implementation for L<Future::IO> which uses L<IO::Uring>.

There are no additional methods to use in this module; it simply has to be
loaded, and it will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::Uring;

   my $f = Future::IO->sleep(5);
   ...

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
