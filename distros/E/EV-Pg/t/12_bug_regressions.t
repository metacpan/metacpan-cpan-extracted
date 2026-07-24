use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use POSIX ':sys_wait_h';
use lib 't';
use TestHelper;

require_pg;
plan tests => 12;

# run_isolated($code, $timeout) -> ($status, $child_output)
# Runs $code->($wr) in a forked child with its own EV loop and connection.
# The child prints its observed value(s) to $wr and must return; the harness
# then closes the pipe and POSIX::_exit(0)s.  $status is 'ok' (clean exit 0),
# 'exit:N', 'signal:N' (crash), or 'timeout' (hang; child KILLed).
sub run_isolated {
    my ($code, $timeout) = @_;
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $rd;
        my $rc = eval { $code->($wr); 0 };
        if (!defined $rc) { warn "child error: $@"; $rc = 3; }
        close $wr;    # flush before _exit
        POSIX::_exit($rc);
    }
    close $wr;
    my $deadline = time + $timeout;
    my $status;
    while (1) {
        my $kid = waitpid($pid, WNOHANG);
        if ($kid == $pid) { $status = $?; last; }
        if (time >= $deadline) {
            kill 'KILL', $pid;
            waitpid($pid, 0);
            close $rd;
            return ('timeout', '');
        }
        select(undef, undef, undef, 0.05);
    }
    my $out;
    {
        local $/;
        $out = <$rd>;
    }
    close $rd;
    $out = '' unless defined $out;
    chomp $out;
    if (my $sig = $status & 127) { return ("signal:$sig", $out) }
    my $exit = $status >> 8;
    return ($exit == 0 ? 'ok' : "exit:$exit", $out);
}

# 1. Regression: skip off-by-one misdelivery.  In pipeline mode with a large
# single-row result A, calling skip_pending from A's first-row callback and
# then queueing D must deliver D's OWN result ('DDD'), never 'CCC'
# (pre-fix: D got 'CCC').
{
    my $pg;
    my $skipped = 0;
    my ($d_calls, $d_value) = (0, undef);
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->enter_pipeline;
            $pg->query_params(
                "select repeat('x',200) from generate_series(1,50000)", [], sub {
                my ($r, $e) = @_;
                return if $skipped;
                $skipped = 1;
                $pg->skip_pending;
                $pg->query_params("select 'DDD'::text", [], sub {
                    my ($r2, $e2) = @_;
                    $d_calls++;
                    $d_value = $r2->[0][0] if ref $r2 && @$r2;
                });
                $pg->pipeline_sync(sub { EV::break });
            });
            $pg->set_single_row_mode;
            $pg->query_params("select 'BBB'::text", [], sub { });
            $pg->query_params("select 'CCC'::text", [], sub { });
            $pg->send_flush_request;
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    is($d_calls, 1, 'skip off-by-one: D callback fired exactly once');
    is($d_value, 'DDD', "skip off-by-one: D received its own 'DDD' (pre-fix: 'CCC')");
}

# 2. Regression: COPY-OUT skip livelock.  skip_pending from a COPY_OUT tag
# callback with ~20MB still in flight must not spin at 100% CPU, and the
# connection must recover.  Forked: a livelock regression hangs the process
# where no EV timer can fire, so only a parent-side wall-clock kills it.
{
    my ($st, $out) = run_isolated(sub {
        my $wr = shift;
        my $pg;
        my ($skipped, $alive) = (0, '');
        my $retry;
        $pg = EV::Pg->new(
            conninfo => $conninfo,
            on_connect => sub {
                $pg->enter_pipeline;
                $pg->query_params(
                    "copy (select repeat('x',100) from generate_series(1,200000)) to stdout",
                    [], sub {
                    my ($r, $e) = @_;
                    if (!$skipped && defined $r && !ref $r && $r eq 'COPY_OUT') {
                        $skipped = 1;
                        $pg->skip_pending;
                        # libpq is still in COPY state until the skip drain
                        # finishes in the io watcher; retry queueing 'alive'
                        # until the connection accepts new commands again.
                        $retry = EV::timer(0.05, 0.05, sub {
                            my $ok = eval {
                                $pg->query_params("select 'alive'::text", [], sub {
                                    my ($r2, $e2) = @_;
                                    $alive = $r2->[0][0] if ref $r2 && @$r2;
                                    EV::break;
                                });
                                1;
                            };
                            if ($ok) {
                                undef $retry;
                                $pg->send_flush_request;
                            }
                        });
                    }
                });
                $pg->query_params("select 'after'::text", [], sub { });
                $pg->pipeline_sync(sub { });
            },
            on_error => sub { warn "Error: $_[0]"; EV::break },
        );
        my $t = EV::timer(8, 0, sub { EV::break });
        EV::run;
        print $wr "$alive\n";
    }, 10);
    is($st, 'ok', 'COPY-OUT skip: no livelock (pre-fix: 100% CPU hang)');
    is($out, 'alive', "COPY-OUT skip: connection recovered, 'alive' returned");
}

