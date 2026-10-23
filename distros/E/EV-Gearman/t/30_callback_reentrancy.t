# Callback reentrancy: connect/disconnect from inside callbacks must
# not corrupt the session. Hermetic — fake Unix-socket servers, no
# gearmand needed.
#
# Covers the disconnect()+connect() parse-guard flip (SIGSEGV) and
# the stray reconnect timer on nested connects.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use IO::Socket::UNIX;
use EV;
use EV::Gearman;

my $dir = tempdir(CLEANUP => 1);

# Fake binary server: answers ECHO_REQ, records connections.
sub binary_server {
    my ($path) = @_;
    unlink $path;
    my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 16)
        or die "bind $path: $!";
    $srv->blocking(0);
    my $st = { srv => $srv, conns => [], nconn => 0 };
    $st->{accept} = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            $st->{nconn}++;
            my $conn = { sock => $c, rbuf => '' };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; return; }
                $conn->{rbuf} .= $chunk;
                while (length($conn->{rbuf}) >= 12) {
                    my (undef, $cmd, $len) =
                        unpack 'a4 N N', substr($conn->{rbuf}, 0, 12);
                    last if length($conn->{rbuf}) < 12 + $len;
                    my $body = substr($conn->{rbuf}, 12, $len);
                    substr($conn->{rbuf}, 0, 12 + $len) = '';
                    if ($cmd == 16) {
                        syswrite $c, "\0RES" . pack('N N', 17, length $body)
                            . $body;
                    }
                }
            };
            push @{$st->{conns}}, $conn;
        }
    };
    $st;
}

# Fake text server: answers one line per command line.
sub text_server {
    my ($path) = @_;
    unlink $path;
    my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 16)
        or die "bind $path: $!";
    $srv->blocking(0);
    my $st = { srv => $srv, conns => [] };
    $st->{accept} = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            my $conn = { sock => $c, rbuf => '' };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; return; }
                $conn->{rbuf} .= $chunk;
                if ($conn->{rbuf} =~ s/^(.*)\n//) {
                    syswrite $c, "OK fake-1.0\n";
                }
            };
            push @{$st->{conns}}, $conn;
        }
    };
    $st;
}

sub run_loop {
    my ($secs) = @_;
    my $t = EV::timer $secs, 0, sub { EV::break };
    EV::run;
}

# 1. disconnect()+connect_unix() inside a binary response callback.
{
    my $path = "$dir/r30b.sock";
    my $srv = binary_server($path);
    my (@errors, $ndisc, $nconn);
    my ($r1, $e1, $r2, $e2);
    my $g;
    my $did;
    my $go = sub {
        return if $did++;
        $g->echo('ping', sub {
            ($r1, $e1) = @_;
            $g->disconnect;
            $g->connect_unix($path);
            $g->echo('ping2', sub { ($r2, $e2) = @_; EV::break });
        });
    };
    $g = EV::Gearman->new(
        path          => $path,
        on_error      => sub { push @errors, $_[0] },
        on_disconnect => sub { $ndisc++ },
        on_connect    => sub { $nconn++; $go->() if $g },
    );
    $go->();
    run_loop(5);
    is $r1, 'ping', 'binary flip: first echo delivered';
    is $e1, undef,  'binary flip: first echo has no error';
    is $nconn, 2,   'binary flip: reconnected exactly once';
    is $ndisc, 1,   'binary flip: on_disconnect fired once';
    is_deeply \@errors, [], 'binary flip: no protocol errors';
    is $r2, 'ping2', 'binary flip: session usable after the flip';
    is $e2, undef,   'binary flip: second echo has no error';
    undef $g;
}

# 2. Same dance inside an admin (text-protocol) callback.
{
    my $path = "$dir/r30a.sock";
    my $srv = text_server($path);
    my (@errors, $ndisc);
    my ($r1, $e1, $r2, $e2);
    my $g;
    my $did;
    my $go = sub {
        return if $did++;
        $g->admin('version', sub {
            ($r1, $e1) = @_;
            $g->disconnect;
            $g->connect_unix($path);
            $g->admin('version', sub { ($r2, $e2) = @_; EV::break });
        });
    };
    $g = EV::Gearman->new(
        path          => $path,
        on_error      => sub { push @errors, $_[0] },
        on_disconnect => sub { $ndisc++ },
        on_connect    => sub { $go->() if $g },
    );
    $go->();
    run_loop(5);
    is $r1, 'OK fake-1.0', 'admin flip: first reply delivered';
    is $e1, undef,         'admin flip: first reply has no error';
    is $ndisc, 1,          'admin flip: on_disconnect fired once';
    is_deeply \@errors, [], 'admin flip: no protocol errors';
    is $r2, 'OK fake-1.0', 'admin flip: session usable after the flip';
    undef $g;
}

