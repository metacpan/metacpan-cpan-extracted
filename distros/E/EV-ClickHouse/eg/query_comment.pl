#!/usr/bin/env perl
# query_log_comment: prepend a SQL block comment carrying caller / service
# identification to every query. Visible in system.query_log on the
# server side, useful for tracing where load comes from in shared
# clusters. Set to 1 for auto-generated tag, a string for a literal,
# or omit / set falsy to disable.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host              => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port              => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol          => 'native',
    query_log_comment => "service=eg-comment user=$ENV{USER} pid=$$",
    on_connect        => sub {
        # The server receives "/* service=eg-comment user=... pid=N */ select 1"
        # and logs it verbatim into system.query_log when log_queries=1.
        $ch->query("select 1", sub {
            print "Query ran with query_log_comment attached.\n";
            EV::break;
        });
    },
);
EV::run;
$ch->finish;
