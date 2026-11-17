use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMySQL;
use EV;
use EV::mysql;

my $have_server = TestMySQL::server_available();
diag('no test server - DB tests will skip') unless $have_server;

SKIP: {
    skip 'No MySQL/MySQL server', 3 unless $have_server;

    subtest 'stream DML-first multi drains secondary results' => sub {
        plan tests => 4;
        my $m = EV::mysql->new(
            TestMySQL::connect_args(),
            multi_statements => 1,
            on_connect       => sub { EV::break },
            on_error         => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for stream-DML-drain test') unless $m->is_connected;

        my $eof = 0;
        $m->query_stream("do 1; select 2", sub {
            my ($row, $err) = @_;
            if ($err) { fail("stream DML-first: unexpected error: $err"); EV::break; return }
            return if defined $row;
            $eof = 1;
            $m->q("select 42", sub {
                my ($r, $e) = @_;
                ok(!$e, 'stream DML-first: follow-up query has no error')
                    or diag("follow-up error: $e");
                is($r && $r->[0][0], 42, 'stream DML-first: follow-up query returns data');
                ok($m->is_connected, 'stream DML-first: connection still up');
                EV::break;
            });
        });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok($eof, 'stream DML-first: got EOF');
        $m->finish;
    };

    subtest 'stream DML-only multi drains without a result set' => sub {
        plan tests => 3;
        my $m = EV::mysql->new(
            TestMySQL::connect_args(),
            multi_statements => 1,
            on_connect       => sub { EV::break },
            on_error         => sub { diag("connect failed: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        BAIL_OUT('could not connect for stream-DML-only test') unless $m->is_connected;

        $m->query_stream("do 1; do 2", sub {
            my ($row, $err) = @_;
            if ($err) { fail("stream DML-only: unexpected error: $err"); EV::break; return }
            return if defined $row;
            pass('stream DML-only: got EOF');
            $m->q("select 7", sub {
                my ($r, $e) = @_;
                ok(!$e && $r->[0][0] == 7, 'stream DML-only: follow-up query works');
                ok($m->is_connected, 'stream DML-only: connection still up');
                EV::break;
            });
        });
        $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        $m->finish;
    };

    subtest 'nested reset_connection in EOF callback survives the drain' => sub {
        plan tests => 8;
        for my $case (
            ['DML-first',    'do 1; select sleep(1)'],
            ['select-first', 'select 1; select sleep(1)'],
        ) {
            my ($tag, $sql) = @$case;
            my $m = EV::mysql->new(
                TestMySQL::connect_args(),
                multi_statements => 1,
                on_connect       => sub { EV::break },
                on_error         => sub { diag("connect failed: $_[0]"); EV::break },
            );
            my $t = EV::timer(10, 0, sub { EV::break });
            EV::run;
            BAIL_OUT('could not connect for EOF-nest test') unless $m->is_connected;

            my ($eof, $rok, $rerr);
            $m->query_stream($sql, sub {
                my ($row, $err) = @_;
                if ($err) { fail("$tag: unexpected stream error: $err"); EV::break; return }
                return if defined $row;
                $eof = 1;
                $m->reset_connection(sub { ($rok, $rerr) = @_; EV::break });
            });
            $t = EV::timer(15, 0, sub { EV::break });
            EV::run;
            ok($eof, "$tag: got EOF");
            ok($rok && !$rerr, "$tag: nested reset cb fired with ok");

            my $fup = 0;
            $m->query('select 99', sub { $fup = 1; EV::break });
            $t = EV::timer(10, 0, sub { EV::break });
            EV::run;
            ok($fup, "$tag: follow-up cb fired (connection not wedged)");
            ok($m->is_connected, "$tag: connection still up");
            $m->finish;
        }
    };
}

done_testing;
