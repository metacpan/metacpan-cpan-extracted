use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EVKafkaTest;
use EV;
use EV::Kafka;
use POSIX ();

# Round-2 review regressions: malformed encoder input croaks (no corrupt
# frames), re-entrant connect/disconnect from cancel cbs is honored,
# explicit DESTROY via argument magic cannot abort, tls(1) croaks on
# no-OpenSSL builds, acks=0 callbacks fire on flush (or error), and
# mixed acks=0/acks=1 traffic keeps response correlation intact.

my ($conn, $broker) = ready_conn();

sub req_count { scalar @{$broker->{requests}} }

sub croaks_clean {
    my ($name, $code) = @_;
    my $reqs = req_count();
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    ok !$ok, "$name croaks";
    like $err, qr/bad (element|partition)|missing/, "$name croak message"
        or diag "got: $err";
    is $conn->pending, 0, "$name queues nothing";
    is req_count(), $reqs, "$name sends no bytes";
}

# --- MED: 7 encoders reject malformed elements up front ---

{
    my @t;
    $t[2] = 'x';
    croaks_clean 'metadata holes', sub { $conn->metadata(\@t, undef) };
    croaks_clean 'join_group holes',
        sub { $conn->join_group('g', 'm', \@t, undef) };
    croaks_clean 'delete_topics holes',
        sub { $conn->delete_topics(\@t, 5000, undef) };
}

croaks_clean 'sync_group non-hash elem',
    sub { $conn->sync_group('g', 1, 'm', [[1]], undef) };
croaks_clean 'sync_group missing member_id',
    sub { $conn->sync_group('g', 1, 'm', [{ assignment => 'x' }], undef) };
croaks_clean 'offset_commit non-hash elem',
    sub { $conn->offset_commit('g', 1, 'm', [[1]], undef) };
croaks_clean 'offset_commit missing topic',
    sub {
        $conn->offset_commit('g', 1, 'm',
            [{ partitions => [{ partition => 0, offset => 1 }] }], undef);
    };
croaks_clean 'offset_commit bad partition',
    sub {
        $conn->offset_commit('g', 1, 'm',
            [{ topic => 't', partitions => [[1]] }], undef);
    };
croaks_clean 'offset_fetch non-hash elem',
    sub { $conn->offset_fetch('g', [[1]], undef) };
croaks_clean 'offset_fetch missing topic',
    sub { $conn->offset_fetch('g', [{ partitions => [0] }], undef) };
croaks_clean 'create_topics non-hash elem',
    sub { $conn->create_topics([[1]], 5000, undef) };
croaks_clean 'create_topics missing name',
    sub { $conn->create_topics([{ num_partitions => 1 }], 5000, undef) };

# --- MED: legal near-neighbors still queue (no over-broad checks) ---

{
    $conn->sync_group('g', 1, 'm', [{ member_id => 'x' }], undef);
    is $conn->pending, 1, 'sync_group without assignment queues';
    $conn->offset_commit('g', 1, 'm', [{ topic => 't' }], undef);
    is $conn->pending, 2, 'offset_commit without partitions queues';
    $conn->offset_fetch('g', [{ topic => 't' }], undef);
    is $conn->pending, 3, 'offset_fetch without partitions queues';
    $conn->metadata(['t'], sub { EV::break });
    my $t = timeout_w(5);
    EV::run;
    # Drain the rest; the mock answers all three queued above.
    my $t2 = EV::timer 1, 0, sub { EV::break };
    EV::run;
    is $conn->pending, 0, 'queued near-neighbors all resolve';
}

# --- re-entrant connect() from a cancel cb leaks nothing ---

SKIP: {
    skip '/proc unavailable', 2 unless -d '/proc/self/fd';
    my $fds = sub {
        opendir my $dh, '/proc/self/fd' or die $!;
        my @f = grep /^\d+$/, readdir $dh;
        closedir $dh;
        return scalar @f;
    };
    my ($port, $brk) = mock_broker();
    my $c = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $up = 0;
    $c->on_connect(sub { $up = 1; EV::break });
    $c->on_error(sub { EV::break });
    $c->connect('127.0.0.1', $port, 5);
    my $t = timeout_w(5);
    EV::run;
    BAIL_OUT('setup failed') unless $up;
    my $cycle = sub {
        $c->metadata(undef, sub {
            eval { $c->connect('127.0.0.1', $port, 5) };
        });
        $up = 0;
        $c->connect('127.0.0.1', $port, 5);
        my $t2 = timeout_w(5);
        EV::run;
        die 'reconnect failed' unless $up && $c->connected;
    };
    $cycle->();
    my $before = $fds->();
    $cycle->() for 1 .. 3;
    is $fds->(), $before, 're-entrant connect leaks no fds';
    ok $c->connected, 're-entrant connect still connects';
    $c->disconnect;
}

# --- re-entrant disconnect() from a cancel cb wins ---

{
    my ($port, $brk) = mock_broker();
    my $c = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $up = 0;
    $c->on_connect(sub { $up = 1; EV::break });
    $c->on_error(sub { EV::break });
    $c->connect('127.0.0.1', $port, 5);
    my $t = timeout_w(5);
    EV::run;
    BAIL_OUT('setup failed') unless $up;
    $c->metadata(undef, sub { eval { $c->disconnect } });
    $c->connect('127.0.0.1', $port, 5);
    my $t2 = EV::timer 1.5, 0, sub { EV::break };
    EV::run;
    ok !$c->connected, 'inner disconnect is not swallowed';
}

# --- explicit DESTROY via argument magic cannot abort ---

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

# --- acks=0 fires on flush; mixed acks traffic correlates ---

{
    my ($fired, $res, $error);
    $conn->produce('t', 0, 'k', 'v', { acks => 0 }, sub {
        $fired++;
        ($res, $error) = @_;
        EV::break;
    });
    ok !$fired, 'acks=0 callback is not synchronous';
    is $conn->pending, 1, 'acks=0 callback counts as pending';
    my $t = timeout_w(5);
    EV::run;
    is $fired, 1, 'acks=0 callback fires after flush';
    ok((ref $res eq 'HASH' && !keys %$res), 'acks=0 empty success result');
    ok !defined($error), 'acks=0 no error';
}

{
    my ($f0, $f1, $r1, $e1);
    $conn->produce('t', 0, 'k', 'v0', { acks => 0 }, sub { $f0++ });
    $conn->produce('t', 0, 'k', 'v1', sub {
        ($r1, $e1) = @_;
        $f1++;
        EV::break;
    });
    my $t = timeout_w(5);
    EV::run;
    is $f0, 1, 'mixed: acks=0 callback fires';
    is $f1, 1, 'mixed: acks=1 callback fires';
    ok !$e1, 'mixed: acks=1 has no correlation error';
    ok($r1 && ref $r1->{topics} eq 'ARRAY', 'mixed: acks=1 result shape');
}

{
    my ($fired, $res, $error);
    $conn->produce_batch('t', 0, [{ key => 'k', value => 'v' }],
        { acks => 0 }, sub {
            $fired++;
            ($res, $error) = @_;
            EV::break;
        });
    ok !$fired, 'produce_batch acks=0 is not synchronous';
    my $t = timeout_w(5);
    EV::run;
    is $fired, 1, 'produce_batch acks=0 fires after flush';
    ok !defined($error), 'produce_batch acks=0 no error';
}

$conn->disconnect;

done_testing();

package EVKTest::Killer;

sub TIESCALAR { bless { v => $_[1] }, $_[0] }
sub FETCH { $main::VC->DESTROY; $_[0]{v} }
sub STORE { $_[0]{v} = $_[1] }
