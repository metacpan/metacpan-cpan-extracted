#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use EV;
use EV::Pg qw(:pipeline);

my $conninfo = $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';
my $N        = $ENV{BENCH_N} || 10_000;
my $batch    = $ENV{BENCH_BATCH} || 1000;

my $pg;

sub bench {
    my ($label, $code) = @_;
    my $timeout_sec = ($N > 100_000) ? 120 : 30;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            my $t0 = time;
            $code->(sub {
                my $elapsed = time - $t0;
                printf "  %-34s %d in %.3fs  (%d q/s)\n",
                    $label, $N, $elapsed, $N / $elapsed;
                EV::break;
            });
        },
        on_error => sub { die "error: $_[0]\n" },
    );
    my $timeout = EV::timer($timeout_sec, 0, sub { die "timeout\n" });
    EV::run;
    $pg->finish;
}

# Helper: sequential loop with prepared statement
sub seq_prepared {
    my ($stmt, $sql, $param_cb, $done) = @_;
    $pg->prepare($stmt, $sql, sub {
        my $i = 0;
        my $next; $next = sub {
            if (++$i >= $N) {
                undef $next;
                $done->();
                return;
            }
            $pg->query_prepared($stmt, $param_cb->($i), $next);
        };
        $pg->query_prepared($stmt, $param_cb->(0), $next);
    });
}

# Helper: batched pipeline
sub pipeline_batched {
    my ($sql, $param_cb, $done) = @_;
    $pg->enter_pipeline;
    my $sent = 0;
    my $send_batch; $send_batch = sub {
        my $end = $sent + $batch;
        $end = $N if $end > $N;
        for my $i ($sent .. $end - 1) {
            $pg->query_params($sql, $param_cb->($i), sub {});
        }
        $sent = $end;
        if ($sent >= $N) {
            $pg->pipeline_sync(sub {
                $pg->exit_pipeline;
                undef $send_batch;
                $done->();
            });
        } else {
            $pg->pipeline_sync(sub { $send_batch->() });
        }
        $pg->send_flush_request;
    };
    $send_batch->();
}

print "EV::Pg benchmark — N=$N, batch=$batch\n";
print "libpq ", EV::Pg->lib_version, ", conninfo: $conninfo\n";

# ─── SELECT ───────────────────────────────────────────────
print "\nSELECT (SELECT \$1::int):\n";

bench("sequential", sub {
    my ($done) = @_;
    seq_prepared("s_sel", "select \$1::int", sub { [$_[0]] }, $done);
});

bench("pipeline", sub {
    my ($done) = @_;
    pipeline_batched("select \$1::int", sub { [$_[0]] }, $done);
});

# ─── INSERT ───────────────────────────────────────────────
print "\nINSERT (2 params):\n";

bench("sequential", sub {
    my ($done) = @_;
    $pg->query("create temp table bench_ins (id int, val text)", sub {
        seq_prepared("s_ins",
            "insert into bench_ins values (\$1, \$2)",
            sub { [$_[0], "row_$_[0]"] },
            $done);
    });
});

bench("pipeline", sub {
    my ($done) = @_;
    $pg->query("create temp table bench_ins2 (id int, val text)", sub {
        pipeline_batched(
            "insert into bench_ins2 values (\$1, \$2)",
            sub { [$_[0], "row_$_[0]"] },
            $done);
    });
});

# ─── UPSERT ──────────────────────────────────────────────
print "\nUPSERT (INSERT ... ON CONFLICT):\n";

bench("sequential", sub {
    my ($done) = @_;
    $pg->query("create temp table bench_ups (id int primary key, val text)", sub {
        seq_prepared("s_ups",
            "insert into bench_ups values (\$1, \$2) on conflict (id) do update set val = excluded.val",
            sub { [$_[0] % ($N / 2), "v_$_[0]"] },
            $done);
    });
});

bench("pipeline", sub {
    my ($done) = @_;
    $pg->query("create temp table bench_ups2 (id int primary key, val text)", sub {
        pipeline_batched(
            "insert into bench_ups2 values (\$1, \$2) on conflict (id) do update set val = excluded.val",
            sub { [$_[0] % ($N / 2), "v_$_[0]"] },
            $done);
    });
});

# ─── DBD::Pg comparison ──────────────────────────────────
print "\nDBD::Pg reference:\n";

