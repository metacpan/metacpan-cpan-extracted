use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

my $have_server = TestMariaDB::server_available();
diag('no test server - server-dependent blocks will skip') unless $have_server;

SKIP: {
    skip 'No MariaDB/MySQL server', 8 unless $have_server;

    # --- close_async must invalidate tracked stmt handles ---
    # Retained statement wrappers must be invalid after close and reconnect.
    {
        my $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub { EV::break },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for close_async-stmt test') unless $m->is_connected;

        my $sth;
        $m->prepare('select 1', sub { ($sth) = @_; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('prepare failed for close_async-stmt test') unless defined $sth;

        my $closed = 0;
        $m->close_async(sub { $closed = 1; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($closed, 'close_async completed');
        ok(!$m->is_connected, 'disconnected after close_async');

        my $reconnected = 0;
        $m->on_connect(sub { $reconnected = 1; EV::break });
        $m->reset;
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($reconnected && $m->is_connected, 'reset() reconnects after close_async');

        eval { $m->execute($sth, undef, sub { fail('stale execute cb must not fire') }) };
        like($@, qr/no longer valid/, 'stale stmt handle rejected after close+reconnect');

        my $close_ok = 0;
        $m->close_stmt($sth, sub { my ($v, $e) = @_; $close_ok = 1 if $v && !$e; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($close_ok, 'close_stmt on invalidated handle succeeds via fast path');

        $m->finish if $m->is_connected;
    }

    # Callbacks can bind parameters and start a ping after queueing a query.
    {
        my $m = EV::MariaDB->new(
            TestMariaDB::connect_args(),
            on_connect => sub { EV::break },
            on_error   => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for send_queue test') unless $m->is_connected;

        my $sth;
        $m->prepare('select ?', sub { ($sth) = @_; EV::break });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('prepare failed for send_queue test') unless defined $sth;

        my ($ping_done, $bind_err, $q2_done) = (0, '', 0);
        $m->query('select 1', sub {
            $m->query('select 2', sub { $q2_done = 1; EV::break });
            eval { $m->bind_params($sth, [1]) };
            $bind_err = $@;
            $m->ping(sub { $ping_done = $_[0] && !$_[1] });
        });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        is($bind_err, '', 'binding parameters is allowed before queued queries are sent');
        ok($ping_done, 'ping queued from the callback completes');
        ok($q2_done, 'buffered query completes after the ping');

        $m->finish if $m->is_connected;
    }
}

done_testing;
