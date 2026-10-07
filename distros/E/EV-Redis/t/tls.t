use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Test::TCP;
use POSIX ();
use IO::Socket::INET;
use IO::Select;
use Socket ();
use Time::HiRes ();

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

ok(defined EV::Redis->has_ssl, 'has_ssl method exists');

unless (EV::Redis->has_ssl) {
    BAIL_OUT('TLS coverage is required but TLS support was not compiled')
        if $ENV{EV_REDIS_REQUIRE_TLS_TESTS};
    eval {
        EV::Redis->new(
            host => 'localhost',
            tls  => 1,
        );
    };
    like($@, qr/TLS support not compiled/, 'tls => 1 without SSL support gives helpful error');

    done_testing;
    exit;
}

diag "TLS support is enabled";

is(EV::Redis->has_ssl, 1, 'has_ssl returns 1 when compiled with TLS');

{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context('/nonexistent/ca.crt', undef, undef, undef, undef);
    };
    like($@, qr/SSL context creation failed/, 'invalid CA cert path croaks');
}

{
    eval {
        EV::Redis->new(
            path => '/tmp/redis.sock',
            tls  => 1,
        );
    };
    like($@, qr/TLS requires 'host'/, 'tls with path croaks');
}

{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context(undef, undef, undef, undef, undef);
    };
    is($@, '', 'SSL context with system defaults succeeds');
}

# OpenSSL accepts even a nonexistent CApath, so only check it doesn't croak
{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context(undef, '/tmp', undef, undef, undef);
    };
    is($@, '', 'SSL context with tls_capath directory succeeds');
}

{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context(undef, undef, '/tmp/cert.pem', undef, undef);
    };
    like($@, qr/SSL context creation failed/, 'cert without key croaks');
}

# a server that never answers the handshake: commands issued meanwhile are
# writes parked until a read, not progress
{
    my $lsn = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    my @held;
    my $accept = EV::io $lsn, EV::READ, sub { push @held, scalar $lsn->accept };
    my @err;
    my $r = EV::Redis->new(
        host => '127.0.0.1', port => $lsn->sockport, tls => 1, tls_verify => 0,
        command_timeout => 300,
        on_error => sub { push @err, $_[0]; EV::break },
    );
    # timers count from the loop's clock, last read before the slow setup
    EV::now_update;
    my $tick = EV::timer 0.05, 0.1, sub { $r->ping(sub {}) if $r->is_connected };
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is($err[0], 'Timeout', 'commands during a stalled TLS handshake do not extend command_timeout');
    $r->disconnect if $r->is_connected;
}

my $can_test_connection = sub {
    system("openssl version >/dev/null 2>&1") == 0
        or return 0;

    my $version = `redis-server --version 2>/dev/null`
        or return 0;

    if ($version =~ /v=(\d+)\.(\d+)/) {
        return 0 if $1 < 6;
    } else {
        return 0;
    }

    return 1;
}->();

unless ($can_test_connection) {
    BAIL_OUT('TLS connection tests require openssl and Redis >= 6.0')
        if $ENV{EV_REDIS_REQUIRE_TLS_TESTS};
    diag "Skipping TLS connection tests (need openssl + Redis >= 6.0 with TLS)";
    done_testing;
    exit;
}

diag "Running TLS connection tests";

my $certdir = tempdir(CLEANUP => 1);
my $ca_key    = "$certdir/ca.key";
my $ca_cert   = "$certdir/ca.crt";
my $srv_key   = "$certdir/server.key";
my $srv_cert  = "$certdir/server.crt";
my $srv_csr   = "$certdir/server.csr";

unless (system("openssl genrsa -out $ca_key 2048 2>/dev/null") == 0 &&
        system("openssl req -new -x509 -key $ca_key -out $ca_cert -days 1 -subj '/CN=Test CA' 2>/dev/null") == 0) {
    BAIL_OUT('Failed to generate the required TLS test certificates')
        if $ENV{EV_REDIS_REQUIRE_TLS_TESTS};
    diag "Failed to generate CA cert, skipping TLS connection tests";
    done_testing;
    exit;
}

system("openssl genrsa -out $srv_key 2048 2>/dev/null") == 0
    or die "Failed to generate server key";
