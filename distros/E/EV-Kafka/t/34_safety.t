use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;
use IO::Handle;
use IO::Socket::INET;
use POSIX ();
use Socket qw(unpack_sockaddr_in);
use File::Temp qw(tempdir);

# Safety hardening regressions: malformed container arguments must not
# crash the process, and lifecycle edge cases (fork, ithreads, global
# destruction, exec, tied scalars) must behave.
#
# Crash-triggering cases run in forked children and assert only on the
# exit status, so a pre-fix SEGV fails the test instead of killing the file.

my ($conn, $broker) = ready_conn();

# Run $code in a forked child (no TAP output there); the child _exits 0
# on success, 1 on die, and fails on any signal death (e.g. SEGV).
sub child_ok {
    my ($name, $code) = @_;
    my $pid = fork();
    BAIL_OUT("fork failed: $!") unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        my $ok = eval { $code->(); 1 };
        POSIX::_exit($ok ? 0 : 1);
    }
    waitpid($pid, 0);
    my $rc = $?;
    ok($rc == 0, $name)
        or diag($rc & 127 ? "child died by signal " . ($rc & 127)
                          : "child exited " . ($rc >> 8));
}

# --- malformed elements croak instead of emitting corrupt frames ---
# Skipping an entry after the count is written corrupts the frame, so
# the encoders reject malformed elements up front (nothing is queued).
# Each child handshakes its own conn: inherited conns croak after fork.

child_ok 'metadata with holes croaks', sub {
    my ($c) = ready_conn();
    my @t;
    $t[3] = 'x';
    my $ok = eval { $c->metadata(\@t, undef); 1 };
    die 'no croak' if $ok;
    die 'queued anyway' if $c->pending > 0;
};

child_ok 'join_group with holes croaks', sub {
    my ($c) = ready_conn();
    my @t;
    $t[2] = 'x';
    my $ok = eval { $c->join_group('g', 'm', \@t, undef); 1 };
    die 'no croak' if $ok;
    die 'queued anyway' if $c->pending > 0;
};

# --- wrong reftype: a non-hash element croaks, surviving the SvRV cast ---
# Elements are non-empty arrays: an empty [] has a NULL AvALLOC, which
# hv_fetch happens to survive, so only populated arrays crash pre-fix.

child_ok 'sync_group arrayref elem croaks', sub {
    my ($c) = ready_conn();
    my $ok = eval { $c->sync_group('g', 1, 'm', [[1 .. 200]], undef); 1 };
    die 'no croak' if $ok;
    die 'queued anyway' if $c->pending > 0;
};

child_ok 'offset_commit arrayref elem croaks', sub {
    my ($c) = ready_conn();
    my $ok = eval { $c->offset_commit('g', 1, 'm', [[1 .. 200]], undef); 1 };
    die 'no croak' if $ok;
    die 'queued anyway' if $c->pending > 0;
};

child_ok 'offset_commit arrayref partition croaks', sub {
    my ($c) = ready_conn();
    my $ok = eval {
        $c->offset_commit('g', 1, 'm',
            [{ topic => 't', partitions => [[1 .. 200]] }], undef);
        1;
    };
    die 'no croak' if $ok;
    die 'queued anyway' if $c->pending > 0;
};

child_ok 'offset_fetch arrayref elem croaks', sub {
    my ($c) = ready_conn();
    my $ok = eval { $c->offset_fetch('g', [[1 .. 200]], undef); 1 };
    die 'no croak' if $ok;
    die 'queued anyway' if $c->pending > 0;
};

child_ok 'create_topics arrayref elem croaks', sub {
    my ($c) = ready_conn();
    my $ok = eval { $c->create_topics([[1 .. 200]], 5000, undef); 1 };
    die 'no croak' if $ok;
    die 'queued anyway' if $c->pending > 0;
};

# --- undef request cb: silent, like the produce paths already were ---

{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    $conn->metadata(undef, undef);
    # Second request breaks the loop after the undef-cb response is processed.
    $conn->metadata(undef, sub { EV::break });
    my $t = timeout_w(5);
    EV::run;
    is scalar @warns, 0, 'undef request cb warns nothing';
}

# --- ithreads: conns refuse cloning instead of aliasing the C struct ---

{
    my $skip = EV::Kafka::Conn->can('CLONE_SKIP')
        && EV::Kafka::Conn->CLONE_SKIP();
    ok $skip, 'Conn defines CLONE_SKIP';
}

# --- fork: methods on an inherited conn croak ---

{
    my $pid = fork();
    BAIL_OUT("fork failed: $!") unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        my $err = do { local $@; eval { $conn->disconnect; 1 } ? '' : $@ };
        my $getters = eval { $conn->connected; $conn->state; $conn->pending; 1 };
        POSIX::_exit($err =~ /fork/ && $getters ? 0 : 1);
    }
    waitpid($pid, 0);
    ok $? == 0, 'conn method croaks after fork, getters still work';
}

