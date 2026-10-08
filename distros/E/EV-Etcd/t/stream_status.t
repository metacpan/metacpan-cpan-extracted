#!/usr/bin/env perl
# A minimal HTTP/2 peer rejects every RPC with a trailers-only gRPC error.
# This exercises the actual status path for all three streaming methods without
# toggling auth on an existing etcd or depending on server error translation.
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;
use POSIX ();

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

sub read_exact {
    my ($fh, $length) = @_;
    my $bytes = '';
    while (length($bytes) < $length) {
        my $n = sysread($fh, my $part, $length - length($bytes));
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

my @servers;
END { for my $pid (@servers) { local $?; kill 'TERM', $pid; waitpid $pid, 0 } }

# {n} in the message becomes the number of the request on that server
sub start_server {
    my ($status, $message) = @_;
    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1,
    ) or plan skip_all => "cannot create gRPC test listener: $!";
    my $endpoint = '127.0.0.1:' . $listener->sockport;
    my $pid = fork;
    plan skip_all => "fork failed: $!" unless defined $pid;
    if ($pid) {
        push @servers, $pid;
        close $listener;
        return $endpoint;
    }
    $SIG{PIPE} = 'IGNORE';
    alarm 30;
    my $requests = 0;
    while (my $peer = $listener->accept) {
        next unless defined read_exact($peer, 24);  # HTTP/2 client preface
        send_frame($peer, 4, 0, 0, '');             # SETTINGS
        while (defined(my $head = read_exact($peer, 9))) {
            my ($a, $b, $c, $type, $flags, $stream) = unpack 'C3 C C N', $head;
            my $payload = read_exact($peer, ($a << 16) | ($b << 8) | $c);
            last unless defined $payload;
            if ($type == 4 && !($flags & 1)) {
                send_frame($peer, 4, 1, 0, '');     # SETTINGS ACK
            } elsif ($type == 6 && !($flags & 1)) {
                send_frame($peer, 6, 1, 0, $payload); # PING ACK
            } elsif ($type == 1) {
                # HPACK: indexed :status=200, literal content-type=application/grpc,
                # then literal grpc-status and grpc-message; no Huffman coding.
                (my $text = $message) =~ s/\{n\}/++$requests/e;
                my $headers = "\x88\x0f\x10\x10application/grpc";
                for my $field (['grpc-status', $status], ['grpc-message', $text]) {
                    $headers .= pack('CC', 0, length $field->[0]) . $field->[0]
                        . pack('C', length $field->[1]) . $field->[1];
                }
                send_frame($peer, 1, 5, $stream, $headers); # END_HEADERS | END_STREAM
            }
        }
        close $peer;
    }
    POSIX::_exit(0);
}

my $endpoint = start_server(16, 'expired token {n}');
my $flaky = start_server(13, 'stream reset {n}');

my $client = EV::Etcd->new(endpoints => [$endpoint]);
my (%errors, %calls, @handles);
my $callback = sub {
    my $name = shift;
    return sub {
        $calls{$name}++;
        $errors{$name} = $_[1];
        EV::break if keys(%errors) == 3;
    };
};
push @handles, $client->watch('/stream-status', $callback->('watch'));
push @handles, $client->lease_keepalive(1, $callback->('keepalive'));
push @handles, $client->election_observe('/stream-status', $callback->('observe'));
my $timer = EV::timer(5, 0, sub { EV::break });
EV::run;
undef $timer;
for my $name (qw(watch keepalive observe)) {
    is($errors{$name} && $errors{$name}{status}, 'UNAUTHENTICATED', "$name retains final status");
    # Three streams, one request each: a reconnect would number past 3
    like($errors{$name} && $errors{$name}{message}, qr/^expired token [123]$/,
        "$name retains error details and does not reconnect");
    is($errors{$name} && $errors{$name}{retryable}, 0, "$name reports a non-retryable error");
    is($errors{$name} && $errors{$name}{source}, $name, "$name retains error source");
    is($calls{$name}, 1, "$name reports the error once");
}
my $cancelled = 0;
$_->cancel(sub { $cancelled++ }) for @handles;
is($cancelled, 3, 'handles remain safe after final-status cleanup');

# Dropping the client and handle inside a terminal callback must defer cleanup
# until that status completion has finished using their C structs.
undef @handles;
undef $client;
for my $method (qw(watch lease_keepalive election_observe)) {
    my $c = EV::Etcd->new(endpoints => [$endpoint]);
    my ($handle, $done);
    $handle = $c->$method($method eq 'lease_keepalive' ? 1 : '/stream-status', sub {
        undef $c;
        undef $handle;
        $done = 1;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($done, "$method can drop client and handle in the error callback");
}

# INTERNAL is how gRPC reports a stream reset by a proxy: reconnect, and
# report the error once max_retries is used up. The clients run one after
# another, so the request number shows how many attempts each made.
my $requests = 0;
for my $method (qw(watch lease_keepalive election_observe)) {
    my $c = EV::Etcd->new(endpoints => [$flaky], max_retries => 1);
    my ($error, $calls);
    my $handle = $c->$method($method eq 'lease_keepalive' ? 1 : '/stream-status', sub {
        $calls++;
        $error = $_[1];
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $requests += 2;
    is($error && $error->{status}, 'INTERNAL', "$method reports INTERNAL after retrying");
    is($error && $error->{message}, "stream reset $requests", "$method reconnected once");
    is($calls, 1, "$method reports the error once");
}

done_testing;
