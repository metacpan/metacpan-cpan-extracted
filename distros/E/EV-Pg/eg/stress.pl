#!/usr/bin/env perl
# Stress test: sequential queries, pipeline batches, prepared statements,
# COPY IN, reconnect — all in one run.
use strict;
use warnings;
use Time::HiRes qw(time);
use EV;
use EV::Pg;

my $conninfo = shift || $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';

my $N_SEQ       = 10_000;   # sequential query_params
my $N_PIPE      = 50_000;   # pipeline query_params
my $PIPE_BATCH  = 1_000;    # sync every N
my $N_PREP      = 10_000;   # prepared statement executions
my $N_COPY_ROWS = 100_000;  # COPY IN rows

my $t0;

sub report {
    my ($label, $n) = @_;
    my $elapsed = time - $t0;
    printf "  %-28s %6d ops in %.2fs  (%d ops/s)\n",
        $label, $n, $elapsed, $n / ($elapsed || 0.001);
}

my $pg; $pg = EV::Pg->new(
    conninfo => $conninfo,
    on_error => sub { die "connection error: $_[0]\n" },
    on_connect => sub { phase_setup() },
);

sub phase_setup {
    $pg->query("create temp table stress (id int, val text)", sub {
        my (undef, $err) = @_;
        die $err if $err;
        phase_sequential();
    });
}

# --- Phase 1: sequential query_params ---
sub phase_sequential {
    print "phase 1: sequential query_params ($N_SEQ queries)\n";
    my $i = 0;
    $t0 = time;
    my $next; $next = sub {
        my ($rows, $err) = @_;
        die $err if $err;
        if (++$i >= $N_SEQ) {
            report("sequential query_params", $N_SEQ);
            undef $next;
            phase_pipeline();
            return;
        }
        $pg->query_params('select $1::int + 1', [$i], $next);
    };
    $pg->query_params('select $1::int + 1', [0], $next);
}

# --- Phase 2: pipeline query_params ---
sub phase_pipeline {
    print "phase 2: pipeline query_params ($N_PIPE queries, batch $PIPE_BATCH)\n";
    $t0 = time;
    $pg->enter_pipeline;

    for my $i (1 .. $N_PIPE) {
        $pg->query_params('select $1::int', [$i], sub {
            my (undef, $err) = @_;
            die $err if $err;
        });

        if ($i % $PIPE_BATCH == 0 || $i == $N_PIPE) {
            my $is_last = ($i == $N_PIPE);
            $pg->pipeline_sync(sub {
                if ($is_last) {
                    $pg->exit_pipeline;
                    report("pipeline query_params", $N_PIPE);
                    phase_prepared();
                }
            });
        }
    }
}

# --- Phase 3: prepared statement executions ---
sub phase_prepared {
    print "phase 3: prepared statements ($N_PREP executions)\n";
    $pg->prepare('stress_stmt', 'select $1::int * 2', sub {
        my (undef, $err) = @_;
        die $err if $err;

        $t0 = time;
        $pg->enter_pipeline;

        for my $i (1 .. $N_PREP) {
            $pg->query_prepared('stress_stmt', [$i], sub {
                my (undef, $err) = @_;
                die $err if $err;
            });

            if ($i % $PIPE_BATCH == 0 || $i == $N_PREP) {
                my $is_last = ($i == $N_PREP);
                $pg->pipeline_sync(sub {
                    if ($is_last) {
                        $pg->exit_pipeline;
                        report("prepared (pipeline)", $N_PREP);
                        phase_copy();
                    }
                });
            }
        }
    });
}

# --- Phase 4: COPY IN ---
sub phase_copy {
    print "phase 4: COPY IN ($N_COPY_ROWS rows)\n";
    $pg->query("truncate stress", sub {
        my (undef, $err) = @_;
        die $err if $err;

        $t0 = time;
        $pg->query("copy stress from stdin", sub {
            my ($data, $err) = @_;

            if (($data // '') eq 'COPY_IN') {
                for my $i (1 .. $N_COPY_ROWS) {
                    $pg->put_copy_data("$i\trow_$i\n");
                }
                $pg->put_copy_end;
                return;
            }

            die $err if $err;
            report("COPY IN", $N_COPY_ROWS);
            phase_reconnect();
        });
    });
}

# --- Phase 5: reconnect under load ---
sub phase_reconnect {
    print "phase 5: reconnect + sequential queries\n";
    $t0 = time;
    my $reconnects = 0;
    my $queries = 0;
    my $target_reconnects = 5;
    my $queries_per_cycle = 100;

    my $run_cycle; $run_cycle = sub {
        my $q = 0;
        my $next; $next = sub {
            my ($rows, $err) = @_;
            die $err if $err;
            $queries++;
            if (++$q >= $queries_per_cycle) {
                $reconnects++;
                if ($reconnects >= $target_reconnects) {
                    report("reconnect ($target_reconnects x $queries_per_cycle q)", $queries);
                    undef $next;
                    undef $run_cycle;
                    phase_done();
                    return;
                }
                $pg->on_connect(sub {
                    $run_cycle->();
                });
                $pg->reset;
                undef $next;
                return;
            }
            $pg->query_params('select $1::int', [$q], $next);
        };
        $pg->query_params('select 1', [], $next);
    };
    $run_cycle->();
}

sub phase_done {
    print "all phases complete\n";
    $pg->finish;
    EV::break;
}

EV::run;
