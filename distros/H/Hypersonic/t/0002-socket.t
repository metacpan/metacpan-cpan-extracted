use strict;
use warnings;
use Test::More;
use IO::Socket::INET;


use Hypersonic::Socket;

# Find a free TCP port by binding ephemerally.
#
# Pre-0.19 every subtest hard-coded `<base> + ($$ % 1000)` which
# collides whenever two CPAN tester runs of the same perl get
# matching PIDs in the same minute (which happens regularly on the
# cpansmoker-1023 host; see Hypersonic 0.18 reports for perl 5.20.0
# and 5.22.2: `bind(port=23789) failed: Address already in use` and
# `bind(port=22803) failed: Address already in use`). Asking the
# kernel to pick the port via bind(0) and then closing the probe
# socket is the standard "find me an unused TCP port" idiom and
# avoids the collision entirely. TIME_WAIT can still racily re-use
# the port, but in practice the window between close() here and the
# Hypersonic::Socket::create_listen_socket call below is small
# enough that this is essentially free.
sub find_free_port {
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Cannot find free port: $!";
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

# Test platform detection
subtest 'Platform detection' => sub {
    my $platform = Hypersonic::Socket::platform();
    ok($platform, "Platform detected: $platform");

    if ($^O eq 'darwin') {
        is($platform, 'darwin', 'macOS detected correctly');
    } elsif ($^O eq 'linux') {
        is($platform, 'linux', 'Linux detected correctly');
    } elsif ($^O eq 'freebsd') {
        is($platform, 'freebsd', 'FreeBSD detected correctly');
    }
};

# Test socket creation
subtest 'Socket creation and lifecycle' => sub {
    # Find an available port
    my $port = find_free_port();

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    ok($listen_fd > 0, "create_listen_socket returned valid fd: $listen_fd");

    # Clean up
    my $close_result = Hypersonic::Socket::close_fd($listen_fd);
    is($close_result, 0, 'close_fd returns 0 on success');
};

# Test http_accept with actual connection
subtest 'http_accept with connection' => sub {
    my $port = find_free_port();

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    ok($listen_fd > 0, 'listen socket created');

    # Fork a client to connect
    my $pid = fork();
    if ($pid == 0) {
        # Child: connect to server
        sleep(0.1);  # Let parent start accepting
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 2,
        );
        if ($sock) {
            print $sock "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
            my $resp = <$sock>;
            close($sock);
        }
        exit(0);
    }

    # Parent: accept connection directly (blocking)
    # Use select() for simple timeout
    my $rin = '';
    vec($rin, $listen_fd, 1) = 1;
    my $ready = select($rin, undef, undef, 2);

    if ($ready > 0) {
        my $client_fd = Hypersonic::Socket::http_accept($listen_fd);
        ok($client_fd > 0, "http_accept returned valid fd: $client_fd");
        Hypersonic::Socket::http_send($client_fd, 'OK', 'text/plain');
        Hypersonic::Socket::close_fd($client_fd);
    } else {
        fail('Timeout waiting for connection');
    }

    waitpid($pid, 0);
    Hypersonic::Socket::close_fd($listen_fd);
};

# Test http_recv
subtest 'http_recv parsing' => sub {
    my $port = find_free_port();

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);

    my $pid = fork();
    if ($pid == 0) {
        sleep(0.1);
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 2,
        );
        if ($sock) {
            print $sock "POST /api/data HTTP/1.1\r\nHost: localhost\r\nContent-Length: 13\r\nConnection: close\r\n\r\n{\"key\":\"val\"}";
            my $resp = <$sock>;  # Wait for response
            close($sock);
        }
        exit(0);
    }

    # Accept connection using select for timeout
    my $rin = '';
    vec($rin, $listen_fd, 1) = 1;
    my $ready = select($rin, undef, undef, 2);

    if ($ready > 0) {
        my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

        if ($client_fd > 0) {
            # Wait for data
            my $cin = '';
            vec($cin, $client_fd, 1) = 1;
            select($cin, undef, undef, 2);

            my $req = Hypersonic::Socket::http_recv($client_fd);

            ok(ref($req) eq 'ARRAY', 'http_recv returns arrayref');
            if (ref($req) eq 'ARRAY' && @$req >= 4) {
                is($req->[0], 'POST', 'Method parsed correctly');
                is($req->[1], '/api/data', 'Path parsed correctly');
                like($req->[2], qr/key/, 'Body contains data');
                is($req->[3], 0, 'Connection: close detected');
                is($req->[4], $client_fd, 'FD passed through');
            }

            # Send response to complete connection
            Hypersonic::Socket::http_send($client_fd, 'OK', 'text/plain');
            Hypersonic::Socket::close_fd($client_fd);
        }
    }

    waitpid($pid, 0);
    Hypersonic::Socket::close_fd($listen_fd);
};