eval {
    require DBI;
    require DBD::Pg;

    my $dbh = DBI->connect("dbi:Pg:$conninfo", '', '', {
        RaiseError => 1, PrintError => 0,
    });

    # SELECT sync
    {
        my $sth = $dbh->prepare("select \$1::int");
        my $t0 = time;
        for my $i (0 .. $N - 1) {
            $sth->execute($i);
            $sth->fetchrow_arrayref;
        }
        my $elapsed = time - $t0;
        printf "  %-34s %d in %.3fs  (%d q/s)\n",
            "SELECT sync", $N, $elapsed, $N / $elapsed;
        $sth->finish;
    }

    # INSERT sync
    {
        $dbh->do("create temp table bench_dbd_ins (id int, val text)");
        my $sth = $dbh->prepare("insert into bench_dbd_ins values (\$1, \$2)");
        my $t0 = time;
        for my $i (0 .. $N - 1) {
            $sth->execute($i, "row_$i");
        }
        my $elapsed = time - $t0;
        printf "  %-34s %d in %.3fs  (%d q/s)\n",
            "INSERT sync", $N, $elapsed, $N / $elapsed;
        $sth->finish;
    }

    # UPSERT sync
    {
        $dbh->do("create temp table bench_dbd_ups (id int primary key, val text)");
        my $sth = $dbh->prepare(
            "insert into bench_dbd_ups values (\$1, \$2) on conflict (id) do update set val = excluded.val");
        my $t0 = time;
        for my $i (0 .. $N - 1) {
            $sth->execute($i % ($N / 2), "v_$i");
        }
        my $elapsed = time - $t0;
        printf "  %-34s %d in %.3fs  (%d q/s)\n",
            "UPSERT sync", $N, $elapsed, $N / $elapsed;
        $sth->finish;
    }

    # ─── async + EV ─────────────────────────────────────
    print "\nDBD::Pg async + EV:\n";

    my $socket = $dbh->{pg_socket};

    # SELECT async
    {
        my $sth = $dbh->prepare("select \$1::int", {pg_async => DBD::Pg::PG_ASYNC()});
        my $i = 0;
        my $t0 = time;
        $sth->execute($i);
        my $w; $w = EV::io($socket, EV::READ, sub {
            $dbh->pg_result;
            $sth->fetchrow_arrayref;
            if (++$i >= $N) {
                undef $w;
                my $elapsed = time - $t0;
                printf "  %-34s %d in %.3fs  (%d q/s)\n",
                    "SELECT async+EV", $N, $elapsed, $N / $elapsed;
                EV::break;
                return;
            }
            $sth->execute($i);
        });
        EV::run;
        $sth->finish;
    }

    # INSERT async
    {
        $dbh->do("create temp table bench_dbd_ins2 (id int, val text)");
        my $sth = $dbh->prepare(
            "insert into bench_dbd_ins2 values (\$1, \$2)",
            {pg_async => DBD::Pg::PG_ASYNC()});
        my $i = 0;
        my $t0 = time;
        $sth->execute($i, "row_$i");
        my $w; $w = EV::io($socket, EV::READ, sub {
            $dbh->pg_result;
            if (++$i >= $N) {
                undef $w;
                my $elapsed = time - $t0;
                printf "  %-34s %d in %.3fs  (%d q/s)\n",
                    "INSERT async+EV", $N, $elapsed, $N / $elapsed;
                EV::break;
                return;
            }
            $sth->execute($i, "row_$i");
        });
        EV::run;
        $sth->finish;
    }

    # UPSERT async
    {
        $dbh->do("create temp table bench_dbd_ups2 (id int primary key, val text)");
        my $sth = $dbh->prepare(
            "insert into bench_dbd_ups2 values (\$1, \$2) on conflict (id) do update set val = excluded.val",
            {pg_async => DBD::Pg::PG_ASYNC()});
        my $i = 0;
        my $t0 = time;
        $sth->execute($i % ($N / 2), "v_$i");
        my $w; $w = EV::io($socket, EV::READ, sub {
            $dbh->pg_result;
            if (++$i >= $N) {
                undef $w;
                my $elapsed = time - $t0;
                printf "  %-34s %d in %.3fs  (%d q/s)\n",
                    "UPSERT async+EV", $N, $elapsed, $N / $elapsed;
                EV::break;
                return;
            }
            $sth->execute($i % ($N / 2), "v_$i");
        });
        EV::run;
        $sth->finish;
    }

    $dbh->disconnect;
};
if ($@) {
    if ($@ =~ /locate|Can't load/) {
        print "  DBD::Pg not available, skipping\n";
    } else {
        print "  DBD::Pg error: $@\n";
    }
}