system("openssl req -new -key $srv_key -out $srv_csr -subj '/CN=127.0.0.1' 2>/dev/null") == 0
    or die "Failed to generate server CSR";
system("openssl x509 -req -in $srv_csr -CA $ca_cert -CAkey $ca_key -CAcreateserial -out $srv_cert -days 1 2>/dev/null") == 0
    or die "Failed to sign server cert";

my $tls_port = empty_port();

my $redis_pid;
eval {
    $redis_pid = fork();
    die "fork failed: $!" unless defined $redis_pid;
    if ($redis_pid == 0) {
        open STDOUT, '>/dev/null';
        open STDERR, '>/dev/null';
        exec('redis-server',
            '--port', '0',
            '--tls-port', $tls_port,
            '--tls-cert-file', $srv_cert,
            '--tls-key-file', $srv_key,
            '--tls-ca-cert-file', $ca_cert,
            '--tls-auth-clients', 'no',
            '--bind', '127.0.0.1',
            '--loglevel', 'warning',
            '--save', '',
        );
        die "exec redis-server failed: $!";
    }
};
if ($@ || !$redis_pid) {
    BAIL_OUT("Failed to start the required TLS Redis: $@")
        if $ENV{EV_REDIS_REQUIRE_TLS_TESTS};
    diag "Failed to start TLS Redis: $@";
    done_testing;
    exit;
}

my $ready = 0;
for (1..50) {
    my $kid = waitpid($redis_pid, POSIX::WNOHANG());
    if ($kid > 0) {
        $redis_pid = undef;
        last;
    }
    if (system("redis-cli -h 127.0.0.1 -p $tls_port --tls --insecure PING >/dev/null 2>&1") == 0) {
        $ready = 1;
        last;
    }
    select(undef, undef, undef, 0.1);
}

unless ($ready) {
    if ($redis_pid) {
        kill 'TERM', $redis_pid;
        waitpid($redis_pid, 0);
        $redis_pid = undef;
    }
    diag "Redis TLS server failed to start (TLS may not be compiled in)";
    BAIL_OUT('The required Redis TLS server failed to start')
        if $ENV{EV_REDIS_REQUIRE_TLS_TESTS};
    done_testing;
    exit;
}

END {
    if ($redis_pid) {
        kill 'TERM', $redis_pid;
        waitpid($redis_pid, 0);
    }
}

{
    my ($connected, $error, $result) = (0, 0, undef);
    my $r = EV::Redis->new(
        host   => '127.0.0.1',
        port   => $tls_port,
        tls    => 1,
        tls_ca => $ca_cert,
    );
    $r->on_error(sub { $error++; $r->disconnect });
    $r->on_connect(sub {
        $connected++;
        $r->ping(sub {
            my ($res, $err) = @_;
            $result = $res;
            $r->disconnect;
        });
    });
    EV::run;

    is($connected, 1, 'TLS connection established');
    is($error, 0, 'no connection error');
    is($result, 'PONG', 'PING over TLS returns PONG');
}

{
    my ($get_result, $error) = (undef, 0);
    my $r = EV::Redis->new(
        host   => '127.0.0.1',
        port   => $tls_port,
        tls    => 1,
        tls_ca => $ca_cert,
    );
    $r->on_error(sub { $error++; $r->disconnect });
    $r->on_connect(sub {
        $r->set('tls_test_key', 'tls_test_value', sub {
            $r->get('tls_test_key', sub {
                my ($res, $err) = @_;
                $get_result = $res;
                $r->disconnect;
            });
        });
    });
    EV::run;

    is($error, 0, 'no error during SET/GET over TLS');
    is($get_result, 'tls_test_value', 'GET over TLS returns correct value');
}

