package Linux::Event::Proactor;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Socket qw(SHUT_RD SHUT_WR SHUT_RDWR);
our $VERSION = '0.010';

use Linux::Event::Clock ();
use Linux::Event::Operation ();
use Linux::Event::Proactor::Backend::Fake ();
use Linux::Event::Proactor::Backend::Uring ();

use constant NS_PER_S => 1_000_000_000;

sub new ($class, %arg) {
    my $backend_name = $arg{backend} // 'fake';
    croak 'backend must be fake or uring'
        unless $backend_name eq 'fake' || $backend_name eq 'uring';

    my $clock = $arg{clock} // Linux::Event::Clock->new(clock => 'monotonic');
    croak 'clock must provide tick()'
        unless $clock->can('tick');
    croak 'clock must provide now_ns()'
        unless $clock->can('now_ns');

    my $self = bless {
        backend_name   => $backend_name,
        backend        => undef,
        clock          => $clock,
        running        => 0,
        stop_requested => 0,
        next_op_id     => 1,
        queue_size     => $arg{queue_size} // 64,

        ops_by_token   => {},
        callback_queue => [],
        callback_head  => 0,
        live_op_count  => 0,
    }, $class;

    if ($backend_name eq 'fake') {
        $self->{backend} = Linux::Event::Proactor::Backend::Fake->_new(
            loop => $self,
            %arg,
        );
    }
    else {
        $self->{backend} = Linux::Event::Proactor::Backend::Uring->_new(
            loop => $self,
            %arg,
        );
    }

    return $self;
}

sub clock ($self) { return $self->{clock} }
sub backend_name ($self) { return $self->{backend_name} }
sub live_op_count ($self) { return $self->{live_op_count} }
sub is_running ($self) { return $self->{running} ? 1 : 0 }
sub drain_callbacks ($self) { return $self->_drain_callback_queue }

sub run ($self) {
    $self->{running}        = 1;
    $self->{stop_requested} = 0;

    while (!$self->{stop_requested}) {
        $self->run_once;
    }

    $self->{running} = 0;
    return;
}

sub run_once ($self) {
    my $n_events = $self->{backend}->_complete_backend_events;
    my $n_cbs    = $self->_drain_callback_queue;
    return $n_events + $n_cbs;
}

sub stop ($self) {
    $self->{stop_requested} = 1;
    return;
}

sub read ($self, %arg) {
    $self->_validate_read_args(%arg);
    return $self->_submit_op('read', %arg);
}

sub write ($self, %arg) {
    $self->_validate_write_args(%arg);
    return $self->_submit_op('write', %arg);
}

sub recv ($self, %arg) {
    $self->_validate_recv_args(%arg);
    return $self->_submit_op('recv', %arg);
}

sub send ($self, %arg) {
    $self->_validate_send_args(%arg);
    return $self->_submit_op('send', %arg);
}

sub accept ($self, %arg) {
    $self->_validate_accept_args(%arg);
    return $self->_submit_op('accept', %arg);
}

sub connect ($self, %arg) {
    $self->_validate_connect_args(%arg);
    return $self->_submit_op('connect', %arg);
}

sub shutdown ($self, %arg) {
    $self->_validate_shutdown_args(%arg);
    $arg{how} = $self->_normalize_shutdown_how($arg{how});
    return $self->_submit_op('shutdown', %arg);
}

sub close ($self, %arg) {
    $self->_validate_close_args(%arg);
    return $self->_submit_op('close', %arg);
}

sub after ($self, $seconds, %arg) {
    $self->_validate_after_args($seconds, %arg);
    my $deadline_ns = $self->_deadline_ns_after($seconds);
    return $self->_submit_op('timeout', deadline_ns => $deadline_ns, %arg);
}

sub at ($self, $deadline, %arg) {
    $self->_validate_at_args($deadline, %arg);
    my $deadline_ns = $self->_deadline_ns_at($deadline);
    return $self->_submit_op('timeout', deadline_ns => $deadline_ns, %arg);
}


sub _new_op ($self, %arg) {
    return Linux::Event::Operation->_new(
        loop     => $self,
        kind     => $arg{kind},
        data     => $arg{data},
        callback => $arg{on_complete},
    );
}

