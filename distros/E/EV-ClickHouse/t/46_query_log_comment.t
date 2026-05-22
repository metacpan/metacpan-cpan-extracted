#!/usr/bin/env perl
# Per-connection query_log_comment + per-query query_log_comment via
# settings should round-trip via system.query_log. Native and HTTP
# both prepend the comment as `/* qlc */` so the server stores it
# verbatim in the log_comment column.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

# system.query_log is opt-in via the server's <query_log> config.
# Probe first; skip if disabled.
my $ql_enabled;
{
    my $probe; $probe = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $probe->query(
                "select 1 from system.tables where database='system' and name='query_log'",
                sub {
                    my ($r) = @_;
                    $ql_enabled = $r && @$r ? 1 : 0;
                    EV::break;
                });
        },
        on_error => sub { EV::break },
    );
    my $bail = EV::timer(3, 0, sub { EV::break }); EV::run; undef $bail;
    $probe->finish;
}
plan skip_all => "system.query_log not enabled on this server"
    unless $ql_enabled;

plan tests => 3;

my $tag  = "ev-ch-qlc-$$-" . int(rand(1_000_000));
my $qid  = "$tag-q1";

my ($insert_err, $rows, $err);
my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $nport, protocol => 'native',
    query_log_comment => $tag,
    on_connect => sub {
        $ch->query("select 1", { query_id => $qid }, sub {
            (undef, $insert_err) = @_;
            # Force the server to materialize the log entry.
            $ch->query("system flush logs", sub {
                $ch->query(
                    "select query_id, log_comment from system.query_log "
                  . "where query_id = {q:String} order by event_time desc limit 1",
                    { params => { q => $qid } },
                    sub { ($rows, $err) = @_; EV::break },
                );
            });
        });
    },
    on_error => sub { $err //= $_[0]; EV::break },
);

my $bail = EV::timer(8, 0, sub { EV::break }); EV::run; undef $bail;
$ch->finish;

ok !$insert_err, "tagged query ran without error" or diag $insert_err;
ok $rows && @$rows,
   "system.query_log has an entry for our query_id"
   or diag "err: " . ($err // '') . "; rows: " . ($rows ? scalar @$rows : 'undef');
my $logged = $rows && @$rows ? ($rows->[0][1] // '') : '';
like $logged, qr/\Q$tag\E/,
   "log_comment column contains our query_log_comment tag";
