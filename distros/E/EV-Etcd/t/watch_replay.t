#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;
use IO::Select;
use Time::HiRes qw(time);
use POSIX ();

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

# Probe without starting gRPC, so the proxy child inherits no gRPC threads.
plan skip_all => 'etcd not available on 127.0.0.1:2379'
    unless IO::Socket::INET->new(PeerAddr => '127.0.0.1:2379', Timeout => 2);

sub write_all {
    my ($fh, $bytes) = @_;
    while (length $bytes) {
        my $n = syswrite $fh, $bytes;
        return unless $n;
        substr($bytes, 0, $n, '');
    }
    return 1;
}

# Drop the first connection after delivering only the watch-created message.
# Later connections are relayed without changes. Fork before gRPC starts.
my $listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1,
) or plan skip_all => "cannot create proxy listener: $!";
my $proxy_endpoint = '127.0.0.1:' . $listener->sockport;
my $proxy_pid = fork;
defined $proxy_pid or die "fork: $!";
unless ($proxy_pid) {
    $SIG{PIPE} = 'IGNORE';
    alarm 30;
    my $first = 1;
    while (my $down = $listener->accept) {
        my $up = IO::Socket::INET->new(PeerAddr => '127.0.0.1:2379')
            or POSIX::_exit(2);
        my $select = IO::Select->new($up, $down);
        my ($buffer, $delivered, $close_at) = ('', 0, 0);
        local $SIG{USR1} = sub { $close_at = time };
        while (!$close_at || time < $close_at) {
            my @ready = $select->can_read(0.02);
            my $ended = 0;
            for my $fh (@ready) {
                my $n = sysread $fh, my $bytes, 65536;
                unless ($n) { $ended = 1; last }
                if (fileno($fh) == fileno($down)) {
                    write_all($up, $bytes) or $ended = 1;
                } elsif (!$first) {
                    write_all($down, $bytes) or $ended = 1;
                } else {
                    $buffer .= $bytes;
                    while (length($buffer) >= 9) {
                        my ($a, $b, $c, $type, $flags, $stream) =
                            unpack 'C3 C C N', substr($buffer, 0, 9);
                        my $len = ($a << 16) | ($b << 8) | $c;
                        last if length($buffer) < 9 + $len;
                        my $frame = substr($buffer, 0, 9 + $len, '');
                        if ($type == 0 && $stream) {
                            next if $delivered;
                            my $body = substr($frame, 9);
                            my $message_len = unpack 'N', substr($body, 1, 4);
                            die 'split created message' if $len < 5 + $message_len;
                            my $keep = 5 + $message_len;
                            $frame = pack('C3 C C N', ($keep >> 16) & 255,
                                ($keep >> 8) & 255, $keep & 255, $type, 0, $stream)
                                . substr($body, 0, $keep);
                            $delivered = 1;
                            $close_at = time + 0.2;
                        }
                        write_all($down, $frame) or $ended = 1;
                    }
                }
            }
            last if $ended;
        }
        close $down;
        close $up;
        $first = 0;
    }
    POSIX::_exit(0);
}
close $listener;
END {
    if ($proxy_pid) { local $?; kill 'TERM', $proxy_pid; waitpid $proxy_pid, 0 }
}

sub rpc {
    my ($client, $method, @args) = @_;
    my ($resp, $err, $done);
    $client->$method(@args, sub { ($resp, $err) = @_; $done = 1; EV::break });
    my $timer = EV::timer(4, 0, sub { EV::break });
    EV::run;
    die "$method failed: " . ($err ? $err->{message} : 'timeout') if $err || !$done;
    return $resp;
}

my $key = "/adversarial-replay-$$";
my $writer = EV::Etcd->new;
my $start = rpc($writer, 'put', $key, 'v1')->{header}{revision};
rpc($writer, 'put', $key, 'v2');
my $latest = rpc($writer, 'put', $key, 'v3')->{header}{revision};
my $client = EV::Etcd->new(endpoints => [$proxy_endpoint], max_retries => 1);
my (@values, $created, $err);
my $watch = $client->watch($key, { start_revision => $start }, sub {
    my ($resp, $error) = @_;
    if ($error) { $err = $error; EV::break; return }
    $created++ if $resp->{created};
    note "created=$resp->{created}, header=$resp->{header}{revision}, events="
        . scalar @{$resp->{events}};
    push @values, map { $_->{kv}{value} } @{$resp->{events}};
    EV::break if @values == 3;
});
my $timer = EV::timer(3, 0, sub { EV::break });
EV::run;
undef $timer;
ok($created >= 2, 'watch reconnected after creation-only connection drop');
is($err, undef, 'reconnect reports no error');
is_deeply(\@values, [qw(v1 v2 v3)], 'historical events survive drop before replay');
note "requested start=$start, server current=$latest, delivered=" . join(',', @values);
rpc($writer, 'put', $key, 'v4');
my $wait = EV::timer(0.2, 0, sub { EV::break });
EV::run;
undef $wait;
ok(grep($_ eq 'v4', @values), 'reconnected watch still receives future events');
$watch->cancel(sub {});
rpc($writer, 'delete', $key);

