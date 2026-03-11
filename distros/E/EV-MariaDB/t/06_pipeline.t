use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 13;
use EV;
use EV::MariaDB;

my $m;

sub with_mariadb {
    my ($cb) = @_;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}

# Test 1: Queue multiple queries, verify all complete in order
with_mariadb(sub {
    my @results;
    my $N = 5;
    for my $i (1..$N) {
        $m->q("select $i as v", sub {
            my ($rows, $err) = @_;
            push @results, $rows->[0][0];
            if (@results == $N) {
                is_deeply(\@results, [1,2,3,4,5], 'pipeline: 5 queries complete in order');
                EV::break;
            }
        });
    }
});

# Test 2: Queue queries from within callbacks (chain queueing)
with_mariadb(sub {
    my @results;
    $m->q("select 'a'", sub {
        my ($rows) = @_;
        push @results, $rows->[0][0];
        # queue more from callback
        $m->q("select 'b'", sub {
            my ($rows) = @_;
            push @results, $rows->[0][0];
        });
        $m->q("select 'c'", sub {
            my ($rows) = @_;
            push @results, $rows->[0][0];
            is_deeply(\@results, ['a','b','c'], 'pipeline: chain-queued queries complete in order');
            EV::break;
        });
    });
});

# Test 3: Mix of DML and select
with_mariadb(sub {
    my @results;
    $m->q("do 1", sub {
        my ($aff, $err) = @_;
        push @results, "dml:$aff";
    });
    $m->q("select 42 as v", sub {
        my ($rows, $err) = @_;
        push @results, "sel:$rows->[0][0]";
    });
    $m->q("do 2", sub {
        my ($aff, $err) = @_;
        push @results, "dml:$aff";
        is_deeply(\@results, ['dml:0','sel:42','dml:0'], 'pipeline: mixed DML and select');
        EV::break;
    });
});

# Test 4: pending_count tracks correctly
with_mariadb(sub {
    my $initial = $m->pending_count;
    is($initial, 0, 'pipeline: pending_count starts at 0');

    $m->q("select 1", sub {});
    $m->q("select 2", sub {});
    $m->q("select 3", sub {
        is($m->pending_count, 0, 'pipeline: pending_count is 0 after last callback');
        EV::break;
    });

    my $after_queue = $m->pending_count;
    ok($after_queue > 0, "pipeline: pending_count > 0 after queuing ($after_queue)");
});

# Test 5: Queue during connection
{
    my @results;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {},
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );

    # queue before connected
    $m->q("select 'early1'", sub {
        my ($rows) = @_;
        push @results, $rows->[0][0];
    });
    $m->q("select 'early2'", sub {
        my ($rows) = @_;
        push @results, $rows->[0][0];
        is_deeply(\@results, ['early1','early2'], 'pipeline: queries queued during connect');
        EV::break;
    });

    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}

# Test 6: Multiple pipelined queries complete in order
with_mariadb(sub {
    my @results;
    $m->q("select 'ok1'", sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : "ok:$rows->[0][0]";
    });
    $m->q("select 'ok2'", sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : "ok:$rows->[0][0]";
        is($results[0], 'ok:ok1', 'pipeline: first query ok');
        is($results[1], 'ok:ok2', 'pipeline: second query ok');
        EV::break;
    });
});

# Test 7: Many queries (stress test)
with_mariadb(sub {
    my $N = 100;
    my $done = 0;
    my $ok = 1;
    for my $i (1..$N) {
        $m->q("select $i", sub {
            my ($rows, $err) = @_;
            if ($err) {
                diag("pipeline stress: error at $i: $err");
                $ok = 0;
            }
            elsif ($rows->[0][0] ne "$i") {
                diag("pipeline stress: expected $i got $rows->[0][0]");
                $ok = 0;
            }
            if (++$done >= $N) {
                ok($ok, "pipeline: 100 queries all correct");
                is($done, $N, "pipeline: all 100 completed");
                EV::break;
            }
        });
    }
});

# Test 8: skip_pending cancels queued queries (cancelled cbs get error)
with_mariadb(sub {
    my @results;
    $m->q("select 1", sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : "ok";
        # cancel remaining — their callbacks fire with (undef, "skipped")
        $m->skip_pending;
    });
    $m->q("select 2", sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : "ok";
        # this runs as part of skip_pending
    });
    $m->q("select 3", sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : "ok";
        is_deeply(\@results, ['ok', 'err:skipped', 'err:skipped'],
            'pipeline: skip_pending cancels remaining with error');
        is($m->pending_count, 0, 'pipeline: pending_count 0 after skip');
        EV::break;
    });
});