# 3. Regression: use-after-free on a custom (non-default) loop.  Freeing the
# EV::Loop and then the EV::Pg must not segfault.  Forked: a regression kills
# the process with SIGSEGV, which the parent detects via the wait status.
{
    my ($st, $out) = run_isolated(sub {
        my $wr = shift;
        my $loop = EV::Loop->new;
        my $pg = EV::Pg->new(loop => $loop);
        $pg->on_error(sub { warn "Error: $_[0]"; $loop->break });
        $pg->on_connect(sub { $loop->break });
        $pg->connect($conninfo);
        my $guard = $loop->timer(5, 0, sub { $loop->break });
        $loop->run;
        undef $guard;
        $pg->on_connect(undef);   # drop closure capturing $loop
        $pg->on_error(undef);
        undef $loop;              # ev_loop_destroy; $pg's loop pointer dangles
        undef $pg;                # DESTROY must not touch the freed loop
        print $wr "survived\n";
    }, 10);
    is($st, 'ok', "custom loop UAF: clean exit after undef loop + undef pg (pre-fix: SIGSEGV)");
}

# 4. Regression: re-entrant skip double-count.  A's "skipped" callback
# re-enters skip_pending; queries queued afterwards must each get their OWN
# result.  Forked: pre-fix E was misdelivered and then the connection hung.
{
    my ($st, $out) = run_isolated(sub {
        my $wr = shift;
        my $pg;
        my $reentered = 0;
        my ($e_val, $f_val) = ('', '');
        $pg = EV::Pg->new(
            conninfo => $conninfo,
            on_connect => sub {
                $pg->enter_pipeline;
                $pg->query_params("select 'A'::text", [], sub {
                    my ($r, $e) = @_;
                    if (!$reentered) {
                        $reentered = 1;
                        $pg->skip_pending;    # inner re-entrant skip
                    }
                });
                $pg->query_params("select 'B'::text", [], sub { });
                $pg->query_params("select 'C'::text", [], sub { });
                $pg->skip_pending;            # outer skip over A,B,C
                $pg->query_params("select 'EEE'::text", [], sub {
                    my ($r, $e) = @_;
                    $e_val = $r->[0][0] if ref $r && @$r;
                });
                $pg->query_params("select 'FFF'::text", [], sub {
                    my ($r, $e) = @_;
                    $f_val = $r->[0][0] if ref $r && @$r;
                });
                $pg->pipeline_sync(sub { EV::break });
                $pg->send_flush_request;
            },
            on_error => sub { warn "Error: $_[0]"; EV::break },
        );
        my $t = EV::timer(8, 0, sub { EV::break });
        EV::run;
        print $wr "$e_val $f_val\n";
    }, 10);
    my ($e_got, $f_got) = split ' ', $out;
    is($st, 'ok', 're-entrant skip: no hang (pre-fix: hung after misdelivery)');
    is($e_got, 'EEE', "re-entrant skip: E got its own 'EEE' (pre-fix: 1)");
    is($f_got, 'FFF', "re-entrant skip: F got its own 'FFF'");
}

# 5. Regression: result_meta stale after describe.  describe_prepared must
# refresh result_meta to the described statement (pre-fix: kept the previous
# query's meta).
{
    my $pg;
    my ($pre_nfields, $post_nfields);
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->prepare('ps', "select 1 as x, 2 as y, 3 as z", sub {
                $pg->query_params("select 42 as answer", [], sub {
                    my $m = $pg->result_meta;
                    $pre_nfields = $m->{nfields} if $m;
                    $pg->describe_prepared('ps', sub {
                        my $m2 = $pg->result_meta;
                        $post_nfields = $m2->{nfields} if $m2;
                        EV::break;
                    });
                });
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    is($pre_nfields, 1, 'result_meta: 1-column select gives nfields 1');
    is($post_nfields, 3, "result_meta after describe_prepared is nfields 3 (pre-fix: stale 1)");
}

# 6. Regression: phantom skip credit on reconnect-in-callback.  finish +
# connect inside a skipped callback must not leak a skip credit onto the
# fresh connection that would silently drop Z.  Forked: pre-fix could also
# spin in the drain loop.
{
    my ($st, $out) = run_isolated(sub {
        my $wr = shift;
        my $pg;
        my ($did_skip, $did_reconnect, $z_val) = (0, 0, '');
        $pg = EV::Pg->new(
            conninfo => $conninfo,
            on_connect => sub {
                if (!$did_skip) {
                    $did_skip = 1;
                    $pg->enter_pipeline;
                    $pg->query_params("select 'X'::text", [], sub {
                        my ($r, $e) = @_;
                        if (!$did_reconnect) {
                            $did_reconnect = 1;
                            $pg->finish;
                            $pg->connect($conninfo);
                        }
                    });
                    $pg->query_params("select 'Y'::text", [], sub { });
                    $pg->skip_pending;
                } else {
                    $pg->query_params("select 'ZZZ'::text", [], sub {
                        my ($r, $e) = @_;
                        $z_val = $r->[0][0] if ref $r && @$r;
                        EV::break;
                    });
                }
            },
            on_error => sub { warn "Error: $_[0]"; EV::break },
        );
        my $t = EV::timer(8, 0, sub { EV::break });
        EV::run;
        print $wr "$z_val\n";
    }, 10);
    is($st, 'ok', 'reconnect-in-skip: no drain-loop spin');
    is($out, 'ZZZ', "reconnect-in-skip: Z fired with 'ZZZ' (pre-fix: silently dropped)");
}