# LibreSSL rejects an IP as SNI (RFC 6066)
# on_error goes in the constructor: the SSL failure fires inside connect()
{
    my ($connected, $error, $error_msg) = (0, 0, '');
    my $r;
    $r = EV::Redis->new(
        host            => '127.0.0.1',
        port            => $tls_port,
        tls             => 1,
        tls_ca          => $ca_cert,
        tls_server_name => '127.0.0.1',
        on_error   => sub { $error++; $error_msg = $_[0]; $r->disconnect if $r && $r->is_connected },
        on_connect => sub { $connected++; $r->disconnect },
    );
    EV::run;

    if ($error && $error_msg =~ /SNI/) {
        pass('TLS SNI with IP rejected by SSL library (expected on LibreSSL)');
        pass('(SNI IP test skipped)');
    } else {
        is($connected, 1, 'TLS connection with SNI succeeds');
        is($error, 0, 'no error with SNI');
    }
}

{
    my ($connected, $error) = (0, 0);
    my $r = EV::Redis->new(
        host       => '127.0.0.1',
        port       => $tls_port,
        tls        => 1,
        tls_verify => 0,
    );
    $r->on_error(sub { $error++; $r->disconnect });
    $r->on_connect(sub {
        $connected++;
        $r->disconnect;
    });
    EV::run;

    is($connected, 1, 'TLS with tls_verify => 0 connects without CA');
    is($error, 0, 'no error with tls_verify => 0');
}

{
    # OpenSSL CApath lookups need hash-named symlinks
    my $cadir = tempdir(CLEANUP => 1);
    my $hash = `openssl x509 -hash -noout -in $ca_cert 2>/dev/null`;
    chomp $hash;
    symlink($ca_cert, "$cadir/$hash.0") if $hash;

    SKIP: {
        skip 'could not create CA hash symlink', 2 unless $hash && -l "$cadir/$hash.0";

        my ($connected, $error) = (0, 0);
        my $r = EV::Redis->new(
            host       => '127.0.0.1',
            port       => $tls_port,
            tls        => 1,
            tls_capath => $cadir,
        );
        $r->on_error(sub { $error++; $r->disconnect });
        $r->on_connect(sub { $connected++; $r->disconnect });
        EV::run;

        is($connected, 1, 'TLS connection with tls_capath succeeds');
        is($error, 0, 'no error with tls_capath');
    }
}

{
    eval {
        EV::Redis->new(
            host   => '127.0.0.1',
            port   => $tls_port,
            tls    => 1,
            tls_ca => '/nonexistent/ca.crt',
        );
    };
    like($@, qr/SSL context creation failed/, 'TLS with invalid CA croaks');
}

{
    my ($connected, $disconnected, $error, $reconnected) = (0, 0, 0, 0);
    my $r = EV::Redis->new(
        host      => '127.0.0.1',
        port      => $tls_port,
        tls       => 1,
        tls_ca    => $ca_cert,
        reconnect => 1,
        reconnect_delay => 200,
        max_reconnect_attempts => 3,
    );
    $r->on_error(sub { $error++ });
    $r->on_connect(sub {
        if ($connected == 0) {
            $connected++;
            $r->command('CLIENT', 'ID', sub {
                my ($id, $err) = @_;
                if ($err) {
                    $r->disconnect;
                    return;
                }
                my $r2 = EV::Redis->new(
                    host   => '127.0.0.1',
                    port   => $tls_port,
                    tls    => 1,
                    tls_ca => $ca_cert,
                );
                $r2->on_error(sub { });
                $r2->on_connect(sub {
                    $r2->command('CLIENT', 'KILL', 'ID', $id, sub {
                        $r2->disconnect;
                    });
                });
            });
        }
        else {
            $reconnected++;
            $r->disconnect;
        }
    });
    $r->on_disconnect(sub { $disconnected++ });

    my $timer; $timer = EV::timer 5, 0, sub {
        undef $timer;
        $r->disconnect;
    };
    EV::run;

    is($connected, 1, 'TLS initial connection established');
    is($reconnected, 1, 'TLS reconnection succeeded');
    ok($disconnected >= 2, 'TLS disconnect callbacks fired');
}

my ($other_key, $other_ca) = ("$certdir/other.key", "$certdir/other.crt");
my $have_other_ca = system("openssl req -new -x509 -newkey rsa:2048 -nodes -keyout $other_key"
                         . " -out $other_ca -days 1 -subj '/CN=Other CA' 2>/dev/null") == 0;
EV::now_update;

