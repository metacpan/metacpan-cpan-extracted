use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use IO::Socket::INET;
use IO::Select;
use Socket qw(SOL_SOCKET SO_SNDBUF sockaddr_in sockaddr_family AF_INET);
use Time::HiRes 'time';
use EV;
use EV::MariaDB;

my $have_server = TestMariaDB::server_available();
plan skip_all => 'no MariaDB server' unless $have_server;

my %only = map { $_ => 1 } split /,/, ($ENV{T25_ONLY} // '');
my %proxy_pids;
my $proxy_owner = $$;
END {
    if (defined $proxy_owner && $$ == $proxy_owner) {
        kill 'TERM', $_ for keys %proxy_pids;
        waitpid($_, 0) for keys %proxy_pids;
    }
}

# Stall proxy: forwards to the real server. Once per connection, after >64KB
# from the client it pauses 2s (forces EAGAIN mid-send); after >64KB from the
# server it pauses 30s (stalls a mid-stream drain).
sub start_stall_proxy {
    my $listen = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1:0', Listen => 5, ReuseAddr => 1, Proto => 'tcp',
    ) or die "proxy listen failed: $!";
    my $port = $listen->sockport;
    my $pid = fork();
    die "fork failed: $!" unless defined $pid;
    if ($pid == 0) {
        $0 = 'ev-mariadb-stall-proxy';
        # Detach stdio so a crashed parent can't leave the harness
        # waiting on a pipe this orphan still holds open.
        open STDIN, '<', '/dev/null';
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        while (my $client = $listen->accept()) {
            my $server = $TestMariaDB::socket
                ? IO::Socket::UNIX->new(Peer => $TestMariaDB::socket, Timeout => 10)
                : IO::Socket::INET->new(
                PeerAddr => $TestMariaDB::host, PeerPort => $TestMariaDB::port,
                Proto => 'tcp', Timeout => 10,
            );
            unless ($server) { close $client; next; }
            my $sel = IO::Select->new($client, $server);
            my ($cbytes, $sbytes, $cstalled, $sstalled) = (0, 0, 0, 0);
            my ($buf, $alive) = ('', 1);
            while ($alive) {
                my @r = $sel->can_read(60);
                last unless @r;
                for my $fh (@r) {
                    my $n = sysread($fh, $buf, 65536);
                    unless ($n) { $alive = 0; last; }
                    my $dst = ($fh == $client) ? $server : $client;
                    if ($fh == $client) {
                        $cbytes += $n;
                        if (!$cstalled && $cbytes > 65536) { $cstalled = 1; sleep 2; }
                    } else {
                        $sbytes += $n;
                        if (!$sstalled && $sbytes > 65536) { $sstalled = 1; sleep 30; }
                    }
                    my $off = 0;
                    while ($off < length $buf) {
                        my $w = syswrite($dst, $buf, length($buf) - $off, $off);
                        last unless $w;
                        $off += $w;
                    }
                }
            }
            close $client;
            close $server;
        }
        exit 0;
    }
    close $listen;
    $proxy_pids{$pid} = 1;
    return ($port, $pid);
}

sub stop_proxy {
    my ($pid) = @_;
    kill 'TERM', $pid;
    waitpid($pid, 0);
    delete $proxy_pids{$pid};
}

sub connect_mariadb {
    my (%extra) = @_;
    my $m = EV::MariaDB->new(
        TestMariaDB::connect_args(), %extra, on_error => sub {},
        (exists $extra{port} ? (host => '127.0.0.1', unix_socket => undef) : ()),
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    my $w = EV::timer(0, 0.05, sub { EV::break if $m->is_connected });
    EV::run;
    undef $t;
    undef $w;
    return $m;
}

 # --- 1: close_stmt on stale handle during reset reconnect ---
if (!%only || $only{1}) {
    my $m = connect_mariadb();
    ok($m->is_connected, '1: connected');
    my ($stmt, $perr, $done);
    $m->prepare('select 1', sub { ($stmt, $perr) = @_; $done = 1; });
    my $t = EV::timer(10, 0, sub { EV::break });
    my $w = EV::timer(0, 0.05, sub { EV::break if $done });
    EV::run;
    undef $t;
    undef $w;
    ok($done && !$perr, '1: prepared') or diag $perr;

    $m->reset();
    my ($fired, $ok, $err);
    eval {
        $m->close_stmt($stmt, sub { ($ok, $err) = @_; $fired = 1; });
    };
    ok(!$@, '1: close_stmt stale during reset reconnect does not croak')
        or diag "croak: $@";
    ok($fired && $ok && !defined $err,
        '1: close_stmt stale during reset fires (1, undef) synchronously');

    eval { $m->close_stmt($stmt, 'not-code'); };
    like($@, qr/callback must be a CODE reference/,
        '1: non-CODE cb still validated first');

    eval { $m->close_stmt(999999999, sub {}); };
    like($@, qr/not connected/,
        '1: unknown handle mid-reconnect still croaks not connected');

    $t = EV::timer(10, 0, sub { EV::break });
    $w = EV::timer(0, 0.05, sub { EV::break if $m->is_connected });
    EV::run;
    undef $t;
    undef $w;
    ok($m->is_connected, '1: reconnected after reset');
    eval { $m->close_stmt($stmt, sub {}); };
    like($@, qr/invalid statement handle/, '1: wrapper freed exactly once');
    $m->finish;
}

 # --- 4: finish() mid-stream with a live stmt must not hang in drain ---
if (!%only || $only{4}) {
    my ($pport, $ppid) = start_stall_proxy();
    my $m = connect_mariadb(port => $pport);
    ok($m->is_connected, '4: connected via proxy');
    my ($stmt, $perr, $done);
    $m->prepare('select 1', sub { ($stmt, $perr) = @_; $done = 1; });
    my $t = EV::timer(25, 0, sub { EV::break });
    my $w = EV::timer(0, 0.05, sub { EV::break if $done });
    EV::run;
    undef $t;
    undef $w;
    ok($done && !$perr, '4: live stmt prepared') or diag $perr;
    my ($nrows, $elapsed);
    $m->query_stream(
        'WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n < 20000) '
        . "SELECT REPEAT('b',500), n FROM s",
        sub {
            my ($row, $err) = @_;
            return if !defined $row;
            $nrows++;
            if ($nrows == 1) {
                my $t0 = time();
                $m->finish();
                $elapsed = time() - $t0;
                EV::break;
            }
        });
    $t = EV::timer(90, 0, sub { EV::break });
    EV::run;
    undef $t;
    ok(defined $elapsed && $elapsed < 8,
        sprintf('4: finish mid-stream with live stmt returns fast (%.2fs)',
            $elapsed // -1));
    stop_proxy($ppid);
}

done_testing();
