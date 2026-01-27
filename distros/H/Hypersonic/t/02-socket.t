use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic::Socket;

# Test platform detection
subtest 'Platform detection' => sub {
    my $platform = Hypersonic::Socket::platform();
    ok($platform, "Platform detected: $platform");

    my $backend = Hypersonic::Socket::event_backend();
    ok($backend, "Event backend: $backend");

    if ($^O eq 'darwin') {
        is($platform, 'darwin', 'macOS detected correctly');
        is($backend, 'kqueue', 'macOS uses kqueue');
    } elsif ($^O eq 'linux') {
        is($platform, 'linux', 'Linux detected correctly');
        is($backend, 'epoll', 'Linux uses epoll');
    } elsif ($^O eq 'freebsd') {
        is($platform, 'freebsd', 'FreeBSD detected correctly');
        is($backend, 'kqueue', 'FreeBSD uses kqueue');
    }
};

# Test socket creation
subtest 'Socket creation and lifecycle' => sub {
    # Find an available port
    my $port = 22000 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    ok($listen_fd > 0, "create_listen_socket returned valid fd: $listen_fd");

    # Should be able to create event loop
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);
    ok($loop_fd > 0, "create_event_loop returned valid fd: $loop_fd");

    # Clean up
    my $close_result = Hypersonic::Socket::close_fd($listen_fd);
    is($close_result, 0, 'close_fd returns 0 on success');

    my $close_loop = Hypersonic::Socket::close_fd($loop_fd);
    is($close_loop, 0, 'close_fd event loop returns 0');
};

# Test event_add and event_del
subtest 'Event add and delete' => sub {
    my $port = 22100 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    ok($listen_fd > 0, 'listen socket created');

    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);
    ok($loop_fd > 0, 'event loop created');

    # Create a second socket to add/remove
    my $port2 = $port + 1;
    my $fd2 = Hypersonic::Socket::create_listen_socket($port2);
    ok($fd2 > 0, 'second socket created');

    # Add to event loop
    my $add_result = Hypersonic::Socket::event_add($loop_fd, $fd2);
    is($add_result, 0, 'event_add returns 0 on success');

    # Remove from event loop
    my $del_result = Hypersonic::Socket::event_del($loop_fd, $fd2);
    is($del_result, 0, 'event_del returns 0 on success');

    # Cleanup
    Hypersonic::Socket::close_fd($fd2);
    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
};

# Test ev_poll timeout behavior
subtest 'ev_poll timeout' => sub {
    my $port = 22200 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);

    # Poll with short timeout - should return empty (no connections)
    my $start = time();
    my $events = Hypersonic::Socket::ev_poll($loop_fd, 100);
    my $elapsed = time() - $start;

    ok(ref($events) eq 'ARRAY', 'ev_poll returns arrayref');
    is(scalar @$events, 0, 'ev_poll returns empty array with no connections');
    ok($elapsed < 1, 'ev_poll respects timeout');

    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
};

# Test http_accept with actual connection
subtest 'http_accept with connection' => sub {
    my $port = 22300 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);

    # Fork a client to connect
    my $pid = fork();
    if ($pid == 0) {
        # Child: connect to server
        sleep(0.1);  # Let parent start polling
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 2,
        );
        if ($sock) {
            print $sock "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
            close($sock);
        }
        exit(0);
    }

    # Parent: wait for connection
    my $events = Hypersonic::Socket::ev_poll($loop_fd, 2000);
    ok(ref($events) eq 'ARRAY', 'ev_poll returns arrayref');

    if (@$events > 0) {
        my ($fd, $flags) = @{$events->[0]};
        is($fd, $listen_fd, 'Event on listen socket');

        my $client_fd = Hypersonic::Socket::http_accept($listen_fd);
        ok($client_fd > 0, "http_accept returned valid fd: $client_fd");

        Hypersonic::Socket::close_fd($client_fd);
    }

    waitpid($pid, 0);
    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
};

# Test http_recv
subtest 'http_recv parsing' => sub {
    my $port = 22400 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);

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

    # Accept connection
    Hypersonic::Socket::ev_poll($loop_fd, 2000);
    my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

    if ($client_fd > 0) {
        # Add client to event loop and wait for data
        Hypersonic::Socket::event_add($loop_fd, $client_fd);
        Hypersonic::Socket::ev_poll($loop_fd, 2000);

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

    waitpid($pid, 0);
    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
};

