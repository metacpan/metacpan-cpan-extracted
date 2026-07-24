#!/usr/bin/env perl
# Regression tests for two defects found in the 0.05 review:
#   * `idempotent => 0` leaked to the server as an unknown setting, because
#     is_client_only_key() omitted it and insert() only stripped it on the
#     truthy path. Reproduces on HTTP, where the server validates settings:
#     "HTTP 404: Code: 115. DB::Exception: Unknown setting 'idempotent'".
#   * Streamer wedged forever when insert() croaked synchronously inside
#     _flush: in_flight stayed 1, finish()'s callback never fired and
#     sticky_error was never set.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

plan skip_all => "ClickHouse HTTP not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

plan tests => 5;

# ---------------------------------------------------------------------
# `idempotent => 0` must be stripped client-side, not sent to the server.
# A falsy value is documented as a no-op; before the fix the server
# rejected it with Code 115, Unknown setting 'idempotent'.
# ---------------------------------------------------------------------
{
    my $tbl = "ev_ch_idem0_$$";
    my ($err, $done);

    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        on_connect => sub {
            $ch->query("create table if not exists $tbl (n UInt32) engine=Memory", sub {
                my (undef, $e) = @_;
                if ($e) { $err = $e; return EV::break }
                $ch->insert($tbl, [[1]], { idempotent => 0 }, sub {
                    my (undef, $e2) = @_;
                    $err  = $e2;
                    $done = 1;
                    $ch->query("drop table if exists $tbl", sub { EV::break });
                });
            });
        },
        on_error => sub { $err //= $_[1] // 'connection error'; EV::break },
    );
    EV::run;

    ok($done, 'insert with idempotent => 0 ran to completion');
    is($err, undef, 'idempotent => 0 is not forwarded to the server')
        or diag("error was: " . (defined $err ? $err : '(undef)'));
}

# ---------------------------------------------------------------------
# Streamer must not wedge when insert() croaks synchronously. finish()
# puts the connection in the definitively-disconnected state, which is
# where insert() croaks before queueing anything.
# ---------------------------------------------------------------------
{
    my ($in_flight, $sticky, $finish_fired) = (undef, undef, 0);

    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        on_connect => sub {
            $ch->finish;                    # terminal not-connected state

            my $s = $ch->insert_streamer("ev_ch_no_such_table_$$",
                                         batch_size => 1);
            # Triggers _flush, whose insert() croaks synchronously. The
            # croak is swallowed by G_EVAL inside XS _streamer_push_row,
            # so the streamer's own state is all we can observe.
            $s->push_row([1]);
            $in_flight = $s->in_flight;
            $sticky    = $s->sticky_error;
            $s->finish(sub { $finish_fired = 1 });
            EV::break;
        },
        on_error => sub { EV::break },
    );
    EV::run;

    is($in_flight, 0, 'Streamer in_flight is reset after a synchronous insert croak');
    ok(defined $sticky, 'Streamer sticky_error is set after a synchronous insert croak')
        or diag('sticky_error was undef - the streamer would buffer rows forever');
    ok($finish_fired, 'Streamer finish() callback still fires after the croak');
}