# Test http_send
subtest 'http_send' => sub {
    my $port = find_free_port();

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);

    my $response_body;
    my $pid = fork();
    if ($pid == 0) {
        sleep(0.1);
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 2,
        );
        if ($sock) {
            print $sock "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
            local $/;
            my $resp = <$sock>;
            # Check response in parent via exit code
            exit($resp =~ /Hello World/ ? 0 : 1);
        }
        exit(1);
    }

    my $rin = '';
    vec($rin, $listen_fd, 1) = 1;
    my $ready = select($rin, undef, undef, 2);

    if ($ready > 0) {
        my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

        if ($client_fd > 0) {
            my $cin = '';
            vec($cin, $client_fd, 1) = 1;
            select($cin, undef, undef, 2);
            Hypersonic::Socket::http_recv($client_fd);

            my $sent = Hypersonic::Socket::http_send($client_fd, 'Hello World', 'text/plain');
            ok($sent > 0, "http_send returned bytes sent: $sent");

            Hypersonic::Socket::close_fd($client_fd);
        }
    }

    waitpid($pid, 0);
    is($? >> 8, 0, 'Client received correct response');

    Hypersonic::Socket::close_fd($listen_fd);
};

# Test http_send with custom content type
subtest 'http_send with JSON content type' => sub {
    my $port = find_free_port();

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);

    my $pid = fork();
    if ($pid == 0) {
        sleep(0.1);
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 2,
        );
        if ($sock) {
            print $sock "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
            local $/;
            my $resp = <$sock>;
            # Check for JSON content type
            exit($resp =~ /application\/json/ ? 0 : 1);
        }
        exit(1);
    }

    my $rin = '';
    vec($rin, $listen_fd, 1) = 1;
    my $ready = select($rin, undef, undef, 2);

    if ($ready > 0) {
        my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

        if ($client_fd > 0) {
            my $cin = '';
            vec($cin, $client_fd, 1) = 1;
            select($cin, undef, undef, 2);
            Hypersonic::Socket::http_recv($client_fd);

            my $sent = Hypersonic::Socket::http_send($client_fd, '{"status":"ok"}', 'application/json');
            ok($sent > 0, "http_send with JSON returned bytes: $sent");

            Hypersonic::Socket::close_fd($client_fd);
        }
    }

    waitpid($pid, 0);
    is($? >> 8, 0, 'Client received JSON content type');

    Hypersonic::Socket::close_fd($listen_fd);
};

# Test http_send_404
subtest 'http_send_404' => sub {
    my $port = find_free_port();

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);

    my $pid = fork();
    if ($pid == 0) {
        sleep(0.1);
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 2,
        );
        if ($sock) {
            print $sock "GET /nonexistent HTTP/1.1\r\nHost: localhost\r\n\r\n";
            local $/;
            my $resp = <$sock>;
            # Check for 404 status and "Not Found" body
            my $ok = ($resp =~ /404 Not Found/ && $resp =~ /Not Found\s*$/);
            exit($ok ? 0 : 1);
        }
        exit(1);
    }

    my $rin = '';
    vec($rin, $listen_fd, 1) = 1;
    my $ready = select($rin, undef, undef, 2);

    if ($ready > 0) {
        my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

        if ($client_fd > 0) {
            my $cin = '';
            vec($cin, $client_fd, 1) = 1;
            select($cin, undef, undef, 2);
            Hypersonic::Socket::http_recv($client_fd);

            my $sent = Hypersonic::Socket::http_send_404($client_fd);
            ok($sent > 0, "http_send_404 returned bytes: $sent");

            Hypersonic::Socket::close_fd($client_fd);
        }
    }

    waitpid($pid, 0);
    is($? >> 8, 0, 'Client received 404 response');

    Hypersonic::Socket::close_fd($listen_fd);
};

# Test error handling - invalid fd
subtest 'Error handling' => sub {
    # close_fd on invalid fd
    my $result = Hypersonic::Socket::close_fd(-1);
    is($result, -1, 'close_fd on -1 returns error');

    # http_accept on invalid fd
    my $client = Hypersonic::Socket::http_accept(-1);
    is($client, -1, 'http_accept on -1 returns error');

    # http_recv on invalid fd
    my $req = Hypersonic::Socket::http_recv(-1);
    ok(!defined($req), 'http_recv on -1 returns undef');
};

# Test port already in use
subtest 'Port already in use' => sub {
    my $port = find_free_port();

    my $fd1 = Hypersonic::Socket::create_listen_socket($port);
    ok($fd1 > 0, 'First socket created');

    # Second socket on same port should fail (unless SO_REUSEPORT)
    # Note: With SO_REUSEPORT this might actually succeed on Linux
    my $fd2 = Hypersonic::Socket::create_listen_socket($port);

    # Just verify we got valid file descriptors
    ok(defined($fd2), 'Second socket creation returned a value');

    Hypersonic::Socket::close_fd($fd1);
    Hypersonic::Socket::close_fd($fd2) if $fd2 > 0;
};

done_testing();