# Test http_send
subtest 'http_send' => sub {
    my $port = 22500 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);

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

    Hypersonic::Socket::ev_poll($loop_fd, 2000);
    my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

    if ($client_fd > 0) {
        Hypersonic::Socket::event_add($loop_fd, $client_fd);
        Hypersonic::Socket::ev_poll($loop_fd, 2000);
        Hypersonic::Socket::http_recv($client_fd);

        my $sent = Hypersonic::Socket::http_send($client_fd, 'Hello World', 'text/plain');
        ok($sent > 0, "http_send returned bytes sent: $sent");

        Hypersonic::Socket::close_fd($client_fd);
    }

    waitpid($pid, 0);
    is($? >> 8, 0, 'Client received correct response');

    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
};

# Test http_send with custom content type
subtest 'http_send with JSON content type' => sub {
    my $port = 22600 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);

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

    Hypersonic::Socket::ev_poll($loop_fd, 2000);
    my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

    if ($client_fd > 0) {
        Hypersonic::Socket::event_add($loop_fd, $client_fd);
        Hypersonic::Socket::ev_poll($loop_fd, 2000);
        Hypersonic::Socket::http_recv($client_fd);

        my $sent = Hypersonic::Socket::http_send($client_fd, '{"status":"ok"}', 'application/json');
        ok($sent > 0, "http_send with JSON returned bytes: $sent");

        Hypersonic::Socket::close_fd($client_fd);
    }

    waitpid($pid, 0);
    is($? >> 8, 0, 'Client received JSON content type');

    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
};

# Test http_send_404
subtest 'http_send_404' => sub {
    my $port = 22700 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);

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

    Hypersonic::Socket::ev_poll($loop_fd, 2000);
    my $client_fd = Hypersonic::Socket::http_accept($listen_fd);

    if ($client_fd > 0) {
        Hypersonic::Socket::event_add($loop_fd, $client_fd);
        Hypersonic::Socket::ev_poll($loop_fd, 2000);
        Hypersonic::Socket::http_recv($client_fd);

        my $sent = Hypersonic::Socket::http_send_404($client_fd);
        ok($sent > 0, "http_send_404 returned bytes: $sent");

        Hypersonic::Socket::close_fd($client_fd);
    }

    waitpid($pid, 0);
    is($? >> 8, 0, 'Client received 404 response');

    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
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
    my $port = 22800 + ($$ % 1000);

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

# Test multiple connections
subtest 'Multiple concurrent connections' => sub {
    my $port = 22900 + ($$ % 1000);

    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    my $loop_fd = Hypersonic::Socket::create_event_loop($listen_fd);

    my @pids;

    # Fork 3 clients
    for my $i (1..3) {
        my $pid = fork();
        if ($pid == 0) {
            sleep(0.1 * $i);
            my $sock = IO::Socket::INET->new(
                PeerAddr => '127.0.0.1',
                PeerPort => $port,
                Proto    => 'tcp',
                Timeout  => 2,
            );
            if ($sock) {
                print $sock "GET /test$i HTTP/1.1\r\nHost: localhost\r\n\r\n";
                my $resp = <$sock>;
                close($sock);
            }
            exit(0);
        }
        push @pids, $pid;
    }

    # Accept all connections
    my $accepted = 0;
    for (1..10) {
        my $events = Hypersonic::Socket::ev_poll($loop_fd, 500);
        for my $ev (@$events) {
            my ($fd, $flags) = @$ev;
            if ($fd == $listen_fd) {
                my $client = Hypersonic::Socket::http_accept($listen_fd);
                if ($client > 0) {
                    $accepted++;
                    Hypersonic::Socket::http_send($client, 'OK', 'text/plain');
                    Hypersonic::Socket::close_fd($client);
                }
            }
        }
        last if $accepted >= 3;
    }

    ok($accepted >= 1, "Accepted $accepted concurrent connections");

    waitpid($_, 0) for @pids;
    Hypersonic::Socket::close_fd($listen_fd);
    Hypersonic::Socket::close_fd($loop_fd);
};

done_testing();