sub _submit_op ($self, $kind, %arg) {
    croak 'kind is required' unless defined $kind;

    my $method = "_submit_$kind";
    my $backend = $self->{backend};
    croak "backend does not support $method" unless $backend->can($method);

    my $op = $self->_new_op(
        kind        => $kind,
        data        => $arg{data},
        on_complete => $arg{on_complete},
    );

    my $token = $backend->$method($op, %arg);
    croak 'token is required' unless defined $token;
    croak "duplicate token registration: $token" if exists $self->{ops_by_token}{$token};

    $op->_set_backend_token($token);
    $self->{ops_by_token}{$token} = $op;
    $self->{live_op_count}++;

    return $op;
}

sub _unregister_op ($self, $token) {
    return undef unless defined $token;

    my $op = delete $self->{ops_by_token}{$token};
    return undef unless $op;

    $self->{live_op_count}-- if $self->{live_op_count} > 0;
    return $op;
}

sub _cancel_op ($self, $op) {
    return 0 if $op->is_terminal;
    return $self->{backend}->_cancel_op($op);
}

sub _enqueue_callback ($self, $op) {
    push @{ $self->{callback_queue} }, $op;
    return;
}

sub _drain_callback_queue ($self) {
    my $queue = $self->{callback_queue};
    my $head  = $self->{callback_head};
    my $tail  = scalar(@{$queue});
    my $count = 0;

    while ($head < $tail) {
        my $op = $queue->[$head++];
        $op->_run_callback if defined $op;
        $count++;
    }

    @{$queue} = ();
    $self->{callback_head} = 0;

    return $count;
}

sub _tick_clock ($self) {
    $self->{clock}->tick;
    return $self->{clock}->now_ns;
}

sub _now_ns ($self) {
    return $self->_tick_clock;
}

sub _seconds_to_ns ($self, $seconds) {
    return int($seconds * NS_PER_S);
}

sub _deadline_ns_after ($self, $seconds) {
    my $delta_ns = $self->_seconds_to_ns($seconds);
    $delta_ns = 0 if $delta_ns < 0;

    my $now_ns = $self->_now_ns;
    return $now_ns + $delta_ns;
}

sub _deadline_ns_at ($self, $deadline) {
    return $self->_seconds_to_ns($deadline);
}

sub _remaining_ns_until ($self, $deadline_ns) {
    my $now_ns = $self->_now_ns;
    my $rem = $deadline_ns - $now_ns;
    return $rem > 0 ? $rem : 0;
}

sub _fake_complete_read_success ($self, $token, $chunk) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_read_success'
        unless $backend->can('_fake_complete_read_success');
    return $backend->_fake_complete_read_success($token, $chunk);
}

sub _fake_complete_read_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_read_error'
        unless $backend->can('_fake_complete_read_error');
    return $backend->_fake_complete_read_error($token, %arg);
}

sub _fake_complete_write_success ($self, $token, $bytes) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_write_success'
        unless $backend->can('_fake_complete_write_success');
    return $backend->_fake_complete_write_success($token, $bytes);
}

sub _fake_complete_write_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_write_error'
        unless $backend->can('_fake_complete_write_error');
    return $backend->_fake_complete_write_error($token, %arg);
}

sub _fake_complete_recv_success ($self, $token, $chunk) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_recv_success'
        unless $backend->can('_fake_complete_recv_success');
    return $backend->_fake_complete_recv_success($token, $chunk);
}

sub _fake_complete_recv_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_recv_error'
        unless $backend->can('_fake_complete_recv_error');
    return $backend->_fake_complete_recv_error($token, %arg);
}

sub _fake_complete_send_success ($self, $token, $bytes) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_send_success'
        unless $backend->can('_fake_complete_send_success');
    return $backend->_fake_complete_send_success($token, $bytes);
}

sub _fake_complete_send_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_send_error'
        unless $backend->can('_fake_complete_send_error');
    return $backend->_fake_complete_send_error($token, %arg);
}

sub _fake_complete_accept_success ($self, $token, $fh, $addr = undef) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_accept_success'
        unless $backend->can('_fake_complete_accept_success');
    return $backend->_fake_complete_accept_success($token, $fh, $addr);
}

sub _fake_complete_accept_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_accept_error'
        unless $backend->can('_fake_complete_accept_error');
    return $backend->_fake_complete_accept_error($token, %arg);
}

