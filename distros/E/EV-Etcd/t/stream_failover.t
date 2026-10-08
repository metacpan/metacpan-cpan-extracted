#!/usr/bin/env perl
# A connected HTTP/2 peer returns UNAVAILABLE; streams must use the next endpoint.
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;
use POSIX ();
use Errno qw(EINTR);

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

plan skip_all => "etcd not available on 127.0.0.1:2379"
    unless IO::Socket::INET->new(PeerAddr => "127.0.0.1:2379", Timeout => 2);

sub read_exact {
    my ($fh, $length) = @_;
    my $bytes = '';
    while (length($bytes) < $length) {
        my $n = sysread($fh, my $part, $length - length($bytes));
        next if !defined($n) && $! == EINTR;
        return unless $n;
        $bytes .= $part;
    }
    return $bytes;
}
sub send_frame {
    my ($fh, $type, $flags, $stream, $payload) = @_;
    my $len = length $payload;
    my $bytes = pack('C3 C C N', ($len >> 16) & 255, ($len >> 8) & 255,
        $len & 255, $type, $flags, $stream) . $payload;
    while (length $bytes) {
        my $n = syswrite($fh, $bytes);
        return unless $n;
        substr($bytes, 0, $n, '');
    }
    return 1;
}
my $listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1,
) or die $!;
my $endpoint = '127.0.0.1:' . $listener->sockport;
pipe my $ack_read, my $ack_write or die $!;
my $pid = fork;
defined $pid or die $!;
unless ($pid) {
    close $ack_read;
    $SIG{PIPE} = 'IGNORE';
    alarm 90;
    my ($mode, $held, $peer, $held_watch) = (0, 0);
    $SIG{USR1} = sub { $mode++; $held = 0; syswrite($ack_write, 'M') };
    my $initial_headers = "\x88\x0f\x10\x10application/grpc";
    my $leader_trailers = '';
    for my $field (['grpc-status', '14'], ['grpc-message', 'etcdserver: no leader']) {
        $leader_trailers .= pack('CC', 0, length $field->[0]) . $field->[0]
            . pack('C', length $field->[1]) . $field->[1];
    }
    my $temporary_headers = $initial_headers;
    for my $field (['grpc-status', '14'], ['grpc-message', 'temporary failure']) {
        $temporary_headers .= pack('CC', 0, length $field->[0]) . $field->[0]
            . pack('C', length $field->[1]) . $field->[1];
    }
    my $changed_headers = $initial_headers;
    for my $field (['grpc-status', '14'], ['grpc-message', 'etcdserver: leader changed']) {
        $changed_headers .= pack('CC', 0, length $field->[0]) . $field->[0]
            . pack('C', length $field->[1]) . $field->[1];
    }
    my $lost_headers = $initial_headers;
    for my $field (['grpc-status', '14'],
                   ['grpc-message', 'etcdserver: request timed out, possibly due to connection lost']) {
        $lost_headers .= pack('CC', 0, length $field->[0]) . $field->[0]
            . pack('C', length $field->[1]) . $field->[1];
    }
    my $failover_headers = $initial_headers;
    for my $field (['grpc-status', '14'],
                   ['grpc-message', 'etcdserver: request timed out, possibly due to previous leader failure']) {
        $failover_headers .= pack('CC', 0, length $field->[0]) . $field->[0]
            . pack('C', length $field->[1]) . $field->[1];
    }
    my %mode_headers;
    for my $mode ([8, 4, 'context deadline exceeded'], [9, 2, 'context deadline exceeded'],
                  [10, 8, 'etcdserver: mvcc: database space exceeded'],
                  [11, 8, 'etcdserver: too many requests'],
                  [12, 2, 'etcdserver: request timed out']) {
        my $headers = $initial_headers;
        for my $field (['grpc-status', $mode->[1]], ['grpc-message', $mode->[2]]) {
            $headers .= pack('CC', 0, length $field->[0]) . $field->[0]
                . pack('C', length $field->[1]) . $field->[1];
        }
        $mode_headers{$mode->[0]} = $headers;
    }
    $SIG{USR2} = sub {
        send_frame($peer, 1, 5, $held_watch, $leader_trailers) if $peer && defined $held_watch;
    };
    while (1) {
        $peer = $listener->accept or next;
        $held_watch = undef;
        next unless defined read_exact($peer, 24);
        send_frame($peer, 4, 0, 0, '');
        while (defined(my $head = read_exact($peer, 9))) {
            my ($a, $b, $c, $type, $flags, $stream) = unpack 'C3 C C N', $head;
            my $payload = read_exact($peer, ($a << 16) | ($b << 8) | $c);
            last unless defined $payload;
            if ($type == 4 && !($flags & 1)) {
                send_frame($peer, 4, 1, 0, '');
            } elsif ($type == 6 && !($flags & 1)) {
                send_frame($peer, 6, 1, 0, $payload);
            } elsif ($type == 1) {
                # Hold blocking requests; the second phase also holds a watch
                # until quorum loss is signalled after the client has rotated.
                if ($mode && $held++ < ($mode == 1 ? 3 : $mode >= 5 ? 0 : 2)) {
                    send_frame($peer, 1, 4, $stream, $initial_headers);
                    if ($mode == 1 && $held == 3) {
                        # WatchResponse{created: true} makes it an established stream
                        send_frame($peer, 0, 0, $stream, "\0" . pack('N', 2) . "\x18\x01");
                        $held_watch = $stream;
                    }
                    syswrite($ack_write, 'B');
                } else {
                    send_frame($peer, 1, 5, $stream, $mode == 1 ? $temporary_headers
                        : $mode == 5 ? $changed_headers : $mode == 6 ? $lost_headers
                        : $mode == 7 ? $failover_headers
                        : $mode_headers{$mode} // $initial_headers . $leader_trailers);
                    syswrite($ack_write, 'R') if $mode;
                }
            }
        }
        close $peer;
    }
    POSIX::_exit(0);
}
close $listener;
close $ack_write;
END { if ($pid) { local $?; kill 'TERM', $pid; waitpid $pid, 0 } }
sub rpc {
    my ($client, $method, @args) = @_;
    my ($resp, $error, $done);
    $client->$method(@args, sub { ($resp, $error) = @_; $done = 1; EV::break });
    my $t = EV::timer(4, 0, sub { EV::break });
    EV::run;
    die "$method: " . ($error ? $error->{message} : 'timeout') if $error || !$done;
    return $resp;
}
my $writer = EV::Etcd->new;
my $lease = rpc($writer, 'lease_grant', 30)->{id};
my $election = "/test-stream-failover-$$";
my $leader = rpc($writer, 'election_campaign', $election, $lease, 'leader')->{leader};
my $client = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:2379'], max_retries => 2);
my (%success, %error, @handles);
my $callback = sub {
    my $name = shift;
    return sub {
        if ($_[1]) { $error{$name} = $_[1] }
        else { $success{$name} = 1 }
        EV::break if keys(%error) + keys(%success) >= 3;
    };
};
push @handles, $client->watch('/test-stream-failover', $callback->('watch'));
push @handles, $client->lease_keepalive($lease, $callback->('keepalive'));
push @handles, $client->election_observe($election, $callback->('observe'));
my $timer = EV::timer(5, 0, sub { EV::break });
EV::run;
undef $timer;
for my $name (qw(watch keepalive observe)) {
    ok($success{$name}, "$name fails over from a connected UNAVAILABLE endpoint");
    diag explain($error{$name}) if $error{$name};
}
$_->cancel(sub {}) for @handles;

{
    # A generic failure preserves accepted calls; later quorum loss on their
    # retired connection must still terminate them without another rotation.
    my ($mode_ready, $acknowledged, $refused) = (0, 0, 0);
    my $ack_io;
    $ack_io = EV::io(fileno($ack_read), EV::READ, sub {
        my $n = sysread($ack_read, my $bytes, 64);
        unless ($n) { $ack_io->stop; return }
        $mode_ready = 1 if $bytes =~ /M/;
        $acknowledged += $bytes =~ tr/B/B/;
        $refused += $bytes =~ tr/R/R/;
    });
    # Generous: slow CI runners need seconds for a fresh connection
    my $wait_for = sub {
        my $condition = shift;
        my $poll = EV::timer(0.01, 0.01, sub { EV::break if $condition->() });
        my $guard = EV::timer(10, 0, sub { EV::break });
        my $started = EV::time;
        EV::run;
        die sprintf("mock server did not acknowledge the request: waited %.1fs at line %d, mock %s, ack watcher %s\n",
            EV::time - $started, (caller)[2], kill(0, $pid) ? 'alive' : 'gone',
            $ack_io->is_active ? 'active' : 'stopped')
            unless $condition->();
    };
    kill 'USR1', $pid;
    $wait_for->(sub { $mode_ready });
    my $c = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:2379'], timeout => 1);
    my (%done, %errors, $first_error, $next_error, $next_done, $watch_ready, $watch_error);
    $c->lock("$election/lock", $lease, sub { $done{lock}++; $errors{lock} = $_[1] });
    $wait_for->(sub { $acknowledged == 1 });
    $c->election_campaign("$election/campaign", $lease, 'leader', sub {
        $done{campaign}++; $errors{campaign} = $_[1];
    });
    $wait_for->(sub { $acknowledged == 2 });
    my $w = $c->watch("$election/watch", sub {
        $watch_error = $_[1];
        $watch_ready++ if $_[0] && $_[0]{created};
    });
    $wait_for->(sub { $acknowledged == 3 && $watch_ready });
    $c->get($election, sub {
        $first_error = $_[1];
        $c->get($election, sub { $next_done = 1; $next_error = $_[1]; EV::break });
    });
    my $guard = EV::timer(4, 0, sub { EV::break });
    EV::run;
    undef $guard;
    my $settle = EV::timer(0.2, 0, sub { EV::break });
    EV::run;
    is($first_error && $first_error->{status}, 'UNAVAILABLE', 'connected failure rotates the endpoint');
    ok($next_done && !$next_error, 'the next request reaches the healthy endpoint');
    is($done{lock}, undef, 'established contended lock stays pending across rotation');
    is($done{campaign}, undef, 'established contended campaign stays pending across rotation');

    my $lock_name = "$election-current-lock";
    my $held_lock = rpc($writer, 'lock', $lock_name, $lease);
    my $waiting_lease = rpc($writer, 'lease_grant', 30)->{id};
    my (%current_done, %current_errors, $registered);
    $c->lock($lock_name, $waiting_lease, sub {
        $current_done{lock}++; $current_errors{lock} = $_[1];
    });
    $c->election_campaign($election, $waiting_lease, 'waiter', sub {
        $current_done{campaign}++; $current_errors{campaign} = $_[1];
    });
    for (1 .. 30) {
        my $locks = rpc($writer, 'get', "$lock_name/", { prefix => 1 })->{kvs};
        my $campaigns = rpc($writer, 'get', "$election/", { prefix => 1 })->{kvs};
        if (@$locks == 2 && @$campaigns == 2) { $registered = 1; last }
        my $tick = EV::timer(0.1, 0, sub { EV::break });
        EV::run;
    }
    ok($registered, 'new contended calls reached the healthy current member');

    kill 'USR2', $pid;
    $wait_for->(sub { $done{lock} && $done{campaign} && $watch_ready > 1 });
    for my $name (qw(lock campaign)) {
        is($done{$name}, 1, "late quorum loss ends retired $name once");
        is($errors{$name} && $errors{$name}{status}, 'UNAVAILABLE', "$name reports the unavailable member");
        is($errors{$name} && $errors{$name}{retryable}, 0, "$name requires a fresh lease");
        like($errors{$name} && $errors{$name}{message}, qr/etcdserver: no leader/, "$name retains the reason");
    }
    is($watch_error, undef, 'retired watch reconnects without a terminal error');
    is(scalar keys %current_done, 0, 'old quorum loss preserves contended calls on the current connection');
    rpc($c, 'get', $election);
    pass('late failure does not rotate the healthy current endpoint');
    rpc($writer, 'unlock', $held_lock->{key});
    rpc($writer, 'election_resign', $leader);
    $wait_for->(sub { keys %current_done == 2 });
    for my $name (qw(lock campaign)) {
        is($current_done{$name}, 1, "current $name acquires after the holder releases");
        is($current_errors{$name}, undef, "current $name completes without an error");
    }
    rpc($writer, 'lease_revoke', $waiting_lease);
    $w->cancel(sub {});
    undef $c;

    # A unary no-leader response does the same, with or without another endpoint.
    for my $endpoints ([$endpoint], [$endpoint, '127.0.0.1:2379']) {
        ($mode_ready, $acknowledged) = (0, 0);
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => $endpoints, timeout => 1);
        my (%done, %errors);
        $c->lock("$election/unary-lock", $lease, sub { $done{lock}++; $errors{lock} = $_[1] });
        $wait_for->(sub { $acknowledged == 1 });
        $c->election_campaign("$election/unary-campaign", $lease, 'leader', sub {
            $done{campaign}++; $errors{campaign} = $_[1];
        });
        $wait_for->(sub { $acknowledged == 2 });
        $c->get($election, sub { $done{get}++; $errors{get} = $_[1] });
        $wait_for->(sub { keys %done == 3 });
        for my $name (qw(lock campaign get)) {
            is($done{$name}, 1, "$name completes once on unary quorum loss with " . @$endpoints . ' endpoint(s)');
            is($errors{$name} && $errors{$name}{status}, 'UNAVAILABLE', "$name reports unavailable");
            is($errors{$name} && $errors{$name}{retryable}, $name eq 'get' ? 1 : 0,
                "$name reports whether the same request can be retried");
            like($errors{$name} && $errors{$name}{message}, qr/etcdserver: no leader/, "$name retains the reason");
        }
        rpc($c, 'get', $election) if @$endpoints > 1;
    }

    # etcd refuses every new stream during an election. That must neither end
    # waiting locks nor use up the reconnect budget.
    {
        ($mode_ready, $acknowledged) = (0, 0);
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => [$endpoint], max_retries => 1);
        my (%done, %errors);
        $c->lock("$election/refused-lock", $lease, sub { $done{lock}++; $errors{lock} = $_[1] });
        $wait_for->(sub { $acknowledged == 1 });
        $c->election_campaign("$election/refused-campaign", $lease, 'leader', sub {
            $done{campaign}++; $errors{campaign} = $_[1];
        });
        $wait_for->(sub { $acknowledged == 2 });
        $refused = 0;
        my @streams = (
            $c->watch("$election/refused", sub { $done{watch}++; $errors{watch} = $_[1] }),
            $c->lease_keepalive($lease, sub { $done{keepalive}++; $errors{keepalive} = $_[1] }),
            $c->election_observe($election, sub { $done{observe}++; $errors{observe} = $_[1] }),
        );
        my $t = EV::timer(3.5, 0, sub { EV::break });
        EV::run;
        cmp_ok($refused, '>=', 9, 'refused streams retry beyond max_retries');
        is_deeply(\%done, {}, 'refused streams report nothing and leave waiting locks alone');
        diag explain(\%errors) if %errors;
        $_->cancel(sub {}) for @streams;
    }

    # Nor with a dead endpoint next in turn: each refusal shows the cluster is
    # reachable and restarts the count the dead endpoint uses up.
    {
        my $c = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:1'], max_retries => 1);
        my %errors;
        $refused = 0;
        my @streams = (
            $c->watch("$election/refused", sub { $errors{watch} = $_[1] }),
            $c->lease_keepalive($lease, sub { $errors{keepalive} = $_[1] }),
            $c->election_observe($election, sub { $errors{observe} = $_[1] }),
        );
        my $t = EV::timer(5, 0, sub { EV::break });
        EV::run;
        cmp_ok($refused, '>=', 6, 'streams alternate between the refusing and the dead endpoint');
        is_deeply(\%errors, {}, 'the dead endpoint does not use up max_retries');
        diag explain(\%errors) if %errors;
        $_->cancel(sub {}) for @streams;
    }

    # A working member answers "leader changed" during an election; another
    # member would say the same, so the client stays on this one
    {
        $mode_ready = 0;
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:2379'], timeout => 1);
        my @errors;
        for (1 .. 2) {
            my $done;
            $c->get($election, sub { push @errors, $_[1]; $done = 1 });
            $wait_for->(sub { $done });
        }
        is(scalar(grep { $_ && $_->{message} eq 'etcdserver: leader changed' } @errors), 2,
            'a leader change does not move the client to another endpoint');
    }

    # A timeout from a member cut off from its peers must move the client
    {
        $mode_ready = 0;
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:2379'], timeout => 1);
        my @errors;
        for (1 .. 2) {
            my $done;
            $c->get($election, sub { push @errors, $_[1]; $done = 1 });
            $wait_for->(sub { $done });
        }
        like($errors[0] && $errors[0]{message}, qr/possibly due to connection lost/,
            'an isolated member answers with a timeout');
        is($errors[1], undef, 'which moves the client to the next endpoint');
    }

    # A timeout blamed on the previous leader is part of the same election
    {
        $mode_ready = 0;
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:2379'], timeout => 1);
        my @errors;
        for (1 .. 2) {
            my $done;
            $c->get($election, sub { push @errors, $_[1]; $done = 1 });
            $wait_for->(sub { $done });
        }
        is(scalar(grep { $_ && $_->{message} =~ /previous leader failure/ } @errors), 2,
            'a timeout after a leader failure does not move the client either');
    }

    # A write that waited out etcd's own request timeout for a leader; etcd 3.5
    # and 3.4 report it with different codes
    for my $status (qw(DEADLINE_EXCEEDED UNKNOWN)) {
        $mode_ready = 0;
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:2379'], timeout => 1);
        my @errors;
        for (1 .. 2) {
            my $done;
            $c->get($election, sub { push @errors, $_[1]; $done = 1 });
            $wait_for->(sub { $done });
        }
        is($errors[0] && "$errors[0]{status} $errors[0]{message}", "$status context deadline exceeded",
            "the member reports its own timeout as $status");
        is($errors[1], undef, 'which moves the client to the next endpoint');
    }

    for my $case (['etcdserver: mvcc: database space exceeded', 0], ['etcdserver: too many requests', 1]) {
        $mode_ready = 0;
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => [$endpoint]);
        my ($error, $done);
        $c->get($election, sub { $error = $_[1]; $done = 1 });
        $wait_for->(sub { $done });
        is($error && "$error->{status} $error->{message}", "RESOURCE_EXHAUSTED $case->[0]",
            'RESOURCE_EXHAUSTED reaches the callback');
        is($error && $error->{retryable}, $case->[1], "'$case->[0]' reports retryable $case->[1]");
    }

    # The election service reports etcd's timeout as UNKNOWN
    {
        $mode_ready = 0;
        kill 'USR1', $pid;
        $wait_for->(sub { $mode_ready });
        my $c = EV::Etcd->new(endpoints => [$endpoint, '127.0.0.1:2379'], timeout => 1);
        my @errors;
        for (1 .. 2) {
            my $done;
            $c->get($election, sub { push @errors, $_[1]; $done = 1 });
            $wait_for->(sub { $done });
        }
        is($errors[0] && "$errors[0]{status} $errors[0]{message}", 'UNKNOWN etcdserver: request timed out',
            'the election service reports the timeout as UNKNOWN');
        is($errors[1], undef, 'which moves the client to the next endpoint too');
    }
    $ack_io->stop;
    undef $ack_io;
}
rpc($writer, 'lease_revoke', $lease);
done_testing;
