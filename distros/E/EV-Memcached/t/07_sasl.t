use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

# SASL tests require:
# 1. saslpasswd2 (sasl2-bin package)
# 2. memcached with -S support
# Setup: TEST_MEMCACHED_SASL_PORT, TEST_MEMCACHED_SASL_USER, TEST_MEMCACHED_SASL_PASS
# Or auto-setup if saslpasswd2 and memcached are available

my $host = $ENV{TEST_MEMCACHED_HOST} || '127.0.0.1';
my $port = $ENV{TEST_MEMCACHED_SASL_PORT};
my $user = $ENV{TEST_MEMCACHED_SASL_USER} || 'evmc_test';
my $pass = $ENV{TEST_MEMCACHED_SASL_PASS} || 'evmc_secret';
my $auto_started;

unless ($port) {
    # Try to auto-setup SASL memcached
    my $saslpasswd = '/usr/sbin/saslpasswd2';
    unless (-x $saslpasswd) {
        plan skip_all => "saslpasswd2 not found (install sasl2-bin)";
    }

    my $dir = "/tmp/evmc_sasl_test_$$";
    mkdir $dir, 0755;

    # Create SASL credentials
    open my $pw, '|-', "$saslpasswd -a memcached -c -f $dir/sasldb2 -p $user 2>/dev/null"
        or plan skip_all => "cannot run saslpasswd2";
    print $pw $pass;
    close $pw;
    unless (-f "$dir/sasldb2") {
        system("rm -rf $dir");
        plan skip_all => "saslpasswd2 failed to create db";
    }

    # SASL config
    open my $conf, '>', "$dir/memcached.conf" or die "write conf: $!";
    print $conf "mech_list: plain\nsasldb_path: $dir/sasldb2\n";
    close $conf;

    # Start SASL memcached
    $port = 18399;
    system("SASL_CONF_PATH=$dir memcached -S -B binary -d -p $port -U 0 -P $dir/mc.pid 2>/dev/null");

    # Wait for startup with retry
    my $started = 0;
    for (1..10) {
        select(undef, undef, undef, 0.1);
        my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1);
        if ($s) { close $s; $started = 1; last; }
    }
    unless ($started) {
        system("rm -rf $dir");
        plan skip_all => "cannot start SASL memcached on port $port";
    }
    $auto_started = $dir;
}

sub run_ev {
    my $t = EV::timer 5, 0, sub { fail("timeout"); EV::break };
    EV::run;
}

my $prefix = "ev_mc_sasl_$$\_";

# --- sasl_list_mechs ---
{
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub { diag "error: @_" },
    );
    $mc->on_connect(sub {
        $mc->sasl_list_mechs(sub {
            my ($mechs, $err) = @_;
            ok(!$err, "sasl_list_mechs: no error");
            like($mechs, qr/PLAIN/i, "sasl_list_mechs: PLAIN available");
            $mc->disconnect;
            EV::break;
        });
    });
    run_ev();
}

# --- auto-auth via constructor ---
{
    my $mc = EV::Memcached->new(
        host     => $host,
        port     => $port,
        username => $user,
        password => $pass,
        on_error => sub { diag "error: @_" },
    );
    $mc->on_connect(sub {
        $mc->set("${prefix}auto", "hello", sub {
            my ($res, $err) = @_;
            ok(!$err, "auto-auth: set succeeds");

            $mc->get("${prefix}auto", sub {
                my ($val, $err) = @_;
                is($val, "hello", "auto-auth: get returns value");
                $mc->disconnect;
                EV::break;
            });
        });
    });
    run_ev();
}

# --- explicit sasl_auth ---
{
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub { diag "error: @_" },
    );
    $mc->on_connect(sub {
        $mc->sasl_auth($user, $pass, sub {
            my ($res, $err) = @_;
            ok(!$err, "explicit sasl_auth: no error");
            ok($res, "explicit sasl_auth: success");

            $mc->set("${prefix}explicit", "works", sub {
                my ($res, $err) = @_;
                ok(!$err, "explicit sasl_auth: set after auth");
                $mc->disconnect;
                EV::break;
            });
        });
    });
    run_ev();
}

# --- wrong password ---
{
    my $error_msg;
    my $mc = EV::Memcached->new(
        host     => $host,
        port     => $port,
        username => $user,
        password => 'wrong_password',
        on_error => sub { $error_msg = $_[0] },
    );
    $mc->on_connect(sub {
        # After connect, auth is pipelined — wait for error
        my $w; $w = EV::timer 1, 0, sub {
            undef $w;
            ok($error_msg, "wrong password: on_error fired");
            like($error_msg // '', qr/SASL auth failed|AUTH/,
                "wrong password: error message");
            ok(!$mc->is_connected, "wrong password: disconnected");
            EV::break;
        };
    });
    run_ev();
}

# --- command without auth on SASL server ---
{
    my $error_msg;
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub { $error_msg = $_[0] },
    );
    $mc->on_connect(sub {
        $mc->get("${prefix}noauth", sub {
            my ($val, $err) = @_;
            ok($err, "no auth: get returns error: " . ($err // ''));
            EV::break;
        });
    });
    run_ev();
}

# Cleanup
if ($auto_started) {
    my $pid_file = "$auto_started/mc.pid";
    if (-f $pid_file) {
        my $pid = do { local $/; open my $f, '<', $pid_file; <$f> };
        chomp $pid;
        kill 'TERM', $pid if $pid;
    }
    system("rm -rf $auto_started");
}

done_testing;
