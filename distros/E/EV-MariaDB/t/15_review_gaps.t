use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 6;
use EV;
use EV::MariaDB;

# --- query() is rejected while a stream is active -------------------------
# query_stream is exclusive: "No other queries can be queued while streaming
# is active." Verify the guard actually croaks.
{
    my $m; my $croaked = 0;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            $m->query_stream("select 1 union all select 2", sub {
                my ($row, $err) = @_;
                return if $err;
                if (!defined $row) { EV::break; return }
                my $ok = eval { $m->query("select 99", sub { }); 1 };
                $croaked++ if !$ok && $@ =~ /cannot queue query/;
            });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
    ok($croaked, 'query() croaks while a stream is active');
}

# --- skip_pending from inside a stream row callback -----------------------
# Documents the intentional behaviour: the row callback you are *inside* is
# not re-invoked with "skipped" (that would be a re-entrant double-fire);
# skip_pending closes the connection because a stream is in flight; there is
# no crash and the object stays reusable via reset().
{
    my $m; my @rows; my $terminal = 0; my $connected_after = 1;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            my $n = 0;
            $m->query_stream(
                "select 1 as x union all select 2 union all select 3", sub {
                    my ($row, $err) = @_;
                    if ($err || !defined $row) { $terminal++; return }
                    push @rows, $row->[0];
                    if (++$n == 1) {
                        $m->skip_pending;
                        $connected_after = $m->is_connected ? 1 : 0;
                        EV::break;
                    }
                });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    is_deeply(\@rows, [1], 'only the first row delivered before skip_pending');
    is($terminal, 0,
        'the in-flight stream callback is not re-invoked from inside itself');
    is($connected_after, 0,
        'skip_pending closed the connection for the in-flight stream');
    ok(!$m->is_connected, 'still disconnected after skip_pending');
    my $reset_ok = eval { $m->reset; 1 };
    ok($reset_ok, 'object stays reusable: reset() succeeds after skip_pending');
    $m->finish if $m->is_connected;
}
