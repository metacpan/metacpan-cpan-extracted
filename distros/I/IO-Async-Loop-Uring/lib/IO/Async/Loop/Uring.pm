package IO::Async::Loop::Uring;
$IO::Async::Loop::Uring::VERSION = '0.003';
use strict;
use warnings;

use parent 'IO::Async::Loop';

use Carp 'croak';
use Scalar::Util 'weaken';
use Errno 'ETIME';
use IO::Uring 0.009 qw/IORING_POLL_UPDATE_EVENTS P_PID P_ALL WEXITED IOSQE_ASYNC
                       IORING_TIMEOUT_ETIME_SUCCESS IORING_TIMEOUT_ABS IORING_TIMEOUT_BOOTTIME IORING_TIMEOUT_REALTIME/;
use IO::Poll qw/POLLIN POLLOUT POLLHUP POLLERR POLLPRI/;
use Linux::FD 0.015 qw/signalfd/;
use Signal::Mask;
use Signal::Info 'CLD_EXITED';
use Time::Spec;

use constant API_VERSION => '0.76';
use constant _CAN_ON_HANGUP => !!1;
use constant _CAN_SUBSECOND_ACCURATELY => !!0; # supported but buggy in IO::Async's tests
use constant _CAN_WATCH_ALL_PIDS => !!1;

use constant _CAN_WATCHDOG => !!1;
use constant WATCHDOG_ENABLE => IO::Async::Loop->WATCHDOG_ENABLE;

sub new {
	my ($class, %params) = @_;

	my $self = $class->__new(%params);
	$self->{ring} = IO::Uring->new(128);
	return $self;
}

sub loop_once {
	my ($self, $timeout, %params) = @_;
	my $ret;
	$self->pre_wait;
	if (defined $timeout and $timeout != 0) {
		$self->_adjust_timeout(\$timeout);
		my $timespec = Time::Spec->new($timeout);
		$ret = $self->{ring}->run_once(1, $timespec);
	} else {
		$ret = $self->{ring}->run_once(not defined $timeout);
	}
	$self->post_wait;

	return undef if !defined $ret and $! != ETIME;

	if( WATCHDOG_ENABLE and !$self->{alarmed} ) {
		alarm( IO::Async::Loop->WATCHDOG_INTERVAL );
		$self->{alarmed}++;

		$self->_manage_queues;

		alarm(0);
		undef $self->{alarmed};
	} else {
		$self->_manage_queues;
	}

	return 1;
}

sub is_running {
	my ($self) = @_;
	return $self->{running};
}

sub watch_io {
	my ($self, %params) = @_;

	$self->__watch_io(%params);

	my $handle = $params{handle};
	my $fileno = $handle->fileno;
	my $curmask = $self->{pollmask}{$fileno} // 0;

	my $mask = $curmask;
	$mask |= POLLIN if $params{on_read_ready};
	$mask |= POLLOUT if $params{on_write_ready};
	$mask |= POLLHUP if $params{on_hangup};

	return if $mask == $curmask;
	$self->{pollmask}{$fileno} = $mask;

	my $alarmed = \$self->{alarmed};

	my $this = $self;
	weaken $this;

	if (my $id = $self->{poll_id}{$fileno}) {
		$self->{ring}->poll_update($id, undef, $mask | POLLHUP | POLLERR, IORING_POLL_UPDATE_EVENTS, 0);
		return $id;
	} else {
		my $watch = $this->{iowatches}{$fileno};

		my $id = $self->{ring}->poll_multishot($handle, $mask | POLLHUP | POLLERR, 0, sub {
			my ($res, $flags) = @_;

			if ($res > 0) {
				if( WATCHDOG_ENABLE and !$$alarmed ) {
					alarm( IO::Async::Loop->WATCHDOG_INTERVAL );
					$$alarmed = 1;
				}

				if ($res & (POLLIN|POLLHUP|POLLERR)) {
					$watch->[1]->() if defined $watch->[1];
				}
				if ($res & (POLLOUT|POLLPRI|POLLHUP|POLLERR)) {
					$watch->[2]->() if defined $watch->[2];
				}
				if ($res & (POLLHUP|POLLERR)) {
					$watch->[3]->() if defined $watch->[3];
				}
			} elsif ($flags == 0 && $this->{iowatches}{$fileno} && $this->{iowatches}{$fileno} == $watch) {
				delete $this->{pollmask}{$fileno};
				delete $this->{poll_id}{$fileno};
				delete $this->{iowatches}{$fileno};
			}
		});
		$self->{poll_id}{$fileno} = $id;
		return $id;
	}
}

