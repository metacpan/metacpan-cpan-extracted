package TestServer;

use strict;
use warnings;

use EV ();
use IO::Socket::INET;
use POSIX ();

my %REASON = (
    200 => q(OK),
    204 => q(No Content),
    301 => q(Moved Permanently),
    302 => q(Found),
    400 => q(Bad Request),
    404 => q(Not Found),
    500 => q(Internal Server Error),
);

# A minimal HTTP/1.1 server for the test suite. The handler is called with a
# request hashref and returns ($status, \@headers, $body); returning nothing
# closes the connection without a reply.
sub new {
    my ($class, $handler) = @_;

    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        Listen    => 32,
        ReuseAddr => 1,
    ) or die "TestServer: listen failed: $!";

    my $port = $listener->sockport;
    my $pid = fork;
    die "TestServer: fork failed: $!" unless defined $pid;

    if (!$pid) {
        $SIG{PIPE} = 'IGNORE';
        eval { setpgrp(0, 0) };   # so stop() can reach the per-connection children
        eval { _serve($listener, $handler) };
        POSIX::_exit(0);
    }

    close $listener;
    return bless { pid => $pid, port => $port }, $class;
}

sub port { $_[0]{port} }
sub base_url { 'http://127.0.0.1:' . $_[0]{port} }

sub stop {
    my ($self) = @_;
    return unless $self->{pid};
    kill 'KILL', -$self->{pid} or kill 'KILL', $self->{pid};
    waitpid $self->{pid}, 0;
    $self->{pid} = undef;
}

sub DESTROY { local $?; $_[0]->stop }

my $watchdog;

# Turns a wedged test into a failure instead of a hang. It has to be an EV
# watcher, since $SIG{ALRM} is only dispatched between Perl ops and so never
# arrives while blocked in EV::run, and it has to exit rather than die, since EV
# catches exceptions from a watcher callback and carries on. keepalive(0) stops
# it holding the loop open. A wedge that never re-enters EV::run is not covered.
sub watchdog {
    my ($seconds) = @_;
    $seconds ||= 60;

    $watchdog = EV::signal(ALRM => sub {
        print STDERR "# watchdog: no progress after ${seconds}s\n";
        exit 1;
    });
    $watchdog->keepalive(0);
    alarm $seconds;
}

sub _serve {
    my ($listener, $handler) = @_;

    $SIG{CHLD} = 'IGNORE';

    # One child per connection, so a keep-alive connection sitting idle cannot
    # stall the accept loop for the next one.
    while (my $conn = $listener->accept) {
        my $pid = fork;
        if (!defined $pid || $pid) {
            close $conn;
            next;
        }

        close $listener;
        $conn->autoflush(1);
        my $buffer = '';
        while (my $request = _read_request($conn, \$buffer)) {
            my ($status, $headers, $body) = $handler->($request);
            last unless defined $status;

            $body = '' unless defined $body;
            $headers ||= [];

            my $out = "HTTP/1.1 $status " . ($REASON{$status} || 'Status') . "\r\n"
                    . "Content-Length: " . length($body) . "\r\n";

            my $typed = 0;
            for (my $i = 0; $i < @$headers; $i += 2) {
                $typed = 1 if lc $headers->[$i] eq 'content-type';
                $out .= "$headers->[$i]: $headers->[$i + 1]\r\n";
            }
            $out .= "Content-Type: text/plain\r\n" unless $typed;
            $out .= "\r\n$body";

            last unless _write_all($conn, $out);
            last if lc($request->{headers}{connection} || '') eq 'close';
        }
        close $conn;
        POSIX::_exit(0);
    }
}

sub _fill {
    my ($conn, $buffer, $want) = @_;
    while (length($$buffer) < $want) {
        my $chunk;
        my $got = sysread $conn, $chunk, 65536;
        return 0 unless $got;
        $$buffer .= $chunk;
    }
    return 1;
}

sub _read_line {
    my ($conn, $buffer) = @_;
    my $end;
    while (($end = index $$buffer, "\r\n") < 0) {
        my $chunk;
        my $got = sysread $conn, $chunk, 65536;
        return undef unless $got;
        $$buffer .= $chunk;
    }
    my $line = substr $$buffer, 0, $end, '';
    substr $$buffer, 0, 2, '';
    return $line;
}

sub _read_chunked {
    my ($conn, $buffer) = @_;
    my ($body, %trailers) = ('');

    while (1) {
        my $line = _read_line($conn, $buffer);
        return undef unless defined $line && $line =~ /\A([0-9a-fA-F]+)/;
        my $size = hex $1;

        if (!$size) {
            while (defined(my $trailer = _read_line($conn, $buffer))) {
                last if $trailer eq '';
                next unless $trailer =~ /\A([^:]+):\s*(.*)\z/;
                $trailers{lc $1} = $2;
            }
            last;
        }

        _fill($conn, $buffer, $size + 2) or return undef;
        $body .= substr $$buffer, 0, $size, '';
        substr $$buffer, 0, 2, '';
    }

    return ($body, \%trailers);
}

sub _read_request {
    my ($conn, $buffer) = @_;

    my $end;
    while (($end = index $$buffer, "\r\n\r\n") < 0) {
        my $chunk;
        my $got = sysread $conn, $chunk, 65536;
        return undef unless $got;
        $$buffer .= $chunk;
    }

    my $head = substr $$buffer, 0, $end, '';
    substr $$buffer, 0, 4, '';

    my @lines = split /\r\n/, $head;
    my $start = shift @lines;
    return undef unless defined $start;
    my ($method, $target, undef) = split / /, $start;
    return undef unless defined $target;

    my %headers;
    for my $line (@lines) {
        next unless $line =~ /\A([^:]+):\s*(.*)\z/;
        my ($name, $value) = (lc $1, $2);
        $headers{$name} = exists $headers{$name} ? "$headers{$name}, $value" : $value;
    }

    my $body = '';
    my $trailers = {};

    if (lc($headers{'transfer-encoding'} || '') eq 'chunked') {
        ($body, $trailers) = _read_chunked($conn, $buffer);
        return undef unless defined $body;
    } elsif (my $length = $headers{'content-length'}) {
        return undef unless _fill($conn, $buffer, $length);
        $body = substr $$buffer, 0, $length, '';
    }

    my ($path, $query) = split /\?/, $target, 2;

    return {
        method   => $method,
        target   => $target,
        path     => $path,
        query    => defined $query ? $query : '',
        headers  => \%headers,
        trailers => $trailers,
        body     => $body,
    };
}

sub _write_all {
    my ($conn, $data) = @_;
    while (length $data) {
        my $written = syswrite $conn, $data;
        return 0 unless $written;
        substr $data, 0, $written, '';
    }
    return 1;
}

1;
