package IO::Async::Loop::Epoll::FD;
$IO::Async::Loop::Epoll::FD::VERSION = '0.004';
use strict;
use warnings;

use parent 'IO::Async::Loop::Epoll';

use Carp 'croak';
use Linux::FD 0.015 qw/timerfd signalfd/;
use Linux::FD::Pid 0.007;
use Scalar::Util qw/refaddr weaken/;
use Signal::Mask;

use constant _CAN_WATCH_ALL_PIDS => 0;

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{sigmask} = undef;
	return $self;
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

sub watch_time {
	my ($self, %params) = @_;

	my $code = $params{code} or croak "Expected 'code' as CODE ref";

	my $id;
	my $watch_time = $self->{watch_time} //= {};
	my $callback = sub {
		my $fh = $watch_time->{$id};
		$code->() if $fh && $fh->receive;
	};

	my $fh;
	if( defined $params{after} ) {
		my $after = $params{after} >= 0 ? $params{after} : 0;
		$fh = timerfd($params{clock} || 'monotonic', 'non-blocking');
		if ($after > 0) {
			$fh->set_timeout($after);
		} else {
			my $callback = sub {
				my $fh2 = $watch_time->{$id};
				$code->() if $fh2;
			};
			$self->watch_idle(code => $callback, when => 'later');
		}
	}
	else {
		$fh = Linux::FD::Timer->new($params{clock} || 'realtime', 'non-blocking');
		$fh->set_timeout($params{at}, 0, !!1);
	}

	$self->watch_io(handle => $fh, on_read_ready => $callback);

	$id = refaddr $fh;
	$self->{watch_time}{$id} = $fh;
	return $id;
}

sub unwatch_time {
	my ($self, $id) = @_;
	my $fh = delete $self->{watch_time}{$id};
	$self->unwatch_io(handle => $fh, on_read_ready => 1);
}

sub watch_process {
	my ($self, $process, $code) = @_;

	$code or croak "Expected 'code' as CODE ref";

	my $backref = $self;
	weaken $backref;
	my $callback = sub {
		if (my $pair = $backref->{watch_process}{$process}) {
			my ($fh, $code) = @{$pair};
			if (my $status = $fh->wait) {
				$code->($process, $status);
				$backref->unwatch_process($process);
			}
		}
	};

	my $fh = Linux::FD::Pid->new($process, 'non-blocking');
	$Signal::Mask{CHLD} ||= 1;
	$self->watch_io(handle => $fh, on_read_ready => $callback);

	$self->{watch_process}{$process} = [ $fh, $code ];
	return $process;
}

sub unwatch_process {
	my ($self, $id) = @_;
	if (my $pair = delete $self->{watch_process}{$id}) {
		$self->unwatch_io(handle => $pair->[0], on_read_ready => 1);
		$Signal::Mask{CHLD} = 0 if not keys %{ $self->{watch_process} };
	}
}

1;

# ABSTRACT: Use IO::Async with Epoll and special filehandles

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Async::Loop::Epoll::FD - Use IO::Async with Epoll and special filehandles

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This is a Linux specific backend for L<IO::Async|IO::Async>. Unlike L<IO::Async::Loop::Epoll|IO::Async::Loop::Epoll>, this will use signalfd for signal handling, timerfd for timer handling and pidfd for process handling.

=head1 SEE ALSO

=over 4

=item * L<IO::Async::Loop::Epoll|IO::Async::Loop::Epoll>

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