# a certificate from a CA the client does not trust
SKIP: {
    skip 'could not create a second CA', 2 unless $have_other_ca;
    my (@err, $cb_err, @later);
    my $r = EV::Redis->new(
        host => '127.0.0.1', port => $tls_port, tls => 1, tls_ca => $other_ca,
        on_error => sub { push @err, $_[0]; EV::break },
    );
    # the handshake may fail inside new(): then there is nothing to queue on
    my $queued = eval {
        $r->ping(sub {
            $cb_err = $_[1];
            # on_error comes next: another TLS connection must not change its reason
            push @later, EV::Redis->new(
                host => '127.0.0.1', port => $tls_port, tls => 1, tls_ca => $ca_cert,
                on_error => sub {},
            );
        });
        1;
    };
    unless (@err) { my $g = EV::timer 5, 0, sub { EV::break }; EV::run }
    like($err[0] // '', qr/verif/i, 'untrusted server certificate: on_error names the TLS failure');
    SKIP: {
        skip 'the handshake failed inside new()', 1 unless $queued;
        like($cb_err // '', qr/verif/i, 'untrusted server certificate: so does the pending command');
    }
    $_->disconnect for grep { $_->is_connected } $r, @later;
}

# one relay process per connection: a stalled one must not hold up the next
sub throttling_proxy {
    my ($lsn, $port) = @_;
    $SIG{CHLD} = 'IGNORE';
    while (my $c = $lsn->accept) {
        my $pid = fork;
        if (defined $pid && !$pid) {
            eval { throttled_relay($c, $port) };
            POSIX::_exit(0);
        }
        close $c;
    }
}

# A fixed rate whatever the platform's sleep granularity, handed to the server
# in small pieces so that its own receive window stays open.
my $relay_rate = 16 * 1024 * 1024;

sub throttled_relay {
    my ($c, $port) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port) or return;
    $_->blocking(0) for $c, $s;
    my $sel = IO::Select->new($s);
    my ($allowed, $last) = (0, Time::HiRes::time());
    while (1) {
        my $now = Time::HiRes::time();
        $allowed += ($now - $last) * $relay_rate;
        $allowed = 262144 if $allowed > 262144;
        $last = $now;
        while ($allowed >= 1) {
            my $n = sysread $c, my $buf, $allowed > 32768 ? 32768 : int $allowed;
            return if defined $n ? !$n : !($!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR});
            last unless $n;
            $allowed -= $n;
            $s->blocking(1);
            for (my $off = 0; $off < $n; ) {
                $off += syswrite($s, $buf, $n - $off, $off) // return;
            }
            $s->blocking(0);
        }
        # less than a TLS record per round: the client reads partial records
        if ($sel->can_read(0)) {
            my $m = sysread $s, my $down, 8192;
            return if defined $m && !$m;
            if ($m) {
                $c->blocking(1);
                syswrite $c, $down;
                $c->blocking(0);
            }
        }
        select undef, undef, undef, 0.001;
    }
}

my $proxy_pid;
END {
    if ($proxy_pid) {
        kill 'TERM', -$proxy_pid, $proxy_pid;
        waitpid($proxy_pid, 0);
    }
}

# Loopback TCP can itself stall for seconds once a receiver's window has
# closed, so an upload gets a few attempts, each on a fresh connection.
sub tls_upload_ok {
    my ($port, $size, %opt) = @_;
    for my $attempt (1 .. 3) {
        my ($res, $err, @conn_err);
        my $r = EV::Redis->new(
            host => '127.0.0.1', port => $port, tls => 1, tls_ca => $ca_cert,
            on_error   => sub { push @conn_err, $_[0]; EV::break },
            on_connect => sub { EV::break },
        );
        { my $g = EV::timer 5, 0, sub { EV::break }; EV::run }
        if ($r->is_connected) {
            $opt{prepare}->($r);
            $r->set('tls_big', 'x' x $size, sub { ($res, $err) = @_; EV::break });
            { my $g = EV::timer 10, 0, sub { EV::break }; EV::run }
        }
        $r->disconnect if $r->is_connected;
        return 1 if defined $res && 'OK' eq $res;
        diag "attempt $attempt: ", $err // 'no reply', " [@conn_err]";
    }
    return 0;
}

