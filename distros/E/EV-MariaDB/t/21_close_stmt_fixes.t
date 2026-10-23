use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

my $have_server = TestMariaDB::server_available();
diag('no test server - server-dependent blocks will skip') unless $have_server;

# --- POD lists close_async as a statement invalidator ---
{
    open my $fh, '<', 'lib/EV/MariaDB.pm' or die "open: $!";
    local $/;
    my $pm = <$fh>;
    close $fh;

    my ($prepare)   = $pm =~ /(=head2 prepare\b.*?)(?==head2 |\z)/s;
    my ($close_stmt) = $pm =~ /(=head2 close_stmt\b.*?)(?==head2 |\z)/s;
    my ($stmt_reset) = $pm =~ /(=head2 stmt_reset\b.*?)(?==head2 |\z)/s;
    my ($close_async) = $pm =~ /(=head2 close_async\b.*?)(?==head2 |\z)/s;

    like($prepare, qr/close_async/, 'prepare POD lists close_async as invalidator');
    like($close_stmt, qr/close_async/, 'close_stmt POD lists close_async as invalidator');
    like($stmt_reset, qr/close_async/, 'stmt_reset POD lists close_async as invalidator');
    like($close_async, qr/no longer valid/,
        'close_async POD notes statement invalidation');
}

# --- connect() accepts undef password/database without warning ---
# SvPV conversion happens before any network I/O, so a dead port still
# exercises the XS argument handling. Checks the supplied arguments and warning behavior.
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my $m = EV::MariaDB->new(
        on_error => sub { EV::break },
    );
    $m->connect('127.0.0.1', 'nouser', undef, undef, 1);
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    is_deeply(\@warns, [], 'connect(undef, undef) emits no warnings');
    $m->finish;
}

