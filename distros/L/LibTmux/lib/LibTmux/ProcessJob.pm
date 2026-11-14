package LibTmux::ProcessJob;
use v5.44;
use LibTmux::Transport ();
use LibTmux::X;
use Scalar::Util qw(refaddr weaken);
use Errno        qw(EINTR ECHILD);
use POSIX        qw(_exit);
use JSON::PP     ();
use MIME::Base64 qw(decode_base64 encode_base64);
my %active;

sub start ($class, %input) {
    my %args = LibTmux::Transport->_arguments(%input);
    my ($result_r, $result_w) = LibTmux::Transport::_pipe();
    my ($alive_r,  $alive_w)  = LibTmux::Transport::_pipe();
    my ($cancel_r, $cancel_w) = LibTmux::Transport::_pipe();
    LibTmux::Transport::_nonblock($cancel_w);
    $args{_cancel_r} = $cancel_r;
    my $job = bless {
        result_r        => $result_r,
        alive_w         => $alive_w,
        cancel_w        => $cancel_w,
        external_reaper => exists($args{spawner}),
        max_wire        => 3 * $args{max_output} + 131072,
        wire            => '',
        finished        => false
    }, $class;
    my $child = sub ($prepare = undef) {
        close $result_r;
        close $alive_w;
        close $cancel_w;
        for my $foreign (values %active) {
            next unless $foreign;
            for my $key (qw(result_r alive_w cancel_w)) {
                my $fh = $foreign->{$key};
                close $fh if $fh && defined fileno($fh);
            }
        }
        $SIG{PIPE} = 'IGNORE';
        $SIG{CHLD} = 'DEFAULT';
        my $record;
        my $preparing = true;
        try {
            $prepare->() if $prepare;
            $preparing = false;
            $record =
                LibTmux::Transport::_supervise(\%args, $alive_r, $result_w)
        }
        catch ($error) {
            my $type =
                Scalar::Util::blessed($error)
                && $error->isa('LibTmux::X')
                ? ref($error) =~ s/^LibTmux::X:://r
                : 'Transport';
            $record = {
                cleanup_complete => $preparing,
                error            =>
                    {type => $type, message => "$error", dispatched => false}
            };
        }
        my $wire   = JSON::PP->new->utf8->encode($record);
        my $offset = 0;
        while ($offset < length($wire)) {
            my $n =
                syswrite($result_w, $wire, length($wire) - $offset, $offset);
            next if !defined($n) && $! == EINTR;
            last unless defined($n) && $n > 0;
            $offset += $n;
        }
        close $result_w;
        _exit(0);
    };
    my $pid;
    if ($args{spawner}) {
        try { $pid = $args{spawner}->($child) }
        catch ($error) { close $alive_w; die $error }
    }
    else {
        $pid = fork();
        LibTmux::X::Spawn->throw(
            message    => "fork supervisor: $!",
            dispatched => false
        ) unless defined $pid;
        $child->() unless $pid;
    }
    LibTmux::X::Spawn->throw(
        message    => 'spawn adapter returned an invalid PID',
        dispatched => false
    ) unless defined($pid) && $pid =~ /\A[1-9][0-9]*\z/;
    $job->{pid} = $pid;
    close $result_w;
    close $alive_r;
    close $cancel_r;
    $active{refaddr($job)} = $job;
    weaken($active{refaddr($job)});
    return $job;
}
sub pid              ($self) { $self->{pid} }
sub cleanup_complete ($self) { !!$self->{cleanup_complete} }

sub take_result_handle ($self) {
    LibTmux::X::InvalidArgument->throw(
        message => 'result handle was already transferred')
        unless $self->{result_r};
    return delete $self->{result_r};
}

sub cancel ($self) {
    return if $self->{finished} || $self->{cancelled};
    $self->{cancelled} = true;
    if ($self->{cancel_w} && defined fileno($self->{cancel_w})) {
        local $SIG{PIPE} = 'IGNORE';
        my $written;
        do { $written = syswrite($self->{cancel_w}, 'c') }
            while (!defined($written) && $! == EINTR);
    }
    return;
}

sub consume ($self, $bytes) {
    LibTmux::X::Transport->throw(
        message    => 'supervisor result exceeds its wire limit',
        dispatched => true
    ) if length($self->{wire}) + length($bytes) > $self->{max_wire};
    $self->{wire} .= $bytes;
}