# --- broker socket must not leak across exec ---
# The check is fork+exec: creating a Perl handle on the fd (new_from_fd)
# would itself set CLOEXEC via PerlIO and hide a missing flag.

SKIP: {
    skip '/proc unavailable', 2 unless -d '/proc/self/fd';
    opendir my $dh, '/proc/self/fd' or die $!;
    my %before = map { $_ => 1 } grep /^\d+$/, readdir $dh;
    closedir $dh;
    my ($conn2, $broker2) = ready_conn();
    opendir my $dh2, '/proc/self/fd' or die $!;
    my @new = grep { !$before{$_} } grep /^\d+$/, readdir $dh2;
    closedir $dh2;
    # The client socket: peer is the broker port, local end is ephemeral.
    # A real dup ('<&') is read-only w.r.t. the original's flags.
    my $cfd;
    for my $fd (@new) {
        open my $dup, '<&', $fd or next;
        my $peer = getpeername($dup);
        my $sock = getsockname($dup);
        next unless $peer && $sock;
        my ($pport) = unpack_sockaddr_in($peer);
        my ($sport) = unpack_sockaddr_in($sock);
        if ($pport == $broker2->{port} && $sport != $broker2->{port}) {
            $cfd = $fd;
            last;
        }
    }
    ok defined $cfd, 'found conn socket fd';
    SKIP: {
        skip 'no conn fd found', 1 unless defined $cfd;
        my $pid = fork();
        BAIL_OUT("fork failed: $!") unless defined $pid;
        if ($pid == 0) {
            open STDOUT, '>', '/dev/null';
            open STDERR, '>', '/dev/null';
            { exec { $^X } $^X, '-e', "open my \$fh, '<&', $cfd or exit 0; exit 42"; }
            POSIX::_exit(99);
        }
        waitpid($pid, 0);
        my $rc = $? >> 8;
        ok $rc == 0, 'broker socket has FD_CLOEXEC'
            or diag "exec probe exit=$rc (42 means the fd leaked)";
        $conn2->disconnect;
    }
}

# --- tied scalars: SvOK-gated key/value must see FETCH bytes ---
# (Bare SvPV already fetches magic; only the SvOK checks dropped ties.)

{
    tie my $key, 'EVKTest::Tie', 'tied-key';
    tie my $val, 'EVKTest::Tie', 'tied-val';
    $conn->produce('t', 0, $key, $val, sub { EV::break });
    my $t = timeout_w(5);
    EV::run;
    my ($prod) = grep { $_->{api} == 0 } reverse @{$broker->{requests}};
    ok $prod && index($prod->{body}, 'tied-key') >= 0,
        'tied key FETCH bytes on wire';
    ok $prod && index($prod->{body}, 'tied-val') >= 0,
        'tied value FETCH bytes on wire';
}

# --- connect() must not use the caller's host SV after cancel cbs run ---
# $host is sprintf-built (private buffer, not COW-shared with a const),
# and the cancel cb rewrites it in place via substr.

child_ok 'connect reuses saved host across cancel cbs', sub {
    my ($port, $brk) = mock_broker();
    my $c = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $up = 0;
    $c->on_connect(sub { $up = 1; EV::break });
    $c->on_error(sub { EV::break });
    $c->connect('127.0.0.1', $port, 5);
    my $t = timeout_w(5);
    EV::run;
    die 'handshake failed' unless $up;
    my $host = sprintf('127.0.0.%d', 1);
    $c->metadata(undef, sub { substr($host, 8, 1) = '2' });
    $up = 0;
    $c->connect($host, $port, 5);
    my $t2 = timeout_w(5);
    EV::run;
    die 'reconnect failed' unless $up && $c->connected;
};

# --- on_disconnect/on_error must not fire during global destruction ---
# Global-destruction order is layout-dependent: a holder's DESTROY may
# run after its member was freed. Many holders are used, and the
# assertions are skipped unless at least one holder actually observed
# an intact conn (measured, never assumed).