# Repeated successful recoveries must reset the budget even when the watched
# key is quiet. Writes elsewhere leave an empty historical replay to catch up.
my $idle_key = "$key/idle";
my ($idle_created, $idle_error, $idle_progress, @idle_values) = (0, undef, 0);
my $idle = $client->watch($idle_key, sub {
    my ($resp, $err) = @_;
    if ($err) { $idle_error = $err; EV::break; return }
    $idle_created++ if $resp->{created};
    $idle_progress++ if !$resp->{created} && !@{$resp->{events}};
    push @idle_values, map { $_->{kv}{value} } @{$resp->{events}};
});
wait_for(sub { $idle_created || $idle_error }, 3);
is($idle_created, 1, 'idle watch created');
for my $n (2 .. 4) {
    rpc($writer, 'put', "$key/unrelated", "$n");
    kill 'USR1', $proxy_pid;
    wait_for(sub { $idle_created >= $n || $idle_error }, 3);
    cmp_ok($idle_created, '>=', $n, "idle watch recovers from disconnect " . ($n - 1));
    is($idle_error, undef, 'successful recovery resets the retry budget');
    wait_for(sub { $idle_error }, 0.5);
}
is($idle_progress, 0, 'internal recovery progress is not a user notification');
rpc($writer, 'put', $idle_key, 'awake');
wait_for(sub { @idle_values || $idle_error }, 3);
is_deeply(\@idle_values, ['awake'], 'idle watch delivers after repeated reconnects');
$idle->cancel(sub {});
rpc($writer, 'delete', $idle_key);
rpc($writer, 'delete', "$key/unrelated");

# A future start revision must also survive reconnect, without moving backward
# to the current revision advertised by the new created response.
my $future_key = "$key/future";
my $future_revision = rpc($writer, 'get', $future_key)->{header}{revision} + 50;
my ($future_created, @future_events, $future_error);
my $future = $client->watch($future_key, { start_revision => $future_revision }, sub {
    my ($resp, $err) = @_;
    if ($err) { $future_error = $err; EV::break; return }
    $future_created++ if $resp->{created};
    push @future_events, @{$resp->{events}};
});
sub wait_for {
    my ($condition, $seconds) = @_;
    my $check = EV::timer(0.02, 0.02, sub { EV::break if $condition->() });
    my $guard = EV::timer($seconds, 0, sub { EV::break });
    EV::run;
}
wait_for(sub { $future_created }, 3);
ok($future_created, 'future watch created');
kill 'USR1', $proxy_pid;
wait_for(sub { $future_created >= 2 || $future_error }, 3);
cmp_ok($future_created, '>=', 2, 'future watch reconnected');
is($future_error, undef, 'future watch reconnect reports no error');
my $put_revision = rpc($writer, 'put', $future_key, 'too early')->{header}{revision};
wait_for(sub { @future_events }, 0.2);
cmp_ok($put_revision, '<', $future_revision, 'put precedes the requested start revision');
is(scalar @future_events, 0, 'reconnect preserves the future start revision');
$future->cancel(sub {});
rpc($writer, 'delete', $future_key);

# Each value fits the request limit, but the replay exceeds gRPC's default
# 4 MiB receive limit, which would fail it on every retry
my $large_prefix = "$key/large/";
my $large_start;
for my $i (1 .. 6) {
    my $resp = rpc($writer, 'put', "$large_prefix$i", 'x' x (800 * 1024));
    $large_start //= $resp->{header}{revision};
}
my $large_client = EV::Etcd->new(max_retries => 2);
my ($large_events, @large_errors) = (0);
my $large = $large_client->watch($large_prefix, {
    prefix => 1, start_revision => $large_start,
}, sub {
    my ($resp, $err) = @_;
    if ($err) { push @large_errors, $err; EV::break; return }
    $large_events += @{$resp->{events}};
});
wait_for(sub { @large_errors || $large_events == 6 }, 5);
is($large_events, 6, 'replay larger than 4 MiB is delivered');
is(scalar @large_errors, 0, 'without an error') or diag explain \@large_errors;
my $range = rpc($large_client, 'get', $large_prefix, { prefix => 1 });
is(scalar @{$range->{kvs}}, 6, 'a range response larger than 4 MiB is delivered');
$large->cancel(sub {});
rpc($writer, 'delete', $large_prefix, { prefix => 1 });
done_testing;
