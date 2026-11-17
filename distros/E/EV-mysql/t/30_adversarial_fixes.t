use strict;
use warnings;
use utf8;
use POSIX ();
use Test::More;
use Scalar::Util qw(weaken);
use lib 't/lib';
use TestMySQL;
use EV;
use EV::mysql;

plan skip_all => 'No MySQL server' unless TestMySQL::server_available();

my %A = TestMySQL::connect_args();

sub await_loop {
    my ($loop, $done_ref, $secs) = @_;
    my $guard = $loop->timer($secs // 10, 0, sub { $loop->break });
    $loop->run unless $$done_ref;
    undef $guard;
}

# 1. Sole reference to $m held by active callback closure (query & execute & stale close_stmt)
{
    for my $kind (qw(query execute)) {
        my $wl;
        my $loop = EV::Loop->new;
        $wl = $loop;
        weaken($wl);
        {
            my ($done, $val) = (0, undef);
            my $m = EV::mysql->new(loop => $loop, %A, on_error => sub { $done = 1; $loop->break });
            $m->on_connect(sub {
                my $conn = $m;
                # Clear handlers before returning so only the active op closure holds $conn
                $conn->on_connect(undef);
                $conn->on_error(undef);
                if ($kind eq 'query') {
                    $conn->query('select 101', sub {
                        $val = $_[0] && $conn->is_connected ? $_[0][0][0] : undef;
                        $done = 1;
                        $loop->break;
                    });
                } else {
                    $conn->prepare('select ?', sub {
                        my ($s, $pe) = @_;
                        die $pe if $pe;
                        $conn->execute($s, [202], sub {
                            $val = $_[0] && $conn->is_connected ? $_[0][0][0] : undef;
                            $done = 1;
                            $loop->break;
                        });
                    });
                }
            });
            await_loop($loop, \$done);
            is($val, ($kind eq 'query' ? 101 : 202), "closure-owned \$m ($kind): value ok");
        }
        undef $loop;
        ok(!defined $wl, "closure-owned \$m ($kind): C struct & loop freed cleanly");
    }

    # Explicit undef $m inside execute callback
    {
        my $wl;
        my $loop = EV::Loop->new;
        $wl = $loop;
        weaken($wl);
        my $done = 0;
        my $m = EV::mysql->new(loop => $loop, %A, on_error => sub { $done = 1; $loop->break });
        $m->on_connect(sub {
            $m->prepare('select 1', sub {
                my ($s) = @_;
                $m->execute($s, [], sub {
                    undef $m;
                    $done = 1;
                    $loop->break;
                });
            });
        });
        await_loop($loop, \$done);
        undef $loop;
        ok(!defined $wl, 'execute callback undef $m: no zombie C struct leak');
    }
}

# 2. Stale close_stmt callback: queuing ops inside cb runs them; undef $m frees loop
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($m->is_connected, 'stale close_stmt test connected');

    my $sth;
    $m->prepare('select 1', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    $m->on_connect(sub { EV::break });
    $m->reset;
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($ok, $qval) = (0, undef);
    $m->close_stmt($sth, sub {
        $ok = $_[0];
        $m->query('select 303', sub {
            $qval = $_[0] ? $_[0][0][0] : undef;
            EV::break;
        });
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($ok, 'stale close_stmt ok');
    is($qval, 303, 'query queued inside stale close_stmt cb ran instead of wedging');
    $m->finish;
}

# 3. query_stream: $_[2] ($fields) stays valid after $m->finish inside row callback;
#    recursive query_stream while streaming croaks.
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    my ($fields_after, $rec_err);
    $m->query_stream('select 1 as colname union all select 2', sub {
        my ($row, $err, $fields) = @_;
        return if $err || !defined $row;
        eval { $m->query_stream('select 2', sub {}) };
        $rec_err = $@;
        $m->finish;
        $fields_after = $fields ? [@$fields] : undef;
        EV::break;
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    like($rec_err, qr/cannot queue query_stream while streaming is active/,
         'query_stream inside active stream croaks');
    is_deeply($fields_after, ['colname'], '$_[2] ($fields) stays valid after finish inside row cb');
}

# 4. close_async callback can reconnect & queue query without fail_queued_ops killing it
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($val, $qerr);
    $m->close_async(sub {
        my ($ok, $err) = @_;
        ok($ok && !$err, 'close_async succeeded');
        $m->on_connect(sub {});
        $m->connect(@A{qw(host user password database port)}, $A{unix_socket});
        $m->query('select 404', sub {
            ($val, $qerr) = ($_[0] ? $_[0][0][0] : undef, $_[1]);
            EV::break;
        });
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($qerr, undef, 'query queued in close_async cb was not cancelled');
    is($val, 404, 'query queued in close_async cb returned row');
    $m->finish;
}

# 5. Pipelined execute + close_stmt succeeds in FIFO order
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($rows, $eerr, $cok, $cerr);
    $m->prepare('select ? + 1', sub {
        my ($s, $pe) = @_;
        die $pe if $pe;
        $m->execute($s, [41], sub { ($rows, $eerr) = @_; });
        $m->close_stmt($s, sub { ($cok, $cerr) = @_; EV::break; });
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($eerr, undef, 'pipelined execute before close_stmt had no error');
    is_deeply($rows, [[42]], 'pipelined execute before close_stmt returned result');
    ok($cok && !$cerr, 'pipelined close_stmt succeeded');
    $m->finish;
}

# 6. send_long_data: multi-chunk without prior bind_params AND overriding non-empty bind_params
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($got_nobind, $got_prebind, $err1, $err2);
    $m->prepare('select ?', sub {
        my ($s) = @_;
        $m->send_long_data($s, 0, 'hello-', sub {});
        $m->send_long_data($s, 0, 'world', sub {});
        $m->execute($s, undef, sub {
            ($got_nobind, $err1) = ($_[0] ? $_[0][0][0] : undef, $_[1]);
            $m->close_stmt($s, sub { EV::break });
        });
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($err1, undef, 'send_long_data without prior bind_params: no error');
    is($got_nobind, 'hello-world', 'send_long_data without prior bind_params: chunks concatenated');

    $m->prepare('select ?, ?', sub {
        my ($s) = @_;
        $m->bind_params($s, [7, 'INLINE_SHOULD_NOT_WIN']);
        $m->send_long_data($s, 1, 'chunk1-', sub {});
        $m->send_long_data($s, 1, 'chunk2', sub {});
        $m->execute($s, undef, sub {
            ($got_prebind, $err2) = ($_[0] ? $_[0][0] : undef, $_[1]);
            $m->close_stmt($s, sub { EV::break });
        });
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($err2, undef, 'send_long_data after non-empty bind_params: no error');
    is_deeply($got_prebind, [7, 'chunk1-chunk2'], 'send_long_data overrides prior inline bind cleanly');
    $m->finish;
}

# 7. escape() with utf8 => 1 and unflagged Latin-1 string + SvGETMAGIC tied scalar
{
    my $m = EV::mysql->new(%A, charset => 'utf8mb4', utf8 => 1,
        on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $latin1 = "caf\xe9";
    utf8::downgrade($latin1);
    my $esc = $m->escape($latin1);
    ok(utf8::is_utf8($esc), 'escape unflagged latin1 on utf8=>1 sets SvUTF8');
    is($esc, "caf\x{e9}", 'escape unflagged latin1 preserves characters without mojibake');

    {
        package TieUpper;
        sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
        sub FETCH { ${$_[0]} }
    }
    tie my $tied_sql, 'TieUpper', 'select 505';
    my $tval;
    $m->query($tied_sql, sub { $tval = $_[0][0][0]; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($tval, 505, 'query works with tied SV (SvGETMAGIC)');
    $m->finish;
}

# 8. skip_pending during STATE_DEFERRED_OP clears deferred_timer & closing flags
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($sth, $close_async_err, $stmt_err, $post_val);
    $m->prepare('select 606', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    $m->close_stmt($sth, sub { $stmt_err = $_[1] });
    $m->close_async(sub { $close_async_err = $_[1] });
    $m->skip_pending;

    is($stmt_err, 'skipped', 'pending close_stmt was skipped');
    is($close_async_err, 'skipped', 'pending close_async was skipped');
    ok($m->is_connected, 'connection stayed alive after skipping STATE_DEFERRED_OP close_stmt/close_async');

    $m->execute($sth, [], sub { $post_val = $_[0] ? $_[0][0][0] : undef; });
    $m->query('select 707', sub { EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($post_val, 606, 'stmt closing flag reset by skip_pending; execute still works');
    $m->finish;
}

# 9. query_stream secondary fatal error (KILL) updates is_connected and invokes on_error
{
    my @errs;
    my $m = EV::mysql->new(%A, multi_statements => 1,
        on_connect => sub { EV::break }, on_error => sub { push @errs, $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $ctrl = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $tid = $m->thread_id;
    my ($rows_seen, $eof_seen, $eof_err, $killer) = (0, 0, undef, undef);
    $m->query_stream('select 1; select sleep(0.5)', sub {
        my ($row, $err) = @_;
        if (defined $row) { $rows_seen++; return; }
        $eof_seen = 1;
        $eof_err = $err;
        EV::break;
    });
    $killer = EV::timer(0.1, 0, sub {
        $ctrl->query("kill $tid", sub { $ctrl->finish });
    });
    $t = EV::timer(5, 0, sub { EV::break }); EV::run;
    undef $killer;
    is($rows_seen, 1, 'stream KILL secondary: first row delivered');
    is($eof_seen, 1, 'stream KILL secondary: EOF delivered');
    is($eof_err, undef, 'stream KILL secondary: first-result EOF stays clean');
    ok(@errs >= 1, 'stream KILL secondary: on_error notified');
    ok(!$m->is_connected, 'stream KILL secondary: connection marked disconnected');
    is($m->pending_count, 0, 'stream KILL secondary: pending_count is 0');
    $m->finish;
}

# 10. Nested reset() inside reset() cancel callback does not double-connect
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($connects, $cancelled) = (0, 0);
    $m->on_connect(sub { $connects++; EV::break if $connects >= 1 });
    $m->query('select sleep(1)', sub {
        $cancelled++;
        $m->reset if $cancelled == 1;
    });
    $m->reset;
    $t = EV::timer(5, 0, sub { EV::break }); EV::run;
    my $pause = EV::timer(0.05, 0, sub { EV::break }); EV::run;
    undef $pause;
    is($connects, 1, 'nested reset() inside cancel cb connects once');
    ok($m->is_connected, 'nested reset() leaves connection healthy');
    $m->finish;
}

# 11. Fork during active query_stream: child cleanup must not steal parent stream rows
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare('select 1', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my @rows;
    my ($eof, $forked, $parent_pid) = (0, 0, $$);
    $m->query_stream(
        'with recursive s(n) as (select 1 union all select n+1 from s where n < 20) select n from s',
        sub {
            my ($row, $err) = @_;
            die $err if $err && $$ == $parent_pid;
            if (!defined $row) { $eof = 1; EV::break if $$ == $parent_pid; return; }
            push @rows, $row->[0];
            if (!$forked && @rows == 1) {
                $forked = 1;
                my $pid = fork();
                die "fork: $!" unless defined $pid;
                if ($pid == 0) {
                    eval { $m->finish };
                    POSIX::_exit($@ ? 1 : 0);
                }
                waitpid($pid, 0);
                is($? >> 8, 0, 'forked child finished cleanly');
            }
        });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($eof, 'parent stream reached EOF after child cleanup');
    is(scalar(@rows), 20, 'parent stream received all 20 rows without child stealing data');
    $m->finish;
}

# 12. Global destruction (PL_dirty) with custom EV::Loop exits cleanly without UAF
{
    my $code = q{
        use EV; use EV::mysql;
        my $l = EV::Loop->new;
        my $m = EV::mysql->new(loop => $l, connect_timeout => 5, on_error => sub {});
        $m->connect('127.0.0.1', 'u', 'p', 'd', 1);
        our @hold = ($m, $l);
    };
    my @inc = map { ('-I', $_) } @INC;
    my $rc = system($^X, @inc, '-e', $code);
    is($rc & 127, 0, 'PL_dirty destruction with custom EV::Loop exits without signal');
}

# 13. Forked child calling check_fork_safety paths (reset/query) does not shutdown parent socket
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my @rows;
    my ($eof, $forked, $parent_pid) = (0, 0, $$);
    $m->query_stream(
        'with recursive s(n) as (select 1 union all select n+1 from s where n < 20) select n from s',
        sub {
            my ($row, $err) = @_;
            die $err if $err && $$ == $parent_pid;
            if (!defined $row) { $eof = 1; EV::break if $$ == $parent_pid; return; }
            push @rows, $row->[0];
            if (!$forked && @rows == 1) {
                $forked = 1;
                my $pid = fork();
                die "fork: $!" unless defined $pid;
                if ($pid == 0) {
                    my $on_err = '';
                    $m->on_error(sub { $on_err = $_[0] });
                    # reset() exercises check_fork_safety -> cleanup_connection
                    eval { $m->reset };
                    POSIX::_exit($@ ? 1 : 0);
                }
                waitpid($pid, 0);
                is($? >> 8, 0, 'forked child check_fork_safety reset exited cleanly');
            }
        });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($eof, 'parent stream reached EOF after child reset()');
    is(scalar(@rows), 20, 'parent stream received all 20 rows after child check_fork_safety');
    $m->finish;
}

# 14. Forked child entering EV::run directly with active EV watchers runs fork safety
{
    my $loop = EV::Loop->new;
    my $m = EV::mysql->new(%A, loop => $loop, on_connect => sub { $loop->break }, on_error => sub { $loop->break });
    await_loop($loop, \(my $d1 = 0), 10);

    my ($q_res, $q_err, $child_exit);
    $m->query('select sleep(0.25)', sub {
        ($q_res, $q_err) = @_;
        $loop->break;
    });
    my $ft = $loop->timer(0.05, 0, sub {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            my $rc = 1;
            eval {
                $loop->loop_fork;
                my $lt = $loop->timer(1.5, 0, sub { $loop->break });
                $loop->run;
                $rc = (defined($q_err) && $q_err =~ /fork/i) ? 0 : 2;
            };
            POSIX::_exit($@ ? 3 : $rc);
        }
        waitpid($pid, 0);
        $child_exit = $? >> 8;
    });
    await_loop($loop, \(my $d2 = 0), 10);
    undef $ft;
    is($child_exit, 0, 'forked child running EV::run triggers fork safety in EV callback');
    is($q_err, undef, 'parent active query unaffected by child EV::run');
    ok(ref($q_res) eq 'ARRAY', 'parent active query received result after child EV::run');
    $m->finish;
}

# 15. PL_tmps_stack: mortal row/result/field/error SVs freed immediately per callback inside EV::run
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub {});
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($weak_q_res, $weak_q_fld, $weak_s_row, $weak_s_fld);
    my ($q_freed_in_run, $s_row_freed_in_run, $s_fld_freed_in_run, $s_count) = (0, 0, 0, 0);

    $m->query('select 42 as num', sub {
        $weak_q_res = $_[0]; weaken($weak_q_res);
        $weak_q_fld = $_[2]; weaken($weak_q_fld);
    });
    $m->query('select 99', sub {
        $q_freed_in_run = (!defined($weak_q_res) && !defined($weak_q_fld)) ? 1 : 0;
    });
    $m->query_stream('select 1 as c union all select 2', sub {
        if (defined $_[0]) {
            $s_count++;
            if ($s_count == 1) {
                $weak_s_row = $_[0]; weaken($weak_s_row);
                $weak_s_fld = $_[2]; weaken($weak_s_fld);
            } elsif ($s_count == 2) {
                $s_row_freed_in_run = !defined($weak_s_row) ? 1 : 0;
            }
        }
    });
    $m->query('select 100', sub {
        $s_fld_freed_in_run = !defined($weak_s_fld) ? 1 : 0;
        EV::break;
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($q_freed_in_run, 'query result and fields freed before EV::run returns');
    ok($s_row_freed_in_run, 'stream row freed before next row inside EV::run');
    ok($s_fld_freed_in_run, 'stream fields freed at EOF before next op inside EV::run');
    $m->finish;
}

# 16. Multi-param send_long_data preserves earlier params' long_data_used across bind_param
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare("select concat(?, '|', ?, '|', ?)", sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $res;
    $m->send_long_data($sth, 0, 'alpha-', sub {});
    $m->send_long_data($sth, 0, 'one', sub {});
    $m->send_long_data($sth, 1, 'beta-', sub {});
    $m->send_long_data($sth, 1, 'two', sub {});
    $m->send_long_data($sth, 2, 'gamma', sub {});
    $m->execute($sth, undef, sub { ($res) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($res->[0][0], 'alpha-one|beta-two|gamma', 'multi-param send_long_data across 3 params');

    $m->stmt_reset($sth, sub { EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    $m->bind_params($sth, ['p0', 'p1', 'p2']);
    $m->send_long_data($sth, 0, 'OVR0', sub {});
    $m->send_long_data($sth, 2, 'OVR2', sub {});
    $m->execute($sth, undef, sub { ($res) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($res->[0][0], 'OVR0|p1|OVR2', 'mixed bind_params + multiple send_long_data overrides');
    $m->finish;
}

# 17. skip_pending() in queued cb during fatal abort preserves STATE_DISCONNECTED for on_error
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub {});
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($on_err_called, $q2_err) = (0, undef);
    $m->on_error(sub { $on_err_called++; EV::break });
    $m->query('select sleep(5)', sub {});
    $m->query('select 1', sub {
        $q2_err = $_[1];
        $m->skip_pending;
    });
    $m->query('select 2', sub {});
    my $tid = $m->thread_id;
    my $ctrl;
    $ctrl = EV::mysql->new(%A, on_connect => sub {
        $ctrl->query("kill $tid", sub { $ctrl->finish });
    }, on_error => sub {});
    $t = EV::timer(5, 0, sub { EV::break }); EV::run;
    ok(defined $q2_err, 'queued op failed during KILL abort');
    is($on_err_called, 1, 'on_error still fires when queued cb called skip_pending');
    ok(!$m->is_connected, 'connection remains disconnected after skip_pending in abort cb');
    $m->finish;
}

# 18. reset() + queue new query inside fatal-secondary callback completes cleanly
{
    my $m = EV::mysql->new(%A, multi_statements => 1, on_connect => sub { EV::break }, on_error => sub {});
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $ctrl = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub {});
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    my $tid = $m->thread_id;

    my ($first_res, $reconn_res, $old_q_err, $on_err_spurious) = (undef, undef, undef, 0);
    $m->on_error(sub { $on_err_spurious++ });
    $m->on_connect(sub {
        $m->query('select 777', sub { ($reconn_res) = @_; EV::break });
    });
    $m->query('select 111; select sleep(5)', sub {
        ($first_res) = @_;
        $m->reset;
    });
    $m->query('select 222', sub { $old_q_err = $_[1] });
    my $killer = EV::timer(0.1, 0, sub {
        $ctrl->query("kill $tid", sub { $ctrl->finish });
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    undef $killer;
    is($first_res->[0][0], '111', 'first result delivered before reset');
    is($reconn_res->[0][0], '777', 'query queued after reset() in fatal-secondary cb completes');
    is($on_err_spurious, 0, 'old connection on_error suppressed after callback reset()');
    $m->finish;
}

# 19. STATE_CONNECTING failure -> queued cb calling connect() suppresses old on_error and drains old queued ops
{
    my $on_err_spurious = 0;
    my $old_q2_err;
    my $new_q_res;
    my $m = EV::mysql->new(on_error => sub { $on_err_spurious++ });
    $m->on_connect(sub {
        $m->query('select 888', sub { ($new_q_res) = @_; EV::break });
    });
    # Port 1 triggers deferred_connect_err on TCP connect failure
    $m->connect('127.0.0.1', 'u', 'p', 'd', 1);
    $m->query('select 1', sub {
        $m->connect(@A{qw(host user password database port unix_socket)});
    });
    $m->query('select 2', sub { $old_q2_err = $_[1] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($on_err_spurious, 0, 'STATE_CONNECTING on_error suppressed after cb connect()');
    like($old_q2_err, qr/Connection reset/, 'dead-connection q2 failed before new connect()');
    is($new_q_res->[0][0], '888', 'query on new connection after cb connect() succeeded');
    $m->finish;
}

# 20. Failed execute clears long_data_sent so subsequent send_long_data on another param does not forge long_data_used
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    $m->query('create temporary table t_ld_err (id int primary key, a varchar(32), b varchar(32))', sub { EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    $m->query("insert into t_ld_err values (1, 'seed', 'seed')", sub { EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare('insert into t_ld_err (id, a, b) values (1, ?, ?)', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $dup_err;
    $m->send_long_data($sth, 0, 'should_not_persist', sub {});
    $m->execute($sth, undef, sub { $dup_err = $_[1]; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    like($dup_err, qr/Duplicate entry/i, 'first execute failed as expected');

    my $sth2;
    $m->prepare('select ?, ?', sub { ($sth2) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    # Verify on original $sth via non-failing INSERT after changing param or reusing $sth2 isn't stale:
    # Actually re-prepare or insert id=2 won't match hardcoded id=1; test on SELECT ? + signal error:
    $m->prepare('select if(? = "fail", (select 1 union all select 2), concat(coalesce(?, "null"), "|", ?))', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($r1, $e1);
    $m->bind_params($sth, ['fail', undef, 'x']);
    $m->send_long_data($sth, 1, 'old_chunk', sub {});
    $m->execute($sth, undef, sub { ($r1, $e1) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    like($e1, qr/more than 1 row/i, 'failing execute triggered subquery error');

    # Now re-bind param 0 to "ok" and stream only param 2; param 1 must NOT retain stale long_data_used=1
    $m->bind_params($sth, ['ok', 'clean_val', undef]);
    $m->send_long_data($sth, 2, 'tail', sub {});
    $m->execute($sth, undef, sub { ($r1, $e1) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($e1, undef, 'subsequent execute after failed execute succeeded cleanly');
    is($r1->[0][0], 'clean_val|tail', 'stale long_data_sent did not overwrite clean_val with empty long data');
    $m->finish;
}

# 21. execute($sth, \@params, $cb) snapshots \@params at queue time
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare('select ?, ?', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($r1, $r2);
    my @p = ('first', 10);
    $m->execute($sth, \@p, sub { ($r1) = @_; });
    @p = ('second', 20);
    $m->execute($sth, \@p, sub { ($r2) = @_; EV::break });
    @p = ();
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is_deeply($r1, [['first', '10']], 'first execute saw queue-time snapshot before mutation');
    is_deeply($r2, [['second', '20']], 'second execute saw queue-time snapshot before @p=()');
    $m->finish;
}

# 22. connect() accepts undef port without warnings FATAL error
{
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    my $m = EV::mysql->new(on_connect => sub { EV::break }, on_error => sub { EV::break });
    $m->connect($A{host}, $A{user}, $A{password}, $A{database}, undef, $A{unix_socket});
    my $t = EV::timer(5, 0, sub { EV::break }); EV::run;
    is($warnings, '', 'connect() with undef port emits zero uninitialized warnings');
    ok($m->is_connected || !$A{unix_socket}, 'connect() with undef port connected');
    $m->finish;
}

# 23. send_long_data checks 64-bit param_idx without UV->unsigned int wraparound
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare('select ?', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($e_neg, $e_big);
    $m->send_long_data($sth, -1, 'x', sub { $e_neg = $_[1] });
    if (~0 > 0xFFFFFFFF) {
        $m->send_long_data($sth, 2**32, 'x', sub { $e_big = $_[1]; EV::break });
    } else {
        $m->ping(sub { EV::break });
    }
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    like($e_neg, qr/out of range/i, 'send_long_data negative param_idx does not wrap');
    if (~0 > 0xFFFFFFFF) {
        like($e_big, qr/out of range/i, 'send_long_data 2**32 param_idx does not wrap to 0');
    } else {
        pass('send_long_data 2**32 check skipped on 32-bit');
    }
    $m->finish;
}

# 24. timeout options reject negative and >UINT_MAX values without wraparound
{
    eval { EV::mysql->new(read_timeout => -1, on_error => sub {}) };
    like($@, qr/negative|out of range/i, 'negative read_timeout croaks');
    if (~0 > 0xFFFFFFFF) {
        eval { EV::mysql->new(write_timeout => 2**32, on_error => sub {}) };
        like($@, qr/out of range/i, '2**32 write_timeout croaks instead of wrapping to 0');
    } else {
        pass('2**32 timeout check skipped on 32-bit');
    }
}

# 25. Queued close_stmt behind reset_connection & stale close_stmt after skip_pending+reset
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($sth, $rc_ok, $rc_err, $cs_ok, $cs_err);
    $m->prepare('select 1', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    $m->reset_connection(sub { ($rc_ok, $rc_err) = @_ });
    $m->close_stmt($sth, sub { ($cs_ok, $cs_err) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($rc_ok && !$rc_err, 'reset_connection succeeded');
    ok($cs_ok && !$cs_err, 'close_stmt queued behind reset_connection cleaned up cleanly');

    # Now queue close_stmt behind slow query, skip_pending (wire cleanup), then reset and close_stmt
    $m->prepare('select 2', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    $m->query('select sleep(2)', sub {});
    $m->close_stmt($sth, sub {});
    my $sp_t = EV::timer(0.05, 0, sub { $m->skip_pending; EV::break });
    $t = EV::timer(5, 0, sub { EV::break }); EV::run;
    undef $sp_t;

    $m->on_connect(sub { EV::break });
    $m->reset;
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($after_ok, $after_err);
    eval { $m->close_stmt($sth, sub { ($after_ok, $after_err) = @_; EV::break }) };
    is($@, '', 'close_stmt after wire skip_pending + reset does not croak on stale closing flag');
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($after_ok && !$after_err, 'stale stmt cleaned up cleanly after skip_pending + reset');
    $m->finish;
}

# 26. Tied argument FETCH mutating $m (finish / close_stmt) caught by post-magic state re-check
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    {
        package CloseInFetch;
        sub TIESCALAR { my ($cls, $fn) = @_; bless { fn => $fn }, $cls }
        sub FETCH { $_[0]->{fn}->(); 'select 1' }
    }

    my $sth;
    $m->prepare('select ?', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    tie my $close_stmt_sql, 'CloseInFetch', sub { $m->close_stmt($sth, sub {}) };
    eval { $m->send_long_data($sth, 0, $close_stmt_sql, sub {}) };
    like($@, qr/invalid statement handle/, 'send_long_data re-checks stmt liveness after FETCH');
    $t = EV::timer(10, 0, sub { EV::break }); # drain close_stmt:
    $m->ping(sub { EV::break });
    EV::run;
    undef $t;

    tie my $finish_sql, 'CloseInFetch', sub { $m->finish };
    eval { $m->query($finish_sql, sub {}) };
    like($@, qr/not connected/, 'query re-checks connection state after FETCH');
    is($m->pending_count, 0, 'rejected post-magic query did not leave orphan op');
    $m->finish;
}

# 27. ping() inside idle callback queues cleanly without setting current_op prematurely
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare('select 1', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    # Make $sth stale via reset_connection
    $m->reset_connection(sub { EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($cs_err, $cs_ok, $ping_ok, $pending_after_ping);
    $m->query('select 1', sub {
        $m->ping(sub { $ping_ok = $_[0] && !$_[1] });
        $pending_after_ping = $m->pending_count;
        eval { $m->close_stmt($sth, sub { $cs_ok = $_[0] && !$_[1] }) };
        $cs_err = $@;
        $m->ping(sub { EV::break });
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($pending_after_ping, 1, 'ping() inside idle cb stays queued in op_queue');
    is($cs_err, '', 'close_stmt($stale) after ping() in same cb does not see active current_op');
    ok($cs_ok, 'stale close_stmt succeeded fast-path cleanly');
    ok($ping_ok, 'queued ping() succeeded');
    $m->finish;
}

# 28. bind_params / execute overload calling finish() does not NULL-deref or UAF
{
    {
        package OverloadFinish;
        use overload '""' => sub { $_[0]->{fn}->() }, fallback => 1;
        sub new { my ($c, $fn) = @_; bless { fn => $fn }, $c }
    }

    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare('select ?, ?', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $ov = OverloadFinish->new(sub { $m->finish; 'ok' });
    eval { $m->bind_params($sth, ['first', $ov]) };
    like($@, qr/not connected/, 'bind_params overload calling finish() croaks safely without UAF');

    $m->on_connect(sub { EV::break });
    $m->reset;
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    $m->prepare('select ?, ?', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    eval { $m->execute($sth, ['first', $ov], sub {}) };
    like($@, qr/not connected/, 'execute overload calling finish() evaluated at queue time and croaks safely');
    is($m->pending_count, 0, 'rejected execute left zero pending ops');
    $m->finish;
}

# 29. escape() overload calling finish() croaks safely instead of dereferencing NULL conn
{
    {
        package EscapeOverload;
        use overload '""' => sub { $_[0]->{fn}->() }, fallback => 1;
        sub new { my ($c, $fn) = @_; bless { fn => $fn }, $c }
    }

    my $m = EV::mysql->new(%A, utf8 => 1, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $ov_fin = EscapeOverload->new(sub { $m->finish; "a'b" });
    eval { $m->escape($ov_fin) };
    like($@, qr/not connected/, 'escape overload calling finish() croaks safely');

    $m->on_connect(sub { EV::break });
    $m->reset;
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $ov_u8 = EscapeOverload->new(sub { "\x{2603}'s" });
    my $esc = $m->escape($ov_u8);
    is($esc, "\x{2603}\\'s", 'escape overload returning UTF-8 preserves characters and SvUTF8');
    ok(utf8::is_utf8($esc), 'escape overload return preserves UTF-8 flag');
    $m->finish;
}

# 30. Tied cb fetched only once so close_stmt cannot wedge ctx->closing on second FETCH
{
    {
        package OneShotCb;
        sub TIESCALAR { my ($c, $fn) = @_; bless { n => 0, fn => $fn }, $c }
        sub FETCH {
            $_[0]->{n}++;
            die 'second FETCH unexpected' if $_[0]->{n} > 1;
            $_[0]->{fn};
        }
    }

    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $m->prepare('select 1', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($ok, $err);
    tie my $cb, 'OneShotCb', sub { ($ok, $err) = @_; EV::break };
    eval { $m->close_stmt($sth, $cb) };
    is($@, '', 'close_stmt with OneShotCb does not trigger second FETCH');
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($ok && !$err, 'close_stmt callback invoked cleanly');
    $m->finish;
}

# 31. Sole-ref undef $m inside argument FETCH does not free self mid-XSUB (HOLD_SELF_ST)
{
    {
        package UndefSelfInFetch;
        sub TIESCALAR { my ($c, $fn) = @_; bless { fn => $fn }, $c }
        sub FETCH { $_[0]->{fn}->() }
    }

    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub {});
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    tie my $kill_sql, 'UndefSelfInFetch', sub { undef $m; 'select 1' };
    my $cb_err;
    eval { $m->query($kill_sql, sub { $cb_err = $_[1] }) };
    is($@, '', 'query with FETCH calling undef $m completes without UAF or croak');
    is($cb_err, 'connection finished', 'queued op failed cleanly when temporary self ref dropped after XSUB');
    pass('survived sole-ref undef $m mid-XSUB without crash');
}

# 32. Tied/overloaded $stmt deleting sole $m ref in FETCH does not UAF ST(0) in preamble
{
    {
        package DelSelfStmt;
        sub TIESCALAR { my ($c, $fn) = @_; bless { fn => $fn }, $c }
        sub FETCH { $_[0]->{fn}->() }
    }

    my %h;
    $h{m} = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub {});
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $sth;
    $h{m}->prepare('select 1', sub { ($sth) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    tie my $tied_stmt, 'DelSelfStmt', sub { delete $h{m}; $sth };
    my $cb_err;
    eval { $h{m}->execute($tied_stmt, sub { $cb_err = $_[1] }) };
    is($@, '', 'execute($tied_stmt) deleting sole $m does not croak or UAF ST(0)');
    is($cb_err, 'connection finished', 'execute failed cleanly when $m freed on statement exit');
}

# 33. Stale close_stmt inside outer callback keeps earlier queued query deferred until callback_depth unwinds
{
    my $m = EV::mysql->new(%A, on_connect => sub { EV::break }, on_error => sub { die $_[0] });
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($stale, $live);
    $m->prepare('select 1', sub { ($stale) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    $m->reset_connection(sub { EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    $m->prepare('select ?', sub { ($live) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my ($q2_ran_during_cb, $outer_returned, $bind_err, $exec_res) = (0, 0, undef, undef);
    $m->query('select 1', sub {
        $m->query('select 2', sub { $q2_ran_during_cb = 1 if !$outer_returned });
        $m->close_stmt($stale, sub {});
        eval { $m->bind_params($live, ['ok']) };
        $bind_err = $@;
        $m->execute($live, undef, sub { ($exec_res) = @_; EV::break });
        $outer_returned = 1;
    });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is($q2_ran_during_cb, 0, 'queued query did not start prematurely during stale close_stmt inside outer cb');
    is($bind_err, '', 'bind_params still allowed after stale close_stmt inside outer cb');
    is_deeply($exec_res, [['ok']], 'subsequent execute succeeded cleanly');
    $m->finish;
}

# 34. Tied scalars trigger FETCH at most once across all XSUBs and helpers
{
    {
        package SingleFetch;
        sub TIESCALAR { my ($c, $val) = @_; bless { n => 0, val => $val }, $c }
        sub FETCH {
            $_[0]->{n}++;
            die "unexpected double FETCH (#$_[0]->{n})" if $_[0]->{n} > 1;
            $_[0]->{val};
        }
    }

    tie my $to, 'SingleFetch', 5;
    my $m = eval { EV::mysql->new(read_timeout => $to, on_error => sub {}) };
    is($@, '', '_set_option timeout FETCHed tied scalar once');
    ok($m, 'EV::mysql constructed cleanly with single-FETCH read_timeout');

    eval { $m->connect('127.0.0.1', 'u', 'p', 'd', -0.5) };
    like($@, qr/out of range/i, 'connect rejects negative fractional port -0.5');

    eval { $m->connect('127.0.0.1', 'u', 'p', 'd', 3306.5) };
    like($@, qr/out of range|non-integer/i, 'connect rejects positive fractional port 3306.5');

    eval { EV::mysql->new(read_timeout => 1.5, on_error => sub {}) };
    like($@, qr/out of range|non-integer/i, 'read_timeout rejects fractional 1.5');

    {
        my $nan = sin(9**9**9);
        eval { $m->connect('127.0.0.1', 'u', 'p', 'd', $nan) };
        like($@, qr/out of range/i, 'connect rejects NaN port');
        eval { EV::mysql->new(read_timeout => $nan, on_error => sub {}) };
        like($@, qr/out of range/i, 'read_timeout rejects NaN');
    }

    $m->on_connect(sub { EV::break });
    tie my $t_host, 'SingleFetch', $A{host};
    tie my $t_port, 'SingleFetch', $A{port};
    $m->connect($t_host, $A{user}, $A{password}, $A{database}, $t_port, $A{unix_socket});
    my $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    ok($m->is_connected, 'connect connected with single-FETCH tied host/port');

    tie my $t_sql, 'SingleFetch', 'select ?';
    my $sth;
    eval { $m->prepare($t_sql, sub { ($sth) = @_; EV::break }) };
    is($@, '', 'prepare FETCHed tied SQL once');
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    tie my $t_sth, 'SingleFetch', $sth;
    tie my $t_p0,  'SingleFetch', 0;
    tie my $t_dat, 'SingleFetch', 'hello';
    eval { $m->send_long_data($t_sth, $t_p0, $t_dat, sub { EV::break }) };
    is($@, '', 'send_long_data FETCHed tied stmt/idx/data once');
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    my $res;
    tie my $t_sth2, 'SingleFetch', $sth;
    $m->execute($t_sth2, undef, sub { ($res) = @_; EV::break });
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;
    is_deeply($res, [['hello']], 'execute with single-FETCH long data succeeded');

    tie my $t_mode, 'SingleFetch', 1;
    eval { $m->autocommit($t_mode, sub { EV::break }) };
    is($@, '', 'autocommit FETCHed tied mode once');
    $t = EV::timer(10, 0, sub { EV::break }); EV::run;

    eval { $m->select_db("bad\0db", sub {}) };
    like($@, qr/NUL/i, 'select_db rejects embedded NUL bytes');

    $m->finish;
}

done_testing();