sub _fake_complete_connect_success ($self, $token) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_connect_success'
        unless $backend->can('_fake_complete_connect_success');
    return $backend->_fake_complete_connect_success($token);
}

sub _fake_complete_connect_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_connect_error'
        unless $backend->can('_fake_complete_connect_error');
    return $backend->_fake_complete_connect_error($token, %arg);
}

sub _fake_complete_shutdown_success ($self, $token) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_shutdown_success'
        unless $backend->can('_fake_complete_shutdown_success');
    return $backend->_fake_complete_shutdown_success($token);
}

sub _fake_complete_shutdown_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_shutdown_error'
        unless $backend->can('_fake_complete_shutdown_error');
    return $backend->_fake_complete_shutdown_error($token, %arg);
}

sub _fake_complete_close_success ($self, $token) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_close_success'
        unless $backend->can('_fake_complete_close_success');
    return $backend->_fake_complete_close_success($token);
}

sub _fake_complete_close_error ($self, $token, %arg) {
    my $backend = $self->{backend};
    croak 'active backend does not support _fake_complete_close_error'
        unless $backend->can('_fake_complete_close_error');
    return $backend->_fake_complete_close_error($token, %arg);
}

sub _validate_read_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh len data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    croak 'len is required' unless exists $arg{len};
    croak 'len must be defined' unless defined $arg{len};
    croak 'len must be non-negative' if $arg{len} < 0;
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_write_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh buf data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    croak 'buf is required' unless exists $arg{buf};
    croak 'buf must be defined' unless defined $arg{buf};
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_recv_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh len flags data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    croak 'len is required' unless exists $arg{len};
    croak 'len must be defined' unless defined $arg{len};
    croak 'len must be non-negative' if $arg{len} < 0;
    if (exists $arg{flags}) {
        croak 'flags must be defined' unless defined $arg{flags};
        croak 'flags must be an integer' if $arg{flags} !~ /\A-?\d+\z/;
    }
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_send_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh buf flags data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    croak 'buf is required' unless exists $arg{buf};
    croak 'buf must be defined' unless defined $arg{buf};
    if (exists $arg{flags}) {
        croak 'flags must be defined' unless defined $arg{flags};
        croak 'flags must be an integer' if $arg{flags} !~ /\A-?\d+\z/;
    }
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_accept_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_connect_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh addr data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    croak 'addr is required' unless exists $arg{addr};
    croak 'addr must be defined' unless defined $arg{addr};
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_shutdown_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh how data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    croak 'how is required' unless exists $arg{how};
    croak 'how must be defined' unless defined $arg{how};
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_close_args ($self, %arg) {
    $self->_validate_allowed_keys(\%arg, qw(fh data on_complete));
    croak 'fh is required' unless exists $arg{fh};
    croak 'fh is required' unless defined $arg{fh};
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_after_args ($self, $seconds, %arg) {
    croak 'after requires seconds' unless defined $seconds;
    $self->_validate_allowed_keys(\%arg, qw(data on_complete));
    $self->_validate_common_args(%arg);
    return;
}

sub _validate_at_args ($self, $deadline, %arg) {
    croak 'at requires deadline' unless defined $deadline;
    $self->_validate_allowed_keys(\%arg, qw(data on_complete));
    $self->_validate_common_args(%arg);
    return;
}

sub _normalize_shutdown_how ($self, $how) {
    if (defined($how) && !ref($how) && $how =~ /\A[0-9]+\z/ && ($how == SHUT_RD || $how == SHUT_WR || $how == SHUT_RDWR)) {
        return $how;
    }

    return SHUT_RD   if defined($how) && !ref($how) && $how eq 'read';
    return SHUT_WR   if defined($how) && !ref($how) && $how eq 'write';
    return SHUT_RDWR if defined($how) && !ref($how) && $how eq 'both';

    croak "how must be 'read', 'write', 'both', SHUT_RD, SHUT_WR, or SHUT_RDWR";
}

sub _validate_common_args ($self, %arg) {
    if (exists $arg{on_complete} && defined $arg{on_complete} && ref($arg{on_complete}) ne 'CODE') {
        croak 'on_complete must be a coderef';
    }
    return;
}

sub _validate_allowed_keys ($self, $href, @allowed) {
    my %allowed = map { $_ => 1 } @allowed;
    for my $key (keys %{$href}) {
        croak "unknown argument: $key" unless $allowed{$key};
    }
    return;
}

1;

__END__

=head1 NAME

Linux::Event::Proactor - Completion-based event loop engine for Linux::Event

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;

  my $loop = Linux::Event::Loop->new(
    model   => 'proactor',
    backend => 'uring',
  );

  my $op = $loop->recv(
    fh          => $fh,
    len         => 4096,
    flags       => 0,
    data        => { request_id => 1 },
    on_complete => sub ($op, $result, $ctx) {
      return if $op->is_cancelled;

      if ($op->failed) {
        warn $op->error->message;
        return;
      }

      my $bytes = $result->{bytes};
      my $buf   = $result->{data};
      my $eof   = $result->{eof};
    },
  );

  while ($loop->live_op_count) {
    $loop->run_once;
  }

=head1 DESCRIPTION

C<Linux::Event::Proactor> is the completion-based engine in this distribution.
It submits operations to a backend such as io_uring, tracks them with
L<Linux::Event::Operation> objects, and dispatches completion callbacks through
a deferred callback queue.

The core invariants are:

=over 4

=item * callbacks never run inline

=item * operations settle exactly once

=item * cancellation must remain race-safe

=item * the operation registry remains consistent

=back

=head1 CONSTRUCTOR

=head2 new(%args)

Recognized arguments:

=over 4

=item * C<backend>

Backend name or backend object. Supported backend names in this release are
C<uring> and C<fake>.

=item * C<queue_size>

Backend queue size. Defaults to 256.

=item * C<clock>

Clock object. The proactor uses a monotonic clock for timer operations.

=item * backend-specific options

Arguments such as C<submit_batch_size>, C<cqe_entries>, and C<sqpoll> are
passed through to the uring backend.

=back

=head1 LIFECYCLE

=head2 run

Run until C<stop> is called.

=head2 run_once

Process one round of backend completions and deferred callbacks.
Returns the combined count of processed backend events and callbacks.

=head2 stop

Request that a running loop stop.

=head2 is_running

True while C<run> is active.

=head1 OPERATIONS

Each submission method returns a L<Linux::Event::Operation>.

=head2 read

  $loop->read(fh => $fh, len => $bytes, %opt)

Result shape:

  { bytes => N, data => $string, eof => 0|1 }

=head2 write

  $loop->write(fh => $fh, buf => $buffer, %opt)

Result shape:

  { bytes => N }

=head2 recv

  $loop->recv(fh => $fh, len => $bytes, flags => 0, %opt)

Socket-oriented read with flags. Result shape matches C<read>.

=head2 send

  $loop->send(fh => $fh, buf => $buffer, flags => 0, %opt)

Socket-oriented write with flags. Result shape matches C<write>.

=head2 accept

  $loop->accept(fh => $listen_fh, %opt)

Result shape:

  { fh => $client_fh, addr => $sockaddr }

=head2 connect

  $loop->connect(fh => $fh, addr => $sockaddr, %opt)

Successful result shape:

  {}

=head2 shutdown

  $loop->shutdown(fh => $fh, how => 'read' | 'write' | 'both', %opt)

Numeric shutdown constants are also accepted. Successful result shape is C<{}>.

=head2 close

  $loop->close(fh => $fh, %opt)

Successful result shape is C<{}>.

=head2 after

  $loop->after($seconds, %opt)

=head2 at

  $loop->at($deadline_seconds, %opt)

Timer result shape:

  { expired => 1 }

=head1 CALLBACKS

User callbacks are supplied with C<on_complete>. The callback ABI is:

  $cb->($op, $result, $data)

The callback is never executed inline from backend completion delivery. Instead,
it is queued and drained by C<run_once> or C<drain_callbacks>.

=head1 ACCESSORS

=head2 clock

Returns the clock object.

=head2 backend_name

Returns the backend name.

=head2 live_op_count

Returns the number of operations still registered with the loop.

=head2 drain_callbacks

Manually drain the deferred callback queue. This is primarily useful for tests
and advanced control flows.

=head1 SEE ALSO

L<Linux::Event::Loop>,
L<Linux::Event::Operation>,
L<Linux::Event::Error>,
L<Linux::Event::Proactor::Backend>,
L<Linux::Event::Proactor::Backend::Uring>,
L<Linux::Event::Proactor::Backend::Fake>

=cut
