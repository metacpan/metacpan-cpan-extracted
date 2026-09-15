package t::lib::EchoServer;

use strict;
use warnings;
use HTTP::Server::PSGI;
use JSON::PP qw(encode_json);
use File::Temp qw(tempfile);
use POSIX qw(:sys_wait_h);
use IO::Socket::INET;

# A real local HTTP server for Client tests to POST against, in the same spirit as
# sdks/php/tests/fixtures/echo_server.php: Perl can trivially bind a local listener in-test (no
# mocking framework needed, no monkeypatching a global HTTP function), so this spins one up for
# real rather than faking the transport layer. Each received request is appended as one JSON line
# to a temp file the test process can read back and assert against; responds 401 for
# /unauthorized, 202 otherwise, matching the PHP fixture's own convention.
sub start {
    my ($class) = @_;

    my (undef, $log_path) = tempfile(SUFFIX => '.jsonl', UNLINK => 0);

    # HTTP::Server::PSGI only actually binds its socket inside run(), and the child process
    # (which calls run()) and the parent (which needs to know the port up front to build request
    # URIs) are different processes with no way to hand a dynamically-chosen port back after the
    # fact. So a free port is found and closed here, then handed to both processes explicitly,
    # accepting the small, standard race of something else grabbing it in between.
    my $port = _free_port();
    my $server = HTTP::Server::PSGI->new(host => '127.0.0.1', port => $port, timeout => 5);

    my $pid = fork();
    die "fork failed: $!" unless defined $pid;

    if ($pid == 0) {
        # Child: run the server; never returns.
        my $app = sub {
            my $env = shift;
            open my $fh, '>>', $log_path or die "cannot open $log_path: $!";
            my $body = '';
            if (my $cl = $env->{CONTENT_LENGTH}) {
                read($env->{'psgi.input'}, $body, $cl);
            }
            print $fh encode_json({
                method  => $env->{REQUEST_METHOD},
                path    => $env->{PATH_INFO},
                headers => { map { $_ =~ s/^HTTP_//r => $env->{$_} } grep { /^HTTP_/ } keys %$env },
                body    => $body,
            }), "\n";
            close $fh;

            my $status = $env->{PATH_INFO} eq '/unauthorized' ? 401 : 202;
            return [ $status, [ 'Content-Type' => 'text/plain' ], [''] ];
        };
        $server->run($app);
        exit 0;
    }

    # Parent: wait for the socket to actually accept connections before returning.
    my $deadline = time + 5;
    while (time < $deadline) {
        my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Timeout => 1);
        if ($sock) {
            close $sock;
            last;
        }
        select(undef, undef, undef, 0.05);
    }

    return bless { pid => $pid, port => $port, log_path => $log_path }, $class;
}

sub uri { my ($self) = @_; return "http://127.0.0.1:$self->{port}"; }

sub requests {
    my ($self) = @_;
    open my $fh, '<', $self->{log_path} or return [];
    my @requests;
    while (my $line = <$fh>) {
        chomp $line;
        next unless length $line;
        require JSON::PP;
        push @requests, JSON::PP::decode_json($line);
    }
    close $fh;
    return \@requests;
}

sub stop {
    my ($self) = @_;
    return unless $self->{pid};
    kill 'TERM', $self->{pid};
    # Confirmed directly: without localizing $?, the test process's own final exit code picks up
    # the killed child's wait status (128+SIGTERM) here, since nothing else in the test script
    # ever calls exit() explicitly: `prove` then reports a passing test file as "Dubious,
    # test returned 15" purely from this bookkeeping leaking out, not from any real failure.
    local $?;
    waitpid($self->{pid}, 0);
    unlink $self->{log_path};
}

sub _free_port {
    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1);
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

1;