# 3. Manual connect() from a cancel-phase callback with reconnect=>1:
# the outer disconnect must not arm its timer onto the live session.
{
    my $path = "$dir/r30c.sock";
    unlink $path;
    my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 16)
        or die "bind: $!";
    $srv->blocking(0);
    my ($nconn, @conns);
    my $accept = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            $nconn++;
            if ($nconn == 1) {
                my $t; $t = EV::timer 0.05, 0, sub {
                    close $c; undef $t;
                };
                next;
            }
            my $conn = { sock => $c, rbuf => '' };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; return; }
                $conn->{rbuf} .= $chunk;
                while (length($conn->{rbuf}) >= 12) {
                    my (undef, $cmd, $len) =
                        unpack 'a4 N N', substr($conn->{rbuf}, 0, 12);
                    last if length($conn->{rbuf}) < 12 + $len;
                    my $body = substr($conn->{rbuf}, 12, $len);
                    substr($conn->{rbuf}, 0, 12 + $len) = '';
                    if ($cmd == 16) {
                        syswrite $c, "\0RES" . pack('N N', 17, length $body)
                            . $body;
                    }
                }
            };
            push @conns, $conn;
        }
    };

    my ($nconnect, $did_manual, $did_echo1);
    my ($e1, $r2, $e2, $r3, $e3);
    my $g;
    my $submit1 = sub {
        return if $did_echo1++;
        $g->echo('one', sub {
            (undef, $e1) = @_;
            if (!$did_manual++ && defined $e1) {
                $g->connect_unix($path);
            }
        });
    };
    $g = EV::Gearman->new(
        path            => $path,
        reconnect       => 1,
        reconnect_delay => 100,
        on_error        => sub {},
        on_disconnect   => sub {},
        on_connect      => sub {
            $nconnect++;
            return unless $g;
            $submit1->() if $nconnect == 1;
            if ($nconnect == 2) {
                $g->echo('two', sub {
                    ($r2, $e2) = @_;
                    $g->echo('three', sub {
                        ($r3, $e3) = @_;
                        my $t; $t = EV::timer 0.4, 0, sub {
                            undef $t; EV::break;
                        };
                    });
                });
            }
        },
    );
    $submit1->();
    run_loop(5);
    is $e1, 'disconnected', 'cancel-phase connect: drop reported';
    is $nconnect, 2, 'cancel-phase connect: no stray reconnect fire';
    is $r2, 'two',   'cancel-phase connect: fresh work not cancelled';
    is $e2, undef,   'cancel-phase connect: fresh work has no error';
    is $r3, 'three', 'cancel-phase connect: session not wedged';
    undef $g;
}

# 4. Manual connect() fallback from on_error on connect failure
# ("try next host") with reconnect=>1: same stray-timer class.
{
    my $path = "$dir/r30d.sock";
    my $srv = binary_server($path);
    # A recently-closed TCP port fails async (EINPROGRESS, then the
    # error), so $g is assigned by the time on_error fires — a unix
    # connect to a missing path fails synchronously inside new().
    my $rsrv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        ReuseAddr => 1,
    ) or die "bind: $!";
    my $refused = $rsrv->sockport;
    close $rsrv;

    my ($nconnect, $did_fallback, $r, $e);
    my $g;
    $g = EV::Gearman->new(
        host            => '127.0.0.1',
        port            => $refused,
        reconnect       => 1,
        reconnect_delay => 100,
        on_connect      => sub { $nconnect++ },
        on_disconnect   => sub {},
        on_error        => sub {
            if (!$did_fallback++ && $_[0] =~ /^connect failed/) {
                $g->connect_unix($path);
            }
        },
    );
    my $t1 = EV::timer 0.6, 0, sub {
        $g->echo('ping', sub { ($r, $e) = @_; EV::break });
    };
    run_loop(5);
    is $nconnect, 1, 'on_error fallback: exactly one connect';
    is $srv->{nconn}, 1, 'on_error fallback: exactly one server conn';
    is $r, 'ping', 'on_error fallback: session usable';
    is $e, undef,  'on_error fallback: no error';
    undef $g;
}

# 5. Counters stay consistent when a cancel-phase callback reconnects,
# submits, and disconnects again mid-drain.
{
    my $path = "$dir/r30e.sock";
    unlink $path;
    my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 16)
        or die "bind: $!";
    $srv->blocking(0);
    my $nconn = 0;
    my @conns;
    # Never answer; hang up the first connection to force a
    # cancel-phase drain while the echo is in flight.
    my $accept = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            $nconn++;
            if ($nconn == 1) {
                my $t; $t = EV::timer 0.05, 0, sub {
                    close $c; undef $t;
                };
                next;
            }
            my $conn = { sock => $c };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; }
            };
            push @conns, $conn;
        }
    };
    my $g;
    my ($e1, $e2, @seen);
    my $did;
    my $go = sub {
        return if $did++;
        $g->echo('one', sub {
            (undef, $e1) = @_;
            push @seen, [$g->pending_count, $g->waiting_count,
                         $g->active_count];
            $g->connect_unix($path);
            $g->echo('two', sub {
                (undef, $e2) = @_;
                push @seen, [$g->pending_count, $g->waiting_count,
                             $g->active_count];
            });
            $g->disconnect;
            push @seen, [$g->pending_count, $g->waiting_count,
                         $g->active_count];
            my $t; $t = EV::timer 0.3, 0, sub { undef $t; EV::break };
        });
    };
    $g = EV::Gearman->new(
        path          => $path,
        on_error      => sub {},
        on_disconnect => sub {},
        on_connect    => sub { $go->() if $g },
    );
    $go->();
    run_loop(5);
    is $e1, 'disconnected', 'counter drain: outer cancel reported';
    is $e2, 'disconnected', 'counter drain: nested submit cancelled';
    my $neg = grep { $_->[0] < 0 || $_->[1] < 0 || $_->[2] < 0 } @seen;
    is $neg, 0, 'counter drain: never negative mid-drain';
    is $g->pending_count, 0, 'counter drain: pending settles at 0';
    is $g->waiting_count, 0, 'counter drain: waiting settles at 0';
    is $g->active_count, 0, 'counter drain: active settles at 0';
    undef $g;
}

