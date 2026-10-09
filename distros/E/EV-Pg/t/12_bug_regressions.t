use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use POSIX ':sys_wait_h';
use IO::Socket::INET;
use IO::Socket::UNIX;
use Socket qw(SOL_SOCKET SO_SNDBUF);
use lib 't';
use TestHelper qw(with_pg require_pg $conninfo run_isolated);

require_pg;
plan tests => 82;

# run_perl($code, \%env) -> ($status, '')
# Runs $code in a fresh perl (same @INC), for crashes that only show at
# process start (MALLOC_PERTURB_) or exit (global destruction).
sub run_perl {
    my ($code, $env) = @_;
    return run_isolated(sub {
        %ENV = (%ENV, %{ $env || {} });
        exec($^X, (map { "-I$_" } @INC), '-e', $code) or die "exec: $!";
    }, 20);
}

# 1. Regression: skip off-by-one misdelivery.  In pipeline mode with a large
# single-row result A, calling skip_pending from A's first-row callback and
# then queueing D must deliver D's OWN result ('DDD'), never 'CCC'
# (pre-fix: D got 'CCC').
SKIP: {
    skip 'requires libpq >= 14', 2 unless EV::Pg->can('send_flush_request');
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
SKIP: {
    skip 'requires libpq >= 14', 2 unless EV::Pg->can('send_flush_request');
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
SKIP: {
    skip 'requires libpq >= 14', 3 unless EV::Pg->can('send_flush_request');
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

# 7. Regression: destroy inside on_notice.  The notice handler runs from
# inside libpq, so DESTROY must defer PQfinish until libpq returns
# (pre-fix: heap use-after-free, silent natively -- pinned under
# valgrind by t/05).  Pinned here: clean exit plus a working followup.
{
    my $pg;
    my ($notices, $followup) = (0, '');
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_notice => sub {
            $notices++;
            undef $pg;
        },
        on_connect => sub {
            $pg->query("do \$\$ begin raise notice 'bye'; end \$\$", sub {
                EV::break;
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    my $pg2;
    $pg2 = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg2->query_params("select 'ok'::text", [], sub {
                my ($r, $e) = @_;
                $followup = $r->[0][0] if ref $r && @$r;
                EV::break;
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t2 = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $pg2->finish if $pg2->is_connected;
    ok(!defined $pg && $notices >= 1, 'destroy in on_notice: fired, object gone, clean exit');
    is($followup, 'ok', 'destroy in on_notice: followup connection works');
}

# 8. Regression: reset() inside on_notice during the handshake.  A notice
# can arrive mid-handshake; the reset swaps the conn under the in-flight
# PQconnectPoll, and the stale status must not drive the new conn
# (pre-fix: premature on_connect with is_connected=0, wedged conn).
# A TCP proxy injects a NoticeResponse into the startup flight.
# Forked: pre-fix wedges (parent timeout).
SKIP: {
    my ($host, $port, $db);
    with_pg(cb => sub {
        my ($pg) = @_;
        ($host, $port, $db) = ($pg->host, $pg->port, $pg->db);
        EV::break;
    });
    skip 'cannot determine server host/port', 2
        unless defined $host && length $host && $port && defined $db;
    my ($st, $out) = run_isolated(sub {
        my ($wr) = @_;
        my $lsn = IO::Socket::INET->new(LocalAddr => '127.0.0.1:0',
            Listen => 5, ReuseAddr => 1) or die "listen: $!";
        my $pxport = $lsn->sockport;
        $lsn->blocking(0);
        my $lw; $lw = EV::io($lsn, EV::READ, sub {
            my $c = $lsn->accept or return;
            $c->blocking(0);
            my $s = $host =~ m{^/}
                ? IO::Socket::UNIX->new(Peer => "$host/.s.PGSQL.$port")
                : IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port);
            $s or return;
            $s->blocking(0);
            my ($sbuf, $inj) = ('', 0);
            my ($wc, $ws);
            $wc = EV::io($c, EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                unless ($n) { undef $wc; undef $ws; return; }
                syswrite($s, $chunk);
            });
            $ws = EV::io($s, EV::READ, sub {
                my $n = sysread($s, my $chunk, 65536);
                unless ($n) { undef $wc; undef $ws; return; }
                if (!$inj) {
                    $sbuf .= $chunk;
                    my ($o, $r, $f) = ('', $sbuf, 0);
                    while (length($r) >= 5) {
                        my ($t, $len) = (substr($r, 0, 1),
                                         unpack('N', substr($r, 1, 4)));
                        last if $len < 4 || length($r) < 1 + $len;
                        my $rec = substr($r, 0, 1 + $len, '');
                        if ($t eq 'Z' && !$f) {
                            my $fld = "SNOTICE\0Mstartup-note\0\0";
                            $o .= 'N' . pack('N', 4 + length($fld)) . $fld;
                            $f = 1;
                        }
                        $o .= $rec;
                    }
                    if ($f) { syswrite($c, $o . $r); $sbuf = ''; $inj = 1; }
                    else { $sbuf = $o . $r; }
                } else {
                    syswrite($c, $chunk);
                }
            });
        });
        my ($did, $val) = (0, '');
        my $pg;
        $pg = EV::Pg->new(
            conninfo => "host=127.0.0.1 port=$pxport dbname=$db sslmode=disable",
            on_notice => sub {
                if (!$did) { $did = 1; $pg->reset; }
            },
            on_connect => sub {
                $val .= $pg->is_connected ? 'C' : 'c';
                $pg->query_params("select 'q'::text", [], sub {
                    my ($r, $e) = @_;
                    $val .= ($e ? 'E' : 'Q');
                    EV::break;
                });
            },
            on_error => sub { $val .= '!'; EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        print $wr "did=$did val=$val";
    }, 25);
    is($st, 'ok', 'handshake-notice reset: no wedge (pre-fix: timeout)');
    is($out, 'did=1 val=CQ', 'handshake-notice reset: reconnected, query works');
}

# 9. Regression: nested EV::run inside a query callback.  The nested
# run must not reenter result dispatch (pre-fix: misdelivery, then a
# 100% CPU hang once nested delivery advanced the outer entry), nor
# busy-loop while the deferred result sits on the socket.
# Forked: pre-fix hangs (parent timeout).
{
    my ($st, $out) = run_isolated(sub {
        my ($wr) = @_;
        my ($q1n, $q1v, $q2n, $s1n, $s2n, $iters) = (0, '', 0, 0, 0, 0);
        my $pg;
        $pg = EV::Pg->new(
            conninfo => $conninfo,
            on_connect => sub {
                $pg->enter_pipeline;
                $pg->query_params("select 'Q1'::text", [], sub {
                    my ($r, $e) = @_;
                    $q1n++;
                    $q1v = $r->[0][0] if ref $r && @$r;
                    $pg->query_params("select pg_sleep(0.3)", [], sub { $q2n++ });
                    $pg->pipeline_sync(sub { $s2n++; EV::break });
                    my $nt = EV::timer(1.0, 0, sub { EV::break });
                    my $count = EV::prepare(sub { $iters++ });
                    EV::run;
                });
                $pg->pipeline_sync(sub { $s1n++ });
            },
            on_error => sub { EV::break },
        );
        my $t = EV::timer(8, 0, sub { EV::break });
        EV::run;
        my $spin = $iters > 1000 ? "spin($iters)" : 'idle';
        print $wr "q1=$q1n:$q1v q2=$q2n s1=$s1n s2=$s2n $spin";
    }, 20);
    is($st, 'ok', 'nested run: no hang (pre-fix: timeout)');
    is($out, 'q1=1:Q1 q2=1 s1=1 s2=1 idle', 'nested run: delivery intact, no busy loop');
}

# 9b. Nested EV::run outside result dispatch (on_connect) may wait for a
# query result, as it could before the nested-run guard existed.
{
    my ($st, $out) = run_isolated(sub {
        my ($wr) = @_;
        my $got = 'none';
        my $pg;
        $pg = EV::Pg->new(
            conninfo => $conninfo,
            on_connect => sub {
                $pg->query("select 42", sub { $got = $_[0][0][0]; EV::break });
                my $nt = EV::timer(5, 0, sub { EV::break });
                EV::run;
                EV::break;
            },
            on_error => sub { EV::break },
        );
        my $t = EV::timer(8, 0, sub { EV::break });
        EV::run;
        print $wr "got=$got";
    }, 20);
    is($st, 'ok', 'nested run in on_connect: no hang');
    is($out, 'got=42', 'nested run in on_connect: result delivered');
}

# 10. COPY OUT is event-driven: the COPY_OUT callback re-fires as data
# arrives, so draining to undef each time must complete the stream.
{
    my $pg;
    my ($rows, $final) = (0, '');
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->query("copy (select repeat('x',100) from generate_series(1,200000)) to stdout", sub {
                my ($data, $err) = @_;
                if (defined $data && !ref($data) && $data eq 'COPY_OUT') {
                    while (defined(my $line = $pg->get_copy_data)) {
                        last if $line eq '-1';
                        $rows++;
                    }
                    return;
                }
                $final = $err ? "ERR:$err" : $data;
                EV::break;
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(20, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    is($rows, 200000, 'COPY OUT: event-driven drain reads every row');
    is($final, '200000', 'COPY OUT: final cmd_tuples delivered');
}

# 10b. Regression: COPY IN tag fires once.  Server notices arriving while
# the app paces its rows must not re-run the COPY_IN callback (pre-fix:
# one tag per io event, so a callback that sends on each tag duplicated rows).
{
    my $pg;
    my ($tags, $final, $end) = (0, '');
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_notice => sub { },
        on_connect => sub {
            $pg->query(q{
                create temp table copy_in_tag (v int);
                create function pg_temp.copy_in_tag_note() returns trigger
                    language plpgsql as $$ begin raise notice 'row %', new.v; return new; end $$;
                create trigger copy_in_tag_note before insert on copy_in_tag
                    for each row execute procedure pg_temp.copy_in_tag_note();
            }, sub {
                $pg->query('copy copy_in_tag from stdin', sub {
                    my ($data, $err) = @_;
                    if (defined $data && !ref($data) && $data eq 'COPY_IN') {
                        $tags++;
                        $pg->put_copy_data("$_\n") for 1 .. 5;
                        $end = EV::timer(0.3, 0, sub { $pg->put_copy_end });
                        return;
                    }
                    $final = $err ? "ERR:$err" : $data;
                    EV::break;
                });
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    is($tags, 1, 'COPY IN: tag fired once despite notices');
    is($final, '5', 'COPY IN: exactly the sent rows were copied');
}

# 11. Regression: skipped COPY OUT + in-callback requeue misdelivery.
# Drain the stream to -1 in the tag callback, skip_pending, then queue C+S2
# synchronously: C must get its own rows and S2 must fire exactly once
# (pre-fix: C got S1's stale sync, S2 fired twice with C's rows then (1)).
{
    my ($c_calls, $c_value, $s2_calls) = (0, undef, 0);
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->enter_pipeline;
            $pg->query_params("copy (select 'x'::text) to stdout", [], sub {
                my ($r, $e) = @_;
                return unless defined $r && !ref $r && $r eq 'COPY_OUT';
                while (1) {
                    my $d = $pg->get_copy_data;
                    last if !defined $d;
                    last if $d eq '-1';
                }
                $pg->skip_pending;
                $pg->query_params("select 'CCC'::text", [], sub {
                    my ($r2, $e2) = @_;
                    $c_calls++;
                    $c_value = $e2 ? "ERR:$e2"
                        : (ref $r2 ? $r2->[0][0] : "SCALAR:$r2");
                });
                $pg->pipeline_sync(sub {
                    $s2_calls++;
                    EV::break;
                });
            });
            $pg->query_params("select 'BBB'::text", [], sub { });
            $pg->pipeline_sync(sub { });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    is($c_calls, 1, 'copy-skip requeue: C fired exactly once');
    is($c_value, 'CCC', "copy-skip requeue: C got its own rows (pre-fix: '1')");
    is($s2_calls, 1, 'copy-skip requeue: S2 fired exactly once (pre-fix: twice)');
}

# 12. Regression: fork safety, explicit destroy.  A child that destroys its
# inherited copy must not break the parent's connection, and the parent's
# queued callbacks must still deliver real results (not "object destroyed").
# (pre-fix: parent got "server closed the connection unexpectedly").
{
    pipe(my $rd, my $wr) or die "pipe: $!";
    my ($q1_calls, $q1_value, $q2_value, $err) = (0, undef, undef, '');
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->query("select 'Q1'::text", sub {
                my ($r, $e) = @_;
                $q1_calls++;
                $q1_value = $e ? "ERR:$e" : $r->[0][0];
                $pg->query("select 'Q2'::text", sub {
                    my ($r2, $e2) = @_;
                    $q2_value = $e2 ? "ERR:$e2" : $r2->[0][0];
                    EV::break;
                });
            });
            my $pid = fork();
            die "fork: $!" unless defined $pid;
            if ($pid == 0) {
                close $rd;
                undef $pg;
                print $wr defined($q1_value) ? "CHILD-SAW:$q1_value" : 'CHILD-SILENT';
                close $wr;
                POSIX::_exit(0);
            }
            close $wr;
            waitpid($pid, 0);
        },
        on_error => sub { $err .= $_[0]; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    my $child_said = do { local $/; <$rd> };
    close $rd;
    $pg->finish if $pg->is_connected;
    is($err, '', 'fork undef: parent saw no error');
    is($q1_calls, 1, 'fork undef: pre-fork query fired exactly once');
    is($q1_value, 'Q1', 'fork undef: pre-fork query delivered with rows');
    is($q2_value, 'Q2', 'fork undef: post-fork query works');
    is($child_said, 'CHILD-SILENT', 'fork undef: child dropped queue silently');
}

# 13. Regression: fork safety, global destruction.  A child that plain
# exit()s runs DESTROY on its inherited copy via global destruction;
# the parent must survive that too.
{
    my ($q_value, $err) = (undef, '');
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            my $pid = fork();
            die "fork: $!" unless defined $pid;
            if ($pid == 0) { exit(0); }
            waitpid($pid, 0);
            $pg->query("select 'QF'::text", sub {
                my ($r, $e) = @_;
                $q_value = $e ? "ERR:$e" : $r->[0][0];
                EV::break;
            });
        },
        on_error => sub { $err .= $_[0]; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    is($err, '', 'fork exit: parent saw no error');
    is($q_value, 'QF', 'fork exit: parent query works');
}

# 14. Fork teardown contract.  finish() in the child is safe for the parent,
# and connect() on the inherited object croaks loudly instead of building a
# silently broken connection on a fork-copied loop.  Forks at top level so
# the child's finish takes the immediate-PQfinish path (pre-fix: dead parent).
{
    pipe(my $rd, my $wr) or die "pipe: $!";
    my ($q_value, $err) = (undef, '');
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub { EV::break },
        on_error => sub { $err .= $_[0]; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $rd;
        my $send = eval { $pg->query("select 999", sub { }); 'SENT' };
        $send = "CROAK:$@" if $@;
        print $wr "send:$send\n";
        my $live = eval { $pg->connect($conninfo); 'NO-CROAK' };
        $live = "CROAK:$@" if $@;
        print $wr "conn-live:$live\n";
        my $enc = eval { $pg->set_client_encoding('LATIN1'); 'NO-CROAK' };
        $enc = "CROAK:$@" if $@;
        print $wr "enc:$enc\n";
        $pg->finish;
        my $croak = eval { $pg->connect($conninfo); 'NO-CROAK' };
        $croak = "CROAK:$@" if $@;
        print $wr "conn:$croak\n";
        close $wr;
        POSIX::_exit(0);
    }
    close $wr;
    waitpid($pid, 0);
    $pg->query("select 'QP'::text", sub {
        my ($r, $e) = @_;
        $q_value = $e ? "ERR:$e" : $r->[0][0];
        EV::break;
    });
    $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    my $child_said = do { local $/; <$rd> };
    close $rd;
    $pg->finish if $pg->is_connected;
    like($child_said, qr/another process/, 'fork finish: connect in child croaks');
    like($child_said, qr/^send:CROAK:object created in another process/m,
        'fork send: query in child croaks instead of misdelivering');
    like($child_said, qr/^conn-live:CROAK:object created in another process/m,
        'fork connect: connect on live inherited conn names the real problem');
    like($child_said, qr/^enc:CROAK:object created in another process/m,
        'fork encoding: blocking set_client_encoding in child croaks');
    is($err, '', 'fork finish: parent saw no error');
    is($q_value, 'QP', 'fork finish: parent query works');
}

# 14b. A child that undefs its inherited copy and then runs its own loop
# must not keep watching the shared socket (pre-fix: freed watcher left in
# the child's loop, which busy-looped on the parent's pending result).
{
    pipe(my $rd, my $wr) or die "pipe: $!";
    my ($q_value, $err) = (undef, '');
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub { EV::break },
        on_error => sub { $err .= $_[0]; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg->query("select pg_sleep(0.1), 'QC'::text", sub {
        my ($r, $e) = @_;
        $q_value = $e ? "ERR:$e" : $r->[0][1];
        EV::break;
    });
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $rd;
        undef $pg;
        my $iters = 0;
        my $count = EV::prepare(sub { $iters++ });
        my $stop = EV::timer(0.5, 0, sub { EV::break });
        EV::run;
        print $wr $iters > 1000 ? "spin($iters)" : 'idle';
        close $wr;
        POSIX::_exit(0);
    }
    close $wr;
    select(undef, undef, undef, 0.3);
    $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    waitpid($pid, 0);
    my $child_said = do { local $/; <$rd> };
    close $rd;
    $pg->finish if $pg->is_connected;
    is($child_said, 'idle', 'fork undef+run: child loop ignores the shared socket');
    is($q_value, 'QC', 'fork undef+run: parent still gets its result');
}

# 14c. Regression: a fork child destroying an object with cancel_async in
# flight must not touch the (nulled) loop (pre-fix: child SIGSEGV).
SKIP: {
    skip 'cancel_async needs libpq >= 17', 1 unless EV::Pg->can('cancel_async');
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub { EV::break },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg->query("select pg_sleep(0.5)", sub { });
    $pg->cancel_async(sub { });
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) { undef $pg; POSIX::_exit(0); }
    waitpid($pid, 0);
    is($?, 0, 'fork undef with cancel in flight: child exits cleanly');
    $t = EV::timer(5, 0, sub { EV::break });
    my $done = EV::timer(0.05, 0.05, sub { EV::break unless $pg->pending_count });
    EV::run;
    $pg->finish if $pg->is_connected;
}

# 14d. Regression: objects on a custom loop that outlive it into global
# destruction must not stop watchers on the freed loop (pre-fix: SIGSEGV
# at exit).
{
    my ($st) = run_perl(q{
        use EV; use EV::Pg;
        our $loop = EV::Loop->new; our @objs;
        for (1 .. 3) {
            my $pg; $pg = EV::Pg->new(conninfo => $ENV{TEST_PG_CONNINFO},
                loop => $loop, on_connect => sub { $loop->break });
            push @objs, $pg; $loop->run;
        }
    });
    is($st, 'ok', 'custom loop at global destruction: clean exit');
}

# 14e. Regression: finish (or destroy) from on_notice on a conn opened while
# an older closed conn was still deferred must not free the conn libpq is
# reading (pre-fix: use-after-free; MALLOC_PERTURB_ turns it into SIGSEGV).
for my $how (qw(finish destroy)) {
    my ($st) = run_perl(q{
        use EV; use EV::Pg;
        my $how = $ENV{EV_PG_HOW};
        my ($pg, $stage) = (undef, 0);
        $pg = EV::Pg->new(conninfo => $ENV{TEST_PG_CONNINFO},
            on_notice => sub {
                return unless $stage == 2;
                $stage = 3;
                if ($how eq 'destroy') { undef $pg } else { $pg->finish }
            },
            on_connect => sub {
                if ($stage == 0) {
                    $stage = 1;
                    $pg->reset;
                    my $t = EV::timer(5, 0, sub { EV::break });
                    EV::run;
                    EV::break;
                }
                elsif ($stage == 1) {
                    $stage = 2;
                    $pg->query(q{do $$ begin raise notice 'n'; end $$}, sub { EV::break });
                }
            });
        EV::run;
        exit($stage == 3 ? 0 : 1);
    } . "\n", { MALLOC_PERTURB_ => 165, EV_PG_HOW => $how });
    is($st, 'ok', "on_notice $how after deferred close: no use-after-free");
}

# 15. Notice-driven finish/reset mid-COPY-drain.  skip_pending from a COPY tag
# starts an internal drain; a NOTICE parsed mid-drain that runs finish/reset
# must stop the drain without a spurious on_error, and (for reset) without
# tearing down the fresh connection.
# (pre-fix finish: on_error "connection pointer is NULL";
#  pre-fix reset: on_error "no COPY in progress" + dead fresh conn).
for my $action (qw(finish reset)) {
    # Several cheap rounds: whether the armed notice lands inside the drain
    # loop depends on server flush timing (~4/5 per round), so one round can
    # pass vacuously on buggy code; all rounds pass on fixed code.
    my @all_errors;
    my $bad_first = 0;
    for my $round (1..4) {
        my (@errors, $first, $tag);
        my $armed = 0;
        my $pg;
        $pg = EV::Pg->new(
            conninfo => $conninfo,
            on_notice => sub {
                return unless $armed;
                $armed = 0;
                if ($action eq 'finish') {
                    $pg->finish;
                    my $rt; $rt = EV::timer(0.5, 0, sub {
                        undef $rt;
                        $pg->connect($conninfo);
                    });
                } else {
                    $pg->reset;
                }
            },
            on_connect => sub {
                if (($tag // '') eq 'done') {
                    $pg->query_params("select 'FIRST'::text", [], sub {
                        my ($r, $e) = @_;
                        $first = $e ? "ERR:$e" : $r->[0][0];
                        EV::break;
                    });
                    return;
                }
                my $setup_sql = <<'SQL';
create or replace function pg_temp.noisy(g int) returns text as $$
begin raise notice 'n-%', g; return 'x'; end; $$ language plpgsql
SQL
                $pg->query($setup_sql, sub {
                    die "setup failed: $_[1]" if $_[1];
                    $pg->enter_pipeline;
                    $pg->query_params(
                        "copy (select pg_temp.noisy(g) from generate_series(1,500) g) to stdout",
                        [], sub {
                            my ($r, $e) = @_;
                            return unless defined $r && !ref $r && $r eq 'COPY_OUT';
                            $tag = 'done';
                            $pg->skip_pending;
                            $armed = 1;
                        });
                    $pg->query_params("select 'after'::text", [], sub { });
                    $pg->pipeline_sync(sub { });
                });
            },
            on_error => sub { push @errors, $_[0] },
        );
        my $t = EV::timer(10, 0, sub { push @errors, 'TIMEOUT'; EV::break });
        EV::run;
        $pg->finish if $pg->is_connected;
        push @all_errors, map { "r$round:$_" } @errors;
        $bad_first++ unless defined $first && $first eq 'FIRST';
    }
    is(scalar @all_errors, 0, "drain-$action: no spurious on_error (@all_errors)");
    is($bad_first, 0, "drain-$action: reconnected and query works every round");
}

# 16. keep_alive core: a timer-less loop with an idle connection must stay
# alive iff keep_alive is set.  (The t/08 test keeps a 5s timer armed, so it
# cannot catch a loop-liveness regression.)  Liveness is observed from the
# parent: the child either exits at once (broken/off) or runs until KILLed.
for my $ka (1, 0) {
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $pg;
        $pg = EV::Pg->new(
            conninfo   => $conninfo,
            keep_alive => $ka,
            on_connect => sub { },  # queue stays empty
            on_error   => sub { POSIX::_exit(2) },
        );
        EV::run;  # no timers: returns at once unless keep_alive holds it
        POSIX::_exit(0);
    }
    sleep 2;
    my $alive = (waitpid($pid, WNOHANG) == 0);
    if ($alive) { kill 'KILL', $pid; waitpid($pid, 0); }
    if ($ka) {
        ok($alive, 'keep_alive core: idle timer-less loop stays alive');
    } else {
        ok(!$alive, 'keep_alive off: idle timer-less loop exits (control)');
    }
}

with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select pg_sleep(0.05), 'pending'::text", sub {
        my ($rows, $err) = @_;
        is($err, undef, 'password lookup leaves pending query error-free');
        is($rows->[0][1], 'pending', 'password lookup preserves pending query result');
        EV::break;
    });
    eval { $pg->encrypt_password('testpass', 'testuser') };
    like($@, qr/encrypt_password:.*pending queries/, 'default password lookup rejects pending queries');
    like($pg->encrypt_password('testpass', 'testuser', 'md5'), qr/^md5/,
        'explicit password algorithm works with pending queries');
});

{
    my $retry;
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->query("select pg_sleep(0.05)", sub {
            eval { $pg->set_client_encoding('UTF8') };
            like($@, qr/pending queries/, 'encoding rejects undrained query inside skipped callback');
            eval { $pg->encrypt_password('testpass', 'testuser') };
            like($@, qr/pending queries/, 'password lookup rejects undrained query inside skipped callback');
        });
        $pg->skip_pending;
        eval { $pg->set_client_encoding('UTF8') };
        like($@, qr/pending queries/, 'encoding rejects undrained skipped query');
        eval { $pg->encrypt_password('testpass', 'testuser') };
        like($@, qr/pending queries/, 'password lookup rejects undrained skipped query');
        $retry = EV::timer(0.01, 0.01, sub {
            return unless eval { $pg->set_client_encoding('UTF8'); 1 };
            undef $retry;
            $pg->query("select 'after'::text", sub {
                my ($rows, $err) = @_;
                is($err ? "ERR:$err" : $rows->[0][0], 'after',
                    'connection usable after skipped query drains');
                EV::break;
            });
        });
    });
    undef $retry;
}

with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query('create temp table release_copy (value text)', sub {
        $pg->query('copy release_copy from stdin', sub {
            return unless defined $_[0] && $_[0] eq 'COPY_IN';
            $pg->skip_pending;
            eval { $pg->set_client_encoding('UTF8') };
            like($@, qr/pending queries/, 'encoding rejects active skipped COPY');
            eval { $pg->encrypt_password('testpass', 'testuser') };
            like($@, qr/pending queries/, 'password lookup rejects active skipped COPY');
            $pg->put_copy_end('skipped');
            EV::break;
        });
    });
});

# Blocking helpers must finish notice-driven teardown before returning.
SKIP: {
    my $superuser;
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->query("select rolsuper from pg_roles where rolname = current_user", sub {
            $superuser = ref $_[0] && $_[0][0][0] eq 't';
            EV::break;
        });
    });
    skip 'needs superuser for log_statement notices', 8 unless $superuser;
    for my $method (qw(set_client_encoding encrypt_password)) {
        for my $how (qw(finish destroy)) {
            my (@retained, $count);
            my $notices = 0;
            my $app = "evpg_notice_${method}_${how}_$$";
            for (1 .. 3) {
                my $pg;
                $pg = EV::Pg->new(
                    conninfo => "$conninfo application_name=$app",
                    on_connect => sub { EV::break },
                    on_error => sub { EV::break },
                );
                my $t = EV::timer(5, 0, sub { EV::break });
                EV::run;
                $pg->query("set client_min_messages = log; set log_statement = 'all'", sub { EV::break });
                EV::run;
                $pg->on_notice(sub {
                    $notices++;
                    if ($how eq 'finish') { $pg->finish } else { undef $pg }
                });
                if ($method eq 'set_client_encoding') { $pg->set_client_encoding('UTF8') }
                else { $pg->encrypt_password('testpass', 'testuser') }
                push @retained, $pg if $pg;
            }
            cmp_ok($notices, '>=', 3, "$method: $how from notice fired each round");
            select(undef, undef, undef, 0.3);
            with_pg(cb => sub {
                my ($pg) = @_;
                $pg->query("select count(*) from pg_stat_activity where application_name = '$app'", sub {
                    $count = $_[0][0][0];
                    EV::break;
                });
            });
            is($count, 0, "$method: $how from notice closes backends before object release");
            $_->on_notice(undef) for @retained;
        }
    }
}

# COPY helpers can parse notices outside a result-dispatch frame.
for my $method (qw(get_copy_data put_copy_data)) {
    my ($tag, $count);
    my $notices = 0;
    my $app = "evpg_notice_${method}_$$";
    my $pg;
    $pg = EV::Pg->new(
        conninfo => "$conninfo application_name=$app",
        on_connect => sub { EV::break },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    if ($method eq 'get_copy_data') {
        $pg->query(q{
            create function pg_temp.copy_note() returns text language plpgsql as $$
                begin raise notice 'row'; return 'row'; end $$
        }, sub { EV::break });
        EV::run;
        $pg->query('copy (select pg_temp.copy_note() from generate_series(1,5)) to stdout',
            sub { $tag = $_[0]; EV::break });
    } else {
        open my $fh, '+<&', $pg->socket or die "dup: $!";
        setsockopt($fh, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
            or diag "setsockopt SO_SNDBUF: $!";
        close $fh;
        $pg->query(q{
            create temp table copy_note (value text);
            create function pg_temp.copy_note() returns trigger language plpgsql as $$
                begin
                    if new.value = 'first' then raise notice 'row'; perform pg_sleep(0.2); end if;
                    return new;
                end $$;
            create trigger copy_note before insert on copy_note
                for each row execute procedure pg_temp.copy_note()
        }, sub { EV::break });
        EV::run;
        $pg->query('copy copy_note from stdin', sub { $tag = $_[0]; EV::break });
    }
    select(undef, undef, undef, 0.1);
    EV::run;
    is($tag, $method eq 'get_copy_data' ? 'COPY_OUT' : 'COPY_IN', "$method: COPY started");
    $pg->on_notice(sub { $notices++; $pg->finish });
    if ($method eq 'get_copy_data') {
        for (1 .. 5) {
            my $row = $pg->get_copy_data;
            last if $notices || !defined $row || $row eq '-1';
        }
    } else {
        $pg->put_copy_data("first\n");
        select(undef, undef, undef, 0.1);
        for (1 .. 5) {
            last if $notices;
            $pg->put_copy_data("row\n" x 16384);
        }
    }
    ok($notices && !$pg->is_connected, "$method: notice finished connection during standalone call");
    $pg->finish if $pg->is_connected;
    select(undef, undef, undef, 0.3);
    with_pg(cb => sub {
        my ($monitor) = @_;
        $monitor->query("select count(*) from pg_stat_activity where application_name = '$app'", sub {
            $count = $_[0][0][0];
            EV::break;
        });
    });
    is($count, 0, "$method: notice-driven finish closes backend before object release");
    $pg->on_notice(undef);
}

# COPY methods are not reentrant from on_notice: put_copy_data there parsed
# the next notice inside libpq and recursed (pre-fix: deep recursion, crash).
{
    my ($st, $out) = run_isolated(sub {
        my ($wr) = @_;
        my ($pg, $final, $croaks) = (undef, '', 0);
        $pg = EV::Pg->new(
            conninfo => $conninfo,
            on_error => sub { EV::break },
            on_notice => sub {
                eval { $pg->put_copy_data("99\n") };
                $croaks++ if $@ =~ /not allowed while on_notice runs/;
            },
            on_connect => sub {
                $pg->query(q{
                    create temp table notice_copy (v int);
                    create function pg_temp.notice_copy() returns trigger language plpgsql as $$
                        begin raise notice 'row %', new.v; return new; end $$;
                    create trigger notice_copy before insert on notice_copy
                        for each row execute procedure pg_temp.notice_copy()
                }, sub {
                    $pg->query('copy notice_copy from stdin', sub {
                        my ($data, $err) = @_;
                        if (($data // '') eq 'COPY_IN') {
                            $pg->put_copy_data("$_\n") for 1 .. 3;
                            my $t; $t = EV::timer(0.3, 0, sub { undef $t; $pg->put_copy_end });
                            return;
                        }
                        $final = $err ? "ERR:$err" : $data;
                        EV::break;
                    });
                });
            },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        print $wr "final=$final croaks=$croaks";
    }, 20);
    is($st, 'ok', 'put_copy_data from on_notice: no crash');
    is($out, 'final=3 croaks=3', 'put_copy_data from on_notice: croaks, COPY intact');
}

# skip_pending on a COPY BOTH stream must end it: the server only stops a
# replication stream after the client's CopyDone (pre-fix: wedged forever).
SKIP: {
    my ($pg, $lsn, $after, $retry);
    $pg = EV::Pg->new(
        conninfo => "$conninfo replication=true",
        on_error => sub { EV::break },
        on_connect => sub {
            $pg->query('IDENTIFY_SYSTEM', sub {
                my ($r) = @_;
                $lsn = ref $r ? $r->[0][2] : undef;
                EV::break;
            });
        },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    skip 'physical replication connection unavailable', 1 unless $lsn;
    $pg->query("START_REPLICATION PHYSICAL $lsn", sub {
        return unless ($_[0] // '') eq 'COPY_BOTH';
        $pg->skip_pending;
        $retry = EV::timer(0.05, 0.05, sub {
            return unless eval {
                $pg->query('IDENTIFY_SYSTEM', sub {
                    $after = ref $_[0] ? 'ok' : "ERR:$_[1]";
                    EV::break;
                });
                1;
            };
            undef $retry;
        });
    });
    $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    undef $retry;
    $pg->finish if $pg->is_connected;
    is($after, 'ok', 'skip_pending on COPY BOTH: stream ended, connection usable');
}

# NOTIFYs read by a blocking helper sit in libpq's queue with no fd event to
# announce them; they must still reach on_notify (pre-fix: never delivered).
for my $method (qw(set_client_encoding encrypt_password)) {
    my ($pg, $other, $got);
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_notify => sub { $got = $_[1]; EV::break },
        on_connect => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $pg->query('listen blocking_notify', sub { EV::break });
    EV::run;
    # own loop, so $pg's watcher cannot pick the NOTIFY up first
    my $ol = EV::Loop->new;
    $other = EV::Pg->new(conninfo => $conninfo, loop => $ol, on_connect => sub { $ol->break });
    $ol->run;
    $other->query(qq{notify blocking_notify, '$method'}, sub { $ol->break });
    $ol->run;
    $other->finish;
    select(undef, undef, undef, 0.2);
    if ($method eq 'set_client_encoding') { $pg->set_client_encoding('UTF8') }
    else { $pg->encrypt_password('testpass', 'testuser') }
    $pg->keep_alive(1);
    $t = EV::timer(3, 0, sub { EV::break });
    EV::run unless defined $got;
    $pg->finish;
    is($got, $method, "$method: NOTIFY read during the call is delivered");
}