sub tls_ping {
    my ($r) = @_;
    $r->ping(sub { EV::break });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
}

# A link slow enough for writes to block. TLS hands OpenSSL the whole command
# at once, so its output buffer does not shrink while the bytes go out.
SKIP: {
    my $lsn = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0)
        or skip "listen: $!", 3;
    # small in-flight buffer: the client sees the slow drain as slow writes
    $lsn->sockopt(Socket::SO_RCVBUF(), 65536);
    my $proxy_port = $lsn->sockport;
    $proxy_pid = fork;
    skip "fork: $!", 3 unless defined $proxy_pid;
    if (!$proxy_pid) {
        eval { setpgrp 0, 0 };
        eval { throttling_proxy($lsn, $tls_port) };
        POSIX::_exit(0);
    }
    eval { setpgrp $proxy_pid, $proxy_pid };
    close $lsn;
    # a signal to our process group no longer reaches the proxy: let END stop it
    local $SIG{INT} = local $SIG{TERM} = sub { exit 1 };

    # the handshake's last read finds no data, which must not park the write
    ok(tls_upload_ok($proxy_port, 8 * 1024 * 1024, prepare => sub {
        my $g = EV::timer 0.5, 0, sub { EV::break };
        EV::run;
    }), 'TLS: a large first command on an idle connection is sent');

    # two seconds on the wire; the timeout still has to cover what the kernel
    # holds after the last write, a few megabytes at the relay's rate
    ok(tls_upload_ok($proxy_port, 2 * $relay_rate, prepare => sub {
        tls_ping($_[0]);
        $_[0]->command_timeout(1000);
    }), 'TLS: a large command going out slowly does not time out');

    # a failed handshake leaves its error in OpenSSL's queue
    SKIP: {
        skip 'could not create a second CA', 1 unless $have_other_ca;
        ok(tls_upload_ok($proxy_port, 8 * 1024 * 1024, prepare => sub {
            tls_ping($_[0]);
            my @bad_err;
            my $bad = EV::Redis->new(
                host => '127.0.0.1', port => $tls_port, tls => 1, tls_ca => $other_ca,
                on_error => sub { push @bad_err, $_[0]; EV::break },
            );
            unless (@bad_err) { my $g = EV::timer 5, 0, sub { EV::break }; EV::run }
        }), "TLS: another connection's failed handshake does not break this one");
    }

    # ... nor its reads: a subscriber writes nothing before the message comes
    SKIP: {
        skip 'could not create a second CA', 1 unless $have_other_ca;
        my $size = 200 * 1024;
        my $file = "$certdir/message";
        { open my $fh, '>', $file or die "$file: $!"; print $fh 'x' x $size }
        my ($got, @conn_err, @bad_err);
        my $sub = EV::Redis->new(
            host => '127.0.0.1', port => $proxy_port, tls => 1, tls_ca => $ca_cert,
            on_error => sub { push @conn_err, $_[0]; EV::break },
        );
        $sub->subscribe('tls_channel', sub {
            $got = length $_[0][2] if $_[0] && 'message' eq $_[0][0];
            EV::break;
        });
        { my $g = EV::timer 5, 0, sub { EV::break }; EV::run }
        my $bad = EV::Redis->new(
            host => '127.0.0.1', port => $tls_port, tls => 1, tls_ca => $other_ca,
            on_error => sub { push @bad_err, $_[0]; EV::break },
        );
        unless (@bad_err) { my $g = EV::timer 5, 0, sub { EV::break }; EV::run }
        # in the background: the pieces must arrive while the loop is reading
        system("redis-cli -h 127.0.0.1 -p $tls_port --tls --insecure -x publish tls_channel"
             . " < $file >/dev/null 2>&1 &");
        { my $g = EV::timer 10, 0, sub { EV::break }; EV::run }
        cmp_ok($got // 0, '>=', $size, 'TLS: a subscriber reads a large message after that failure')
            or diag "@conn_err";
        $sub->on_error(sub {});
        $sub->disconnect if $sub->is_connected;
    }

    kill 'TERM', -$proxy_pid, $proxy_pid;
    waitpid($proxy_pid, 0);
    $proxy_pid = undef;
}

done_testing;