{
    my $dir = tempdir(CLEANUP => 1);
    my ($setup, $cnt1, $m1, $cnt2, $m2, $out) =
        map "$dir/$_", qw(setup cnt1 m1 cnt2 m2 out);
    my $pid = fork();
    BAIL_OUT("fork failed: $!") unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>', $out;
        open STDERR, '>&STDOUT';
        my ($port, $brk) = mock_broker();
        my $c = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
        my $up = 0;
        open $EVKTest::GD::M1, '>', $m1 or exit 9;
        open $EVKTest::GD::C1, '>', $cnt1 or exit 9;
        $c->on_connect(sub { $up = 1; EV::break });
        $c->on_disconnect(sub { syswrite($EVKTest::GD::M1, 'x') });
        $c->connect('127.0.0.1', $port, 5);
        my $t = timeout_w(5);
        EV::run;
        # A port that is closed: refused connects fail without DNS or delay.
        my $probe = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1', LocalPort => 0,
            Listen => 1, Proto => 'tcp', ReuseAddr => 1) or exit 9;
        my $closed = $probe->sockport;
        close $probe;
        open $EVKTest::GD::M2, '>', $m2 or exit 9;
        open $EVKTest::GD::C2, '>', $cnt2 or exit 9;
        # Holders live in package globals: lexicals die pre-exit with
        # phase=RUN, but globals die in real global destruction.
        # Markers use syswrite: open/print may need freed stashes there.
        @EVKTest::GD::HOLD1 =
            map { bless { conn => $c }, 'EVKTest::Disconnector' } 1 .. 30;
        @EVKTest::GD::HOLD2 = map {
            my $c2 = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
            $c2->on_error(sub {
                syswrite($EVKTest::GD::M2, 'x');
                EV::break;
            });
            bless { conn => $c2, port => $closed }, 'EVKTest::Refused';
        } 1 .. 5;
        if ($up) {
            open my $fh, '>', $setup; close $fh;
        }
        exit 0;    # normal exit runs global destruction
    }
    waitpid($pid, 0);
    my $rc = $?;
    ok !($rc & 127), 'global-destruction child not killed by signal';
    ok -e $setup, 'global-destruction child reached exit path'
        or do {
            open my $fh, '<', $out;
            diag do { local $/; <$fh> };
        };
    SKIP: {
        skip 'layout freed conns before holders', 1 unless -s $cnt1;
        ok !-s $m1, 'on_disconnect suppressed during global destruction';
    }
    SKIP: {
        skip 'layout freed conns before holders', 1 unless -s $cnt2;
        ok !-s $m2, 'on_error suppressed during global destruction';
    }
}

# --- explicit DESTROY inside an XSUB-fired cb must not strand the conn ---
# Each cycle strands a 64KB wbuf when the reap is missing; VmHWM (peak
# RSS, monotonic) shows it where /proc is available.

SKIP: {
    skip '/proc unavailable', 1 unless -r '/proc/self/status';
    my $pid = fork();
    BAIL_OUT("fork failed: $!") unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        my ($port, $brk) = mock_broker();
        my $cycle = sub {
            my $c = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
            my $up = 0;
            $c->on_connect(sub { $up = 1; EV::break });
            $c->on_error(sub { EV::break });
            $c->connect('127.0.0.1', $port, 5);
            my $t = timeout_w(5);
            EV::run;
            die 'setup failed' unless $up;
            $c->produce('t', 0, undef, 'v' x 65536, sub { });
            $c->metadata(undef, sub { $c->DESTROY });
            $c->disconnect;
            # Keep the broker side bounded so only the client can grow.
            @{$brk->{requests}} = ();
            @{$brk->{conns}} = ();
        };
        $cycle->() for 1 .. 5;    # warm up allocators
        my $before = EVKTest::Leak::vmhwm();
        $cycle->() for 1 .. 60;
        my $after = EVKTest::Leak::vmhwm();
        POSIX::_exit($after - $before < 1024 ? 0 : 1);
    }
    waitpid($pid, 0);
    my $rc = $?;
    ok $rc == 0, 'no RSS growth on explicit DESTROY in cancel cb'
        or diag($rc & 127 ? 'child died by signal ' . ($rc & 127)
                          : 'child exited ' . ($rc >> 8));
}

$conn->disconnect;

done_testing();

package EVKTest::GD;

our (@HOLD1, @HOLD2, $M1, $C1, $M2, $C2);

package EVKTest::Tie;

sub TIESCALAR { bless { v => $_[1] }, $_[0] }
sub FETCH { $_[0]{v} }
sub STORE { $_[0]{v} = $_[1] }

package EVKTest::Disconnector;

sub DESTROY {
    my $c = $_[0]{conn} or return;
    syswrite($EVKTest::GD::C1, 'i');
    eval { $c->disconnect };
}

package EVKTest::Refused;

# Refused connect plus a short pump: connection-refused fires on_error.
# Runs in global destruction, hence syswrite and no method calls there.
sub DESTROY {
    my $s = shift;
    my $c = $s->{conn} or return;
    syswrite($EVKTest::GD::C2, 'i');
    eval {
        $c->connect('127.0.0.1', $s->{port} + 0, 5);
        my $t = EV::timer 0.2, 0, sub { EV::break };
        EV::run;
    };
}

package EVKTest::Leak;

sub vmhwm {
    open my $fh, '<', '/proc/self/status' or die $!;
    while (<$fh>) { return $1 if /^VmHWM:\s+(\d+)\s*kB/; }
    die 'no VmHWM';
}