sub unwatch_io {
	my ($self, %params) = @_;

	$self->__unwatch_io(%params);

	my $handle = $params{handle};
	my $fileno = $handle->fileno;
	my $curmask = $self->{pollmask}{$fileno} // 0;
	my $id = $self->{poll_id}{$fileno} or croak "Can't unwatch unknown IO";

	my $mask = $curmask;
	$mask &= ~POLLIN if $params{on_read_ready};
	$mask &= ~POLLOUT if $params{on_write_ready};
	$mask &= ~POLLHUP if $params{on_hangup};

	return if $mask == $curmask;

	if ($mask == 0) {
		$self->{ring}->poll_remove($id, 0);
		delete $self->{pollmask}{$fileno};
		delete $self->{poll_id}{$fileno};
	} else {
		$self->{pollmask}{$fileno} = $mask;
		$self->{ring}->poll_update($id, undef, $mask | POLLHUP | POLLERR, 0, IORING_POLL_UPDATE_EVENTS);
	}
}

sub watch_signal {
	my ($self, $signal, $code) = @_;

	$code or croak "Expected 'code' as CODE ref";

	my $watch_signal = $self->{watch_signal} //= {};
	my $callback = sub {
		if (my $pair = $watch_signal->{$signal}) {
			my ($fh, $code) = @{$pair};
			while (my $info = $fh->receive) {
				$code->($info->{signo});
			}
		}
	};

	my $fh = signalfd($signal, 'non-blocking');
	$Signal::Mask{$signal} = !!1;
	$self->watch_io(handle => $fh, on_read_ready => $callback);

	$self->{watch_signal}{$signal} = [ $fh, $code ];
	return $signal;
}

sub unwatch_signal {
	my ($self, $signal) = @_;
	if (my $pair = delete $self->{watch_signal}{$signal}) {
		$self->unwatch_io(handle => $pair->[0], on_read_ready => 1);
		$Signal::Mask{$signal} = !!0;
	}
}

my %flag_for_clock = (
	monotonic => 0,
	boottime  => IORING_TIMEOUT_BOOTTIME,
	realtime  => IORING_TIMEOUT_REALTIME,
);

sub watch_time {
	my ($self, %params) = @_;

	my $code = $params{code} or croak "Expected 'code' as CODE ref";

	my $fh;
	if( defined $params{after} ) {
		my $after = $params{after} >= 0 ? $params{after} : 0;
		my $flags = IORING_TIMEOUT_ETIME_SUCCESS;
		$flags |= $flag_for_clock{$params{clock}} if defined $params{clock};

		my $spec = Time::Spec->new($after);
		return $self->{ring}->timeout($spec, 0, $flags, 0 * IOSQE_ASYNC, sub {
			my ($res, $flags) = @_;
			$code->() if $res == -ETIME;
			$spec;
		});
	}
	else {
		my $flags = IORING_TIMEOUT_ABS;
		my $clock = $params{clock} // 'realtime';
		$flags |= $flag_for_clock{$clock};

		my $spec = Time::Spec->new($params{at});
		return $self->{ring}->timeout($spec, 0, $flags, 0, sub {
			my ($res, $flags) = @_;
			$code->() if $res == -ETIME;
			$spec;
		});
	}
}

sub unwatch_time {
	my ($self, $id) = @_;
	$self->{ring}->cancel($id, 0, 0);
	return;
}

sub watch_process {
	my ($self, $process, $code) = @_;
	my $info = Signal::Info->new;
	my $this = $self;
	weaken $this;
	my $id = \(my $tmp);
	if ($process) {
		$$id = $self->{ring}->waitid(P_PID, $process, $info, WEXITED, 0, 0, sub {
			my ($res, $flags) = @_;
			if ($res >= 0) {
				my $status = $info->code == CLD_EXITED ? ($info->status << 8) : $info->status;
				$code->($process, $status);
			}
		});
	} else {
		$$id = $self->{ring}->waitid(P_ALL, 0, $info, WEXITED, 0, 0, sub {
			my ($res, $flags) = @_;
			if ($res >= 0) {
				my $status = $info->code == CLD_EXITED ? ($info->status << 8) : $info->status;
				$code->($info->pid, $status);
				$$id = $this->watch_process(0, $code);
			}
		});
	}
	return $id;
}

sub unwatch_process {
	my ($self, $id) = @_;
	$self->{ring}->cancel($$id, 0);
	return;
}

1;

# ABSTRACT: Use IO::Async with IO::Uring

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Async::Loop::Uring - Use IO::Async with IO::Uring

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use IO::Async::Loop::Uring;

 my $loop = IO::Async::Loop::Uring->new();

 $loop->add( ... );

 $loop->add( IO::Async::Signal->new(
       name => 'HUP',
       on_receipt => sub { ... },
 ) );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<IO::Uring> to perform its work. Because C<io_uring> is a quickly developing kernel subsystem, it requires a Linux 6.7 kernel or newer to function.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
