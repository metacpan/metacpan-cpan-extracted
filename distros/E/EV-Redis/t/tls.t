use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Test::TCP;
use POSIX ();

use EV;
use EV::Redis;

# has_ssl is always available regardless of build configuration
ok(defined EV::Redis->has_ssl, 'has_ssl method exists');

unless (EV::Redis->has_ssl) {
    # Verify that tls => 1 croaks helpfully when SSL not compiled
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

# Test: has_ssl returns true
is(EV::Redis->has_ssl, 1, 'has_ssl returns 1 when compiled with TLS');

# Test: SSL context creation with invalid cert path croaks
{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context('/nonexistent/ca.crt', undef, undef, undef, undef);
    };
    like($@, qr/SSL context creation failed/, 'invalid CA cert path croaks');
}

# Test: tls with path croaks
{
    eval {
        EV::Redis->new(
            path => '/tmp/redis.sock',
            tls  => 1,
        );
    };
    like($@, qr/TLS requires 'host'/, 'tls with path croaks');
}

# Test: SSL context creation succeeds with no certs (uses system defaults)
{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context(undef, undef, undef, undef, undef);
    };
    is($@, '', 'SSL context with system defaults succeeds');
}

# Test: SSL context creation with tls_capath (directory of CA certs)
# OpenSSL silently accepts nonexistent CApath dirs, so just verify it doesn't croak
{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context(undef, '/tmp', undef, undef, undef);
    };
    is($@, '', 'SSL context with tls_capath directory succeeds');
}

# Test: cert without key croaks
{
    my $r = EV::Redis->new();
    eval {
        $r->_setup_ssl_context(undef, undef, '/tmp/cert.pem', undef, undef);
    };
    like($@, qr/SSL context creation failed/, 'cert without key croaks');
}

# --- TLS connection tests ---
# Requires: openssl CLI, redis-server with TLS support, Redis >= 6.0

my $can_test_connection = sub {
    # Check openssl is available
    system("openssl version >/dev/null 2>&1") == 0
        or return 0;

    # Check redis-server is available
    my $version = `redis-server --version 2>/dev/null`
        or return 0;

    # Check Redis >= 6.0 (TLS support)
    if ($version =~ /v=(\d+)\.(\d+)/) {
        return 0 if $1 < 6;
    } else {
        return 0;
    }

    return 1;
}->();

unless ($can_test_connection) {
    diag "Skipping TLS connection tests (need openssl + Redis >= 6.0 with TLS)";
    done_testing;
    exit;
}

diag "Running TLS connection tests";

# Generate self-signed certificates
my $certdir = tempdir(CLEANUP => 1);
my $ca_key    = "$certdir/ca.key";
my $ca_cert   = "$certdir/ca.crt";
my $srv_key   = "$certdir/server.key";
my $srv_cert  = "$certdir/server.crt";
my $srv_csr   = "$certdir/server.csr";

# Generate CA
unless (system("openssl genrsa -out $ca_key 2048 2>/dev/null") == 0 &&
        system("openssl req -new -x509 -key $ca_key -out $ca_cert -days 1 -subj '/CN=Test CA' 2>/dev/null") == 0) {
    diag "Failed to generate CA cert — skipping TLS connection tests";
    done_testing;
    exit;
}

# Generate server cert signed by CA
system("openssl genrsa -out $srv_key 2048 2>/dev/null") == 0
    or die "Failed to generate server key";
system("openssl req -new -key $srv_key -out $srv_csr -subj '/CN=127.0.0.1' 2>/dev/null") == 0
    or die "Failed to generate server CSR";
system("openssl x509 -req -in $srv_csr -CA $ca_cert -CAkey $ca_key -CAcreateserial -out $srv_cert -days 1 2>/dev/null") == 0
    or die "Failed to sign server cert";

# Start Redis with TLS
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
    diag "Failed to start TLS Redis: $@";
    done_testing;
    exit;
}

# Wait for Redis to be ready (check if process is alive and port is listening)
my $ready = 0;
for (1..50) {
    # Check if the child process died (TLS not compiled, bad args, etc.)
    my $kid = waitpid($redis_pid, POSIX::WNOHANG());
    if ($kid > 0) {
        $redis_pid = undef;
        last;
    }
    # Try connecting with redis-cli over TLS
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
    done_testing;
    exit;
}

END {
    if ($redis_pid) {
        kill 'TERM', $redis_pid;
        waitpid($redis_pid, 0);
    }
}

# Test: TLS connection with CA cert
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

# Test: SET/GET over TLS
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

# Test: TLS with tls_server_name (SNI)
# Note: LibreSSL (OpenBSD) correctly rejects IP addresses in SNI per RFC 6066.
# on_error must be in constructor since SSL failure fires during connect().
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

# Test: TLS with tls_verify => 0 (skip peer verification, no CA needed)
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

# Test: TLS connection with tls_capath (directory containing CA cert)
{
    # OpenSSL CApath requires hashed symlinks; create them
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

# Test: TLS constructor with invalid CA cert croaks at construction time
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

# Test: TLS reconnection
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
            # Force disconnect via CLIENT KILL to trigger reconnect
            $r->command('CLIENT', 'ID', sub {
                my ($id, $err) = @_;
                if ($err) {
                    $r->disconnect;
                    return;
                }
                # Use a second connection to kill ourselves
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

done_testing;
