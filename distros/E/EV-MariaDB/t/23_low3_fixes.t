use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

my $have_server = TestMariaDB::server_available();
diag('no test server - DB tests will skip') unless $have_server;

SKIP: {
    skip 'No MariaDB/MySQL server', 8 unless $have_server;

    # --- 1. escape() propagates the SvUTF8 flag ---
    {
        my $m;
        $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            charset    => 'utf8mb4',
            on_connect => sub { EV::break },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for escape-utf8 test') unless $m->is_connected;

        my $uni = "café déjà";
        my $escaped = $m->escape($uni);
        ok(utf8::is_utf8($escaped), 'escape: UTF-8 flag propagated to result');
        is($escaped, $uni, 'escape: flagged value round-trips without double-encoding');

        my $bytes = "it's a test";
        ok(!utf8::is_utf8($m->escape($bytes)), 'escape: byte string stays unflagged');

        $m->finish;
    }

    # --- 2. after close_async, stmt ops croak 'not connected' until reset ---
    {
        my $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub { EV::break },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for close_async-window test') unless $m->is_connected;

        my $sth;
        $m->prepare('select 1', sub { ($sth) = @_; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('prepare failed for close_async-window test') unless defined $sth;

        my $closed = 0;
        $m->close_async(sub { $closed = 1; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($closed, 'close_async completed');

        eval { $m->stmt_reset($sth, sub {}) };
        like($@, qr/not connected/, 'stmt_reset after close_async croaks not connected');
        eval { $m->close_stmt($sth, sub {}) };
        like($@, qr/not connected/, 'close_stmt after close_async croaks not connected');

        $m->finish;
    }

    # --- 3. stmt_reset retains parameter bindings ---
    {
        my $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub { EV::break },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for stmt_reset-bind test') unless $m->is_connected;

        my ($sth, $perr);
        $m->prepare('select ? + ?', sub { ($sth, $perr) = @_; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT("prepare failed: $perr") if $perr || !defined $sth;

        $m->bind_params($sth, [40, 2]);
        my $rok;
        $m->stmt_reset($sth, sub { $rok = $_[0] && !$_[1]; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($rok, 'stmt_reset ok');

        my ($rows, $eerr);
        $m->execute($sth, undef, sub { ($rows, $eerr) = @_; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        is($rows->[0][0], 42, 'execute(undef) after stmt_reset re-uses retained binds');

        $m->finish if $m->is_connected;
    }
}

done_testing;