sub finish ($self) {
    if ($self->{finished}) {
        die $self->{error} if $self->{error};
        return $self->{result};
    }
    $self->{finished} = true;
    for my $key (qw(alive_w cancel_w result_r)) {
        my $fh = delete $self->{$key};
        close $fh if $fh && defined fileno($fh);
    }
    delete $active{refaddr $self};
    my $record;
    try {
        $record = JSON::PP->new->utf8->max_size($self->{max_wire})
            ->decode(delete $self->{wire});
        LibTmux::X::Transport->throw(
            message    => 'invalid supervisor result',
            dispatched => true
        ) unless ref($record) eq 'HASH';
        $self->{cleanup_complete} = !!$record->{cleanup_complete};
        if ($record->{error} && !exists $record->{stdout}) {
            my $error = $record->{error};
            my $type  = $error->{type} // 'Transport';
            $type = 'Transport' unless "LibTmux::X::$type"->isa('LibTmux::X');
            "LibTmux::X::$type"->throw(%$error);
        }
        for my $key (qw(stdout stderr exit_code signal raw_status)) {
            LibTmux::X::Transport->throw(
                message    => "missing supervisor result $key",
                dispatched => true
            ) unless exists($record->{$key}) && !ref($record->{$key});
        }
        my %bytes;
        for my $key (qw(stdout stderr)) {
            LibTmux::X::Transport->throw(
                message    => "invalid supervisor $key encoding",
                dispatched => true
            ) unless defined($record->{$key});
            $bytes{$key} = decode_base64($record->{$key});
            LibTmux::X::Transport->throw(
                message    => "invalid supervisor $key encoding",
                dispatched => true
            ) unless encode_base64($bytes{$key}, '') eq $record->{$key};
        }
        $self->{result} = bless {
            stdout     => $bytes{stdout},
            stderr     => $bytes{stderr},
            exit_code  => $record->{exit_code},
            signal     => $record->{signal},
            raw_status => $record->{raw_status}
            },
            'LibTmux::CommandResult';
        if ($record->{error}) {
            my $error = $record->{error};
            my $type  = $error->{type} // 'Transport';
            $type = 'Transport' unless "LibTmux::X::$type"->isa('LibTmux::X');
            "LibTmux::X::$type"->throw(%$error, result => $self->{result});
        }
    }
    catch ($error) {
        $self->{error} =
            Scalar::Util::blessed($error) && $error->isa('LibTmux::X')
            ? $error
            : LibTmux::X::Transport->new(
            message    => 'supervisor exited without a valid result',
            dispatched => true
            );
        die $self->{error};
    }
    return $self->{result};
}

sub wait ($self) {
    LibTmux::X::InvalidArgument->throw(
        message => 'loop-owned jobs cannot use blocking wait')
        if $self->{external_reaper};
    local ($!, $?);
    my $fh = $self->take_result_handle;
    try {
        while (true) {
            my $n = sysread($fh, my $chunk, 65536);
            next if !defined($n) && $! == EINTR;
            LibTmux::X::Transport->throw(
                message    => "read supervisor: $!",
                dispatched => true
            ) unless defined $n;
            last unless $n;
            $self->consume($chunk);
        }
    }
    catch ($error) { $self->cancel; close $fh; $self->_reap; die $error }
    close $fh;
    $self->_reap;
    return $self->finish;
}

sub _reap ($self) {
    while (waitpid($self->pid, 0) < 0) {
        last if $! == ECHILD;
        next if $! == EINTR;
        last;
    }
}

sub DESTROY ($self) {
    delete $active{refaddr $self};
    for my $key (qw(result_r alive_w cancel_w)) {
        my $fh = $self->{$key};
        close $fh if $fh && defined fileno($fh);
    }
}

=head1 NAME

LibTmux::ProcessJob - Shared owned process-supervision boundary

=head1 METHODS

=head2 start

Start a supervised literal command using the same arguments as
L<LibTmux::Transport/run>. This explicit operation performs I/O.

=head2 pid

Return the supervisor PID. It differs from the program PID.

=head2 cleanup_complete

True only after a valid supervisor result proves owned program cleanup.

=head2 take_result_handle

Transfer the result pipe exactly once. Its reader owns closing that handle.

=head2 consume

Accumulate bounded result octets. Malformed or excessive data is a failure.

=head2 finish

Decode the complete result after EOF and supervisor exit. Return one
L<LibTmux::CommandResult|LibTmux::Transport/RESULTS> or throw a typed error.

=head2 cancel

Request cleanup without blocking. Cancellation can follow dispatch and does
not imply rollback or completed reaping.

=head2 wait

The synchronous reader/reaper. A loop-owned job refuses blocking wait.
Async adapters supply a spawn/reap callback and retain jobs through EOF plus
the matching exit notification. Dropping a job closes its parent guard but
does not synchronously wait; owners must complete their cleanup protocol.

=cut