# Fake TCP echo server. $hang_first drops connection #1 (to force a
# cancel-phase drain); every client ECHO body is pushed onto @$seen.
sub tcp_echo_server {
    my ($hang_first, $seen) = @_;
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 16,
        ReuseAddr => 1,
    ) or die "bind: $!";
    $srv->blocking(0);
    my $st = { srv => $srv, port => $srv->sockport, conns => [],
               nconn => 0 };
    $st->{accept} = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            $st->{nconn}++;
            if ($hang_first && $st->{nconn} == 1) {
                my $t; $t = EV::timer 0.05, 0, sub {
                    close $c; undef $t;
                };
                next;
            }
            my $conn = { sock => $c, rbuf => '' };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; return; }
                $conn->{rbuf} .= $chunk;
                while (length($conn->{rbuf}) >= 12) {
                    my (undef, $cmd, $len) =
                        unpack 'a4 N N', substr($conn->{rbuf}, 0, 12);
                    last if length($conn->{rbuf}) < 12 + $len;
                    my $body = substr($conn->{rbuf}, 12, $len);
                    substr($conn->{rbuf}, 0, 12 + $len) = '';
                    push @$seen, $body if $cmd == 16;
                    if ($cmd == 16) {
                        syswrite $c, "\0RES" . pack('N N', 17, length $body)
                            . $body;
                    }
                }
            };
            push @{$st->{conns}}, $conn;
        }
    };
    $st;
}

# 6. Retry queued while a nested connect is still in flight must
# survive the outer teardown (unix connects complete inline and
# mask this; TCP does not).
{
    my @seen;
    my $srv = tcp_echo_server(1, \@seen);
    my ($nconnect, $e1, $r2, $e2);
    my $g;
    my $did;
    $g = EV::Gearman->new(
        host            => '127.0.0.1',
        port            => $srv->{port},
        reconnect       => 1,
        reconnect_delay => 100,
        on_error        => sub {},
        on_disconnect   => sub {},
        on_connect      => sub {
            $nconnect++;
            return unless $g && $nconnect == 1 && !$did++;
            $g->echo('one', sub {
                (undef, $e1) = @_;
                $g->connect('127.0.0.1', $srv->{port});
                $g->echo('two', sub {
                    ($r2, $e2) = @_;
                    my $t; $t = EV::timer 0.4, 0, sub {
                        undef $t; EV::break;
                    };
                });
            });
        },
    );
    run_loop(5);
    is $e1, 'disconnected', 'async retry: drop reported';
    is $r2, 'two', 'async retry: queued retry survives teardown';
    is $e2, undef, 'async retry: no error';
    is_deeply \@seen, ['two'], 'async retry: retry reached the server';
    undef $g;
}

# 7. Same via the idle-disconnect path: queue work while
# disconnected, disconnect(), and resubmit on a nested connect from
# the cancel callback.
{
    my @seen;
    my $srv = tcp_echo_server(0, \@seen);
    my $rsrv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        ReuseAddr => 1,
    ) or die "bind: $!";
    my $dead = $rsrv->sockport;
    close $rsrv;

    my ($e1, $r2, $e2, $phase);
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $dead,
        reconnect => 1, reconnect_delay => 5000,
        on_error => sub {}, on_disconnect => sub {},
    );
    my $t0 = EV::timer 0.2, 0, sub {
        $phase = 'queue';
        $g->echo('one', sub {
            (undef, $e1) = @_;
            return unless $phase eq 'queue';
            $phase = 'retry';
            $g->connect('127.0.0.1', $srv->{port});
            $g->echo('two', sub {
                ($r2, $e2) = @_;
                my $t; $t = EV::timer 0.4, 0, sub {
                    undef $t; EV::break;
                };
            });
        });
        $g->disconnect;
    };
    run_loop(8);
    is $e1, 'disconnected', 'idle retry: queued work cancelled';
    is $r2, 'two', 'idle retry: nested resubmit survives';
    is $e2, undef, 'idle retry: no error';
    is_deeply \@seen, ['two'], 'idle retry: resubmit reached the server';
    undef $g;
}

done_testing;