SKIP: {
    skip 'No MariaDB/MySQL server', 7 unless $have_server;

    my $host = $TestMariaDB::host;
    my $port = $TestMariaDB::port;
    my $user = $TestMariaDB::user;
    my $pass = $TestMariaDB::pass;

    # --- undef password/database connects cleanly ---
    {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, @_ };
        my ($connected, $conn_err);
        my $m = EV::MariaDB->new(
            on_connect => sub { $connected = 1; EV::break },
            on_error   => sub { $conn_err = $_[0]; EV::break },
        );
        # undef password only authenticates when the account has none;
        # the no-server test above always covers the undef conversion.
        my $pw = ($pass eq '') ? undef : $pass;
        $m->connect($host, $user, $pw, undef, $port, $TestMariaDB::socket);
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($connected && !defined $conn_err, 'connect with undef database succeeds')
            or diag("connect failed: " . ($conn_err // '?'));
        is_deeply(\@warns, [], 'no warnings from undef connect args');

        # no default database selected, but db-less queries still work
        my ($rows, $qerr);
        $m->query('select 1', sub { ($rows, $qerr) = @_; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        is($rows->[0][0], 1, 'query works after undef-database connect')
            or diag("query failed: " . ($qerr // '?'));
        $m->finish if $m->is_connected;
    }

    # --- undef connect args survive FATAL uninitialized warnings ---
    {
        my ($connected, $conn_err);
        my $m = EV::MariaDB->new(
            on_connect => sub { $connected = 1; EV::break },
            on_error   => sub { $conn_err = $_[0]; EV::break },
        );
        my $pw = ($pass eq '') ? undef : $pass;
        my $err;
        {
            use warnings FATAL => 'uninitialized';
            eval { $m->connect($host, $user, $pw, undef, $port, $TestMariaDB::socket) };
            $err = $@;
        }
        ok(!$err, 'connect(undef) does not die under FATAL warnings')
            or diag("died: $err");
        if (!$err) {
            my $t = EV::timer(10, 0, sub { EV::break });
            EV::run;
        }
        ok($connected, 'FATAL-warnings connect still connects')
            or diag("connect failed: " . ($conn_err // '?'));
        $m->finish if $m->is_connected;
    }

    # --- statements stay invalidated across close_async (multi-stmt) ---
    # on_close_done now mysql_stmt_close()s each detached handle instead
    # of leaking it; a crash here means close-on-detached is unsafe.
    {
        my $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub { EV::break },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for close-stmt test') unless $m->is_connected;

        my (@stmts, $perr);
        for (1..2) {
            $m->prepare('select ?', sub { push @stmts, $_[0]; $perr //= $_[1]; EV::break });
            $t = EV::timer(10, 0, sub { EV::break });
            EV::run;
        }
        BAIL_OUT("prepare failed: $perr") if $perr || @stmts != 2;

        my $closed = 0;
        $m->close_async(sub { $closed = 1; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($closed, 'close_async with open stmts completes without crashing');

        eval { $m->execute($stmts[0], undef, sub {}) };
        like($@, qr/not connected/, 'execute-after-close without reset croaks');

        $m->finish;
    }
}

SKIP: {
    skip 'No MariaDB/MySQL server', 9 unless $have_server;

    # --- close_stmt(stale) while a query is in flight: croak, victim unharmed ---
    # The stale-handle fast path push/delivers synchronously; with another
    # callback queued it must preserve the next callback's result.
    {
        my ($m, $stale, $phase, $zt, $wt);
        my ($q, $cerr);
        $m = EV::MariaDB->new(TestMariaDB::connect_args(),
            on_connect => sub {
                if (!$phase) {
                    $m->prepare("select 1", sub { ($stale) = @_; $phase = 1; $m->reset; });
                    return;
                }
                $zt = EV::timer(0, 0, sub {
                    # the sleep column keeps the query from finishing inside
                    # query() on a fast loopback, which would leave the state
                    # IDLE and close_stmt with nothing to collide with
                    $m->query("select 42, sleep(0.25)", sub { $q = [@_]; });
                    eval { $m->close_stmt($stale, sub {}) };
                    $cerr = $@;
                    $wt = EV::timer(1, 0, sub { EV::break });
                });
            },
            on_error => sub { BAIL_OUT("connect failed: $_[0]") });
        my $t = EV::timer(10, 0, sub { BAIL_OUT("timed out"); EV::break });
        EV::run;
        like($cerr, qr/another operation is in progress/,
            'close_stmt(stale) croaks while query in flight');
        is(ref $q->[0], 'ARRAY', 'victim query cb still gets rows');
        my $qcell = ref $q->[0] eq 'ARRAY' ? $q->[0][0][0] : undef;
        is($qcell, '42', 'victim query rows intact');
        $m->finish if $m->is_connected;
    }

    # --- close_stmt(stale) while an execute is in flight ---
    {
        my ($m, $stale, $phase, $zt, $wt);
        my ($e, $cerr);
        $m = EV::MariaDB->new(TestMariaDB::connect_args(),
            on_connect => sub {
                if (!$phase) {
                    $m->prepare("select 1", sub {
                        ($stale) = @_;
                        $m->prepare("select 7", sub { $phase = 1; $m->reset; });
                    });
                    return;
                }
                $m->prepare("select 7, sleep(0.25)", sub {
                    my ($live) = @_;
                    $zt = EV::timer(0, 0, sub {
                        $m->execute($live, [], sub { $e = [@_]; });
                        eval { $m->close_stmt($stale, sub {}) };
                        $cerr = $@;
                        $wt = EV::timer(1, 0, sub { EV::break });
                    });
                });
            },
            on_error => sub { BAIL_OUT("connect failed: $_[0]") });
        my $t = EV::timer(10, 0, sub { BAIL_OUT("timed out"); EV::break });
        EV::run;
        like($cerr, qr/another operation is in progress/,
            'close_stmt(stale) croaks while execute in flight');
        is(ref $e->[0], 'ARRAY', 'victim execute cb still gets rows');
        my $ecell = ref $e->[0] eq 'ARRAY' ? $e->[0][0][0] : undef;
        is($ecell, '7', 'victim execute rows intact');
        $m->finish if $m->is_connected;
    }

    # --- control: buffered (unsent) query + close_stmt(stale) still fast-paths ---
    {
        my ($m, $stale, $phase);
        my ($q, $sync, $c);
        $m = EV::MariaDB->new(TestMariaDB::connect_args(),
            on_connect => sub {
                if (!$phase) {
                    $m->prepare("select 1", sub { ($stale) = @_; $phase = 1; $m->reset; });
                    return;
                }
                $m->query("select 42", sub { $q = [@_]; EV::break });
                $m->close_stmt($stale, sub { $c = [@_]; });
                $sync = defined $c ? 1 : 0;
            },
            on_error => sub { BAIL_OUT("connect failed: $_[0]") });
        my $t = EV::timer(10, 0, sub { BAIL_OUT("timed out"); EV::break });
        EV::run;
        ok($sync && $c->[0] == 1 && !defined $c->[1],
            'close_stmt(stale) still sync-completes next to a buffered query');
        is(ref $q->[0], 'ARRAY', 'buffered query cb gets rows');
        my $bcell = ref $q->[0] eq 'ARRAY' ? $q->[0][0][0] : undef;
        is($bcell, '42', 'buffered query rows intact');
        $m->finish if $m->is_connected;
    }
}

done_testing;
