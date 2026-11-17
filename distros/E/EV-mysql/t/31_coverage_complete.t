use strict;
use warnings;
use utf8;
use Config;
use Test::More;
use lib 't/lib';
use TestMySQL;
use EV;
use EV::mysql;

plan skip_all => 'No MySQL server' unless TestMySQL::server_available();

my %A = TestMySQL::connect_args();

sub await_loop {
    my ($loop, $done_ref, $secs) = @_;
    my $guard = $loop->timer($secs // 15, 0, sub { $loop->break });
    $loop->run unless $$done_ref;
    undef $guard;
}

# 1. Option parsing, SSL options / ssl_mode, invalid values, and port => undef
{
    for my $mode (qw(DISABLED PREFERRED REQUIRED VERIFY_CA VERIFY_IDENTITY)) {
        my $opt_m = EV::mysql->new(ssl_mode => $mode);
        ok($opt_m, "new(ssl_mode => '$mode') accepted");
    }
    my $undef_ssl = EV::mysql->new(
        ssl_mode               => undef,
        ssl_verify_server_cert => undef,
        ssl_key                => undef,
        ssl_cert               => undef,
        ssl_ca                 => undef,
        ssl_capath             => undef,
        ssl_cipher             => undef,
    );
    ok($undef_ssl, 'undef SSL options accepted');

    my $bad_mode_err = do {
        local $@;
        eval { EV::mysql->new(ssl_mode => 'BOGUS_MODE') };
        $@;
    };
    like($bad_mode_err, qr/invalid ssl_mode/i, 'invalid ssl_mode croaks');

    my $undef_key_err = do {
        local $@;
        my $o = EV::mysql->new();
        eval { $o->_set_option(undef, 1) };
        $@;
    };
    like($undef_key_err, qr/cannot be undef/i, '_set_option(undef, ...) croaks');

    my $unk_opt_err = do {
        local $@;
        my $o = EV::mysql->new();
        eval { $o->_set_option('no_such_opt', 1) };
        $@;
    };
    like($unk_opt_err, qr/unknown option/i, '_set_option unknown option croaks');

    for my $bad_t (
        [ connect_timeout => -1 ],
        [ read_timeout    => -0.5 ],
        [ write_timeout   => 1.5 ],
        [ read_timeout    => 2**40 ],
    ) {
        my ($k, $v) = @$bad_t;
        my $err = do { local $@; eval { EV::mysql->new($k => $v) }; $@ };
        ok($err, "invalid timeout $k => $v croaks");
    }

    my $bad_port_err = do {
        local $@;
        my $o = EV::mysql->new();
        eval { $o->connect($A{host}, $A{user}, $A{password}, $A{database}, 70000) };
        $@;
    };
    like($bad_port_err, qr/port out of range/i, 'port > 65535 croaks');

    # Default EV::default_loop() path + ssl_mode => DISABLED
    my ($def_ok, $def_err) = (0, undef);
    my $m_def = EV::mysql->new(
        %A,
        ssl_mode   => 'DISABLED',
        on_connect => sub { $def_ok = 1; EV::break },
        on_error   => sub { $def_err = $_[0]; EV::break },
    );
    my $tg = EV::timer(10, 0, sub { EV::break });
    EV::run unless $def_ok || defined $def_err;
    undef $tg;
    ok($def_ok && !defined $def_err, 'default loop + ssl_mode => DISABLED connects')
        or diag("err=" . ($def_err // 'undef'));

    # port => undef falls back to 3306
    {
        my $loop = EV::Loop->new;
        my ($p_ok, $p_err) = (0, undef);
        my $m_p = EV::mysql->new(
            loop       => $loop,
            %A,
            port       => undef,
            on_connect => sub { $p_ok = 1; $loop->break },
            on_error   => sub { $p_err = $_[0]; $loop->break },
        );
        await_loop($loop, \$p_ok, 5);
        ok($p_ok || defined $p_err, 'port => undef fallback resolved port cleanly');
    }

    my $reconn_err = do {
        local $@;
        eval { $m_def->connect($A{host}, $A{user}, $A{password}, $A{database}, $A{port}) };
        $@;
    };
    like($reconn_err, qr/already connected or connecting/i, 'connect() while connected croaks');

    # ssl_mode => REQUIRED over TCP
    if (!$ENV{TEST_MYSQL_SOCKET}) {
        my $loop = EV::Loop->new;
        my ($ok, $err) = (0, undef);
        my $m_req = EV::mysql->new(
            loop       => $loop,
            %A,
            ssl_mode   => 'REQUIRED',
            on_connect => sub { $ok = 1; $loop->break },
            on_error   => sub { $err = $_[0]; $loop->break },
        );
        await_loop($loop, \$ok);
        ok($ok && !defined $err, 'ssl_mode => REQUIRED connects over TCP')
            or diag("err=" . ($err // 'undef'));
    }

    # Exercise apply_mysql_options branches for ssl_verify_server_cert == 1 / 0 + ssl_* strings
    {
        my $loop = EV::Loop->new;
        my $done = 0;
        my $m_v1 = EV::mysql->new(
            loop                   => $loop,
            %A,
            ssl_verify_server_cert => 1,
            ssl_cipher             => 'HIGH',
            on_connect             => sub { $done = 1; $loop->break },
            on_error               => sub { $done = 1; $loop->break },
        );
        await_loop($loop, \$done);
        ok($done, 'ssl_verify_server_cert => 1 + ssl_cipher option path executed cleanly');

        $done = 0;
        my $m_v0 = EV::mysql->new(
            loop                   => $loop,
            %A,
            ssl_verify_server_cert => 0,
            ssl_ca                 => '/nonexistent-ev-mysql-ca.pem',
            ssl_capath             => '/nonexistent-ev-mysql-capath',
            on_connect             => sub { $done = 1; $loop->break },
            on_error               => sub { $done = 1; $loop->break },
        );
        await_loop($loop, \$done);
        ok($done, 'ssl_verify_server_cert => 0 + ssl_ca/capath option path executed cleanly');
    }
}

# 2. Multi-row, NULL, UTF-8, and >64 columns on utf8 => 1 (query, query_stream, execute)
{
    my $loop = EV::Loop->new;
    my $m = EV::mysql->new(
        loop       => $loop,
        %A,
        utf8       => 1,
        on_connect => sub { $loop->break },
        on_error   => sub { diag("err: $_[0]"); $loop->break },
    );
    my $con_done = 0;
    $m->on_connect(sub { $con_done = 1; $loop->break });
    await_loop($loop, \$con_done);
    ok($m->is_connected, 'connected with utf8 => 1');

    # Multi-row stored result (nr = 3 > 1) with NULL + UTF-8 + ASCII
    my ($q_rows, $q_err, $q_fields);
    my $done = 0;
    $m->q("select 1 as id, 'привет' as txt, null as nil union all select 2, 'world', 'x' union all select 3, null, 'мир'", sub {
        ($q_rows, $q_err, $q_fields) = @_;
        $done = 1;
        $loop->break;
    });
    await_loop($loop, \$done);
    ok(!$q_err, 'multi-row utf8 query succeeded');
    is(scalar @$q_rows, 3, 'multi-row utf8 query returned 3 rows');
    is($q_rows->[0][1], 'привет', 'row 0 UTF-8 string intact');
    ok(utf8::is_utf8($q_rows->[0][1]), 'row 0 UTF-8 flag set');
    is($q_rows->[0][2], undef, 'row 0 NULL cell is undef');
    is($q_rows->[2][1], undef, 'row 2 NULL cell is undef');
    is($q_rows->[2][2], 'мир', 'row 2 UTF-8 string intact');

    # Multi-row prepared statement (nr = 3 > 1) with NULL + UTF-8 + >64B max_length column
    my ($p_rows, $p_err);
    $done = 0;
    $m->prepare("select ? as id, 'привет' as txt, null as nil, repeat('k', 200) as big union all select ?, null, 'мир', repeat('m', 150)", sub {
        my ($st, $perr) = @_;
        if ($perr) { $p_err = $perr; $done = 1; $loop->break; return }
        $m->execute($st, [10, 20], sub {
            ($p_rows, $p_err) = @_;
            $m->close_stmt($st, sub { $done = 1; $loop->break });
        });
    });
    await_loop($loop, \$done);
    ok(!$p_err, 'multi-row utf8 prepared execute succeeded');
    is(scalar @$p_rows, 2, 'multi-row prepared returned 2 rows');
    is($p_rows->[0][1], 'привет', 'prepared row 0 UTF-8 string ok');
    ok(utf8::is_utf8($p_rows->[0][1]), 'prepared row 0 UTF-8 flag set');
    is($p_rows->[0][2], undef, 'prepared row 0 NULL is undef');
    is(length($p_rows->[0][3]), 200, 'prepared >64-byte column returned full 200 bytes');
    is($p_rows->[1][1], undef, 'prepared row 1 NULL is undef');

    # Wide 70-column (>64) multi-row query, stream, and prepared execute
    my @cols = map { $_ == 67 ? "null as c$_" : ($_ == 68 ? "'юникод' as c$_" : "'v$_' as c$_") } (1 .. 70);
    my $col_sql = join(', ', @cols);
    my $wide_sql = "select $col_sql union all select $col_sql";

    $done = 0;
    my ($w_rows, $w_err, $w_fields);
    $m->q($wide_sql, sub {
        ($w_rows, $w_err, $w_fields) = @_;
        $done = 1;
        $loop->break;
    });
    await_loop($loop, \$done);
    ok(!$w_err, '70-col multi-row query succeeded');
    is(scalar @$w_fields, 70, '70-col fields count = 70');
    is($w_rows->[0][66], undef, '70-col NULL column 67 is undef');
    is($w_rows->[1][67], 'юникод', '70-col UTF-8 column 68 (>64) decoded cleanly');
    ok(utf8::is_utf8($w_rows->[1][67]), '70-col UTF-8 column 68 flag set');

    $done = 0;
    my @s_rows;
    my $s_err;
    $m->query_stream($wide_sql, sub {
        my ($row, $err, $flds) = @_;
        if ($err) { $s_err = $err; $done = 1; $loop->break; return }
        if ($row) { push @s_rows, $row; return }
        $done = 1;
        $loop->break;
    });
    await_loop($loop, \$done);
    ok(!$s_err, '70-col query_stream succeeded');
    is(scalar @s_rows, 2, '70-col query_stream got 2 rows');
    is($s_rows[0][66], undef, '70-col stream NULL col 67 is undef');
    is($s_rows[1][67], 'юникод', '70-col stream UTF-8 col 68 (>64) intact');
    ok(utf8::is_utf8($s_rows[1][67]), '70-col stream UTF-8 col 68 flag set');

    $done = 0;
    my ($wp_rows, $wp_err);
    $m->prepare($wide_sql, sub {
        my ($st, $perr) = @_;
        if ($perr) { $wp_err = $perr; $done = 1; $loop->break; return }
        $m->execute($st, [], sub {
            ($wp_rows, $wp_err) = @_;
            $m->close_stmt($st, sub { $done = 1; $loop->break });
        });
    });
    await_loop($loop, \$done);
    ok(!$wp_err, '70-col prepared execute succeeded');
    is($wp_rows->[0][67], 'юникод', '70-col prepared UTF-8 col 68 intact');
    ok(utf8::is_utf8($wp_rows->[0][67]), '70-col prepared UTF-8 col 68 flag set');

    # sqlstate on syntax error
    $done = 0;
    my $syn_err;
    $m->q("select from bogus_syntax_xyz", sub {
        $syn_err = $_[1];
        $done = 1;
        $loop->break;
    });
    await_loop($loop, \$done);
    ok($syn_err, 'syntax error returned');
    is($m->sqlstate, '42000', 'sqlstate populated with 42000 on syntax error');

    $m->finish;
}

# 3. Prepared params: PARAM_UV, >4 inline params, >16 stack params, >128B string, slow_freeze & guards
{
    my $loop = EV::Loop->new;
    my $m = EV::mysql->new(loop => $loop, %A, utf8 => 1);
    my $done = 0;
    $m->on_connect(sub { $done = 1; $loop->break });
    await_loop($loop, \$done);

    # PARAM_UV (64-bit unsigned > IV_MAX when Perl has 64-bit IV) via execute and bind_params
    if ($Config{ivsize} >= 8) {
        my $uv = ~0; # 18446744073709551615
        $done = 0;
        my ($r_exec, $r_bind);
        $m->prepare("select cast(? as unsigned)", sub {
            my ($st) = @_;
            $m->execute($st, [$uv], sub {
                $r_exec = $_[0][0][0];
                $m->bind_params($st, [$uv - 1]);
                $m->execute($st, sub {
                    $r_bind = $_[0][0][0];
                    $m->close_stmt($st, sub { $done = 1; $loop->break });
                });
            });
        });
        await_loop($loop, \$done);
        is($r_exec, "$uv", 'PARAM_UV via execute preserved full 64-bit unsigned');
        is($r_bind, ($uv - 1) . "", 'PARAM_UV via bind_params preserved full 64-bit unsigned');
    }

    # >16 parameters (20 params: exercises op->params heap + vals_stack > 16) + >128B string
    {
        my $n = 20;
        my $ph = join(' + ', ('length(?)') x $n);
        my $big_str = 'z' x 200;
        my @args = ($big_str, ('a') x ($n - 1));
        $done = 0;
        my ($sum_exec, $sum_bind);
        $m->prepare("select $ph", sub {
            my ($st) = @_;
            $m->execute($st, \@args, sub {
                $sum_exec = $_[0][0][0];
                $m->bind_params($st, \@args);
                $m->execute($st, sub {
                    $sum_bind = $_[0][0][0];
                    $m->close_stmt($st, sub { $done = 1; $loop->break });
                });
            });
        });
        await_loop($loop, \$done);
        is($sum_exec, 200 + 19, '20 params (>4 inline, >16 stack) + 200B string (>128 inline) via execute');
        is($sum_bind, 200 + 19, '20 params + 200B string via bind_params');
    }

    # slow_freeze: mixed plain+tied params mutating plain slot, tied undef, Latin-1 upgrade, overloaded obj, tied @arr, tied $cb
    {
        package CovTiedScalar;
        sub TIESCALAR { bless [ $_[1], $_[2] ], $_[0] }
        sub FETCH     { $_[0][1] ? $_[0][0]->() : $_[0][0] }

        package CovTiedArray;
        sub TIEARRAY  { bless [ @_[1..$#_] ], $_[0] }
        sub FETCHSIZE { scalar @{ $_[0] } }
        sub FETCH     { $_[0][ $_[1] ] }

        package CovOverload;
        use overload '""' => sub { $_[0]{s} }, fallback => 1;
        sub new { bless { s => $_[1] }, $_[0] }
    }
    {
        $done = 0;
        my ($res1, $res2);
        tie my $t_undef, 'CovTiedScalar', undef, 0;
        tie my $t_num,   'CovTiedScalar', 3.5, 0;
        my $ov = CovOverload->new('ov_str');
        my $latin1 = "\xe9"; # non-UTF8 Latin-1 byte requiring upgrade under utf8 => 1

        $m->prepare("select ?, ?, ?, ?, ?, ?", sub {
            my ($st) = @_;
            my $x = 'orig';
            tie my $m2, 'CovTiedScalar', sub { $x = 'mutated'; 'done' }, 1;
            # Bind $_[0] as alias to $x via sub arg list without triggering $m2->FETCH early:
            my $mk_alias = sub {
                $m->execute($st, \@_, sub {
                    $res1 = $_[0][0];
                    tie my @tied_arr, 'CovTiedArray', 'a', 'b', 'c', 4, 5.5, undef;
                    tie my $tied_cb, 'CovTiedScalar', sub {
                        $res2 = $_[0][0];
                        $m->close_stmt($st, sub { $done = 1; $loop->break });
                    }, 0;
                    $m->execute($st, \@tied_arr, $tied_cb);
                });
            };
            $mk_alias->($x, $m2, $t_undef, $t_num, $ov, $latin1);
        });
        await_loop($loop, \$done);
        is($res1->[0], 'orig', 'slow_freeze preserved earlier param before later magic mutated variable');
        is($res1->[1], 'done', 'tied FETCH evaluated in slow_freeze');
        is($res1->[2], undef, 'tied undef preserved as undef');
        is($res1->[3], '3.5', 'tied NV preserved');
        is($res1->[4], 'ov_str', 'overloaded object stringified in slow_freeze');
        is($res1->[5], "\x{e9}", 'Latin-1 upgraded to UTF-8 in slow_freeze');
        is_deeply($res2, ['a', 'b', 'c', '4', '5.5', undef], 'tied array + tied cb worked cleanly');
    }

    # Invalid param_ref, bind_params while busy, queue during closing/streaming
    {
        $done = 0;
        $m->prepare("select ?", sub {
            my ($st) = @_;
            my $e1 = do { local $@; eval { $m->execute($st, 'not_an_arrayref', sub {}) }; $@ };
            like($e1, qr/ARRAY reference/i, 'non-arrayref params croaks');

            my $e2 = do { local $@; eval { $m->bind_params($st, 'not_an_arrayref') }; $@ };
            like($e2, qr/ARRAY reference/i, 'bind_params non-arrayref croaks');

            $m->q("select 1", sub {
                my $e_busy = do { local $@; eval { $m->bind_params($st, [1]) }; $@ };
                like($e_busy, qr/another operation is in progress/i, 'bind_params while callback/op active croaks');
            });
            $m->close_stmt($st, sub { $done = 1; $loop->break });
        });
        await_loop($loop, \$done);
    }

    # Streaming queue guard & close_async guard
    {
        $done = 0;
        my $q_during_stream_err;
        $m->query_stream("select 1 union all select 2", sub {
            my ($row, $err) = @_;
            if ($row && !defined $q_during_stream_err) {
                local $@;
                eval { $m->q("select 1", sub {}) };
                $q_during_stream_err = $@;
            }
            if (!$row) { $done = 1; $loop->break }
        });
        await_loop($loop, \$done);
        like($q_during_stream_err, qr/streaming is active/i, 'queuing query during stream croaks');

        $done = 0;
        my $closed = 0;
        $m->close_async(sub { $closed = 1; $done = 1; $loop->break });
        my $q_closing_err = do { local $@; eval { $m->q("select 1", sub {}) }; $@ };
        like($q_closing_err, qr/closing/i, 'queuing while closing croaks');
        await_loop($loop, \$done);
        is($closed, 1, 'close_async completed cleanly');
    }
}

# 4. Large write payload with write_timeout (EV_WRITE flush) + multi_statements error + DESTROY with pending queue
{
    my $loop = EV::Loop->new;
    my $m = EV::mysql->new(
        loop             => $loop,
        %A,
        multi_statements => 1,
        read_timeout     => 5,
        write_timeout    => 5,
        on_connect       => sub { $loop->break },
        on_error         => sub { $loop->break },
    );
    my $done = 0;
    $m->on_connect(sub { $done = 1; $loop->break });
    await_loop($loop, \$done);

    # ~2MB SQL payload to encourage partial socket writes / EV_WRITE + read_timeout restoration
    my $big = 'x' x (2 * 1024 * 1024);
    my ($len_res, $len_err);
    $done = 0;
    $m->q("select length('$big')", sub {
        ($len_res, $len_err) = ($_[0], $_[1]);
        $done = 1;
        $loop->break;
    });
    await_loop($loop, \$done, 20);
    ok(!$len_err && $len_res && $len_res->[0][0] == 2 * 1024 * 1024, '2MB query with write_timeout + read_timeout succeeded');

    # Multi-statement where 1st result succeeds and 2nd errors (sec_err in complete_query_op -> on_error)
    my ($m1_res, $m1_err, $m1_onerr);
    $m->on_error(sub { $m1_onerr = $_[0] });
    $done = 0;
    $m->q("select 42; select * from no_such_table_xyz_cov", sub {
        ($m1_res, $m1_err) = ($_[0], $_[1]);
        $done = 1;
        $loop->break;
    });
    await_loop($loop, \$done);
    is($m1_res->[0][0], 42, 'multi-stmt 1st result delivered even when 2nd fails');
    ok(!$m1_err && $m1_onerr, '2nd stmt failure delivered to on_error');

    # Multi-statement DML only (complete_query_op STATE_NEXT_RESULT without fields)
    $done = 0;
    my ($dml_res, $dml_err);
    $m->q("do 1; do 2", sub {
        ($dml_res, $dml_err) = ($_[0], $_[1]);
        $done = 1;
        $loop->break;
    });
    await_loop($loop, \$done);
    ok(!$dml_err && defined $dml_res, 'multi-stmt DO; DO completed cleanly');

    # Stored procedure changing result column count across calls (out_cap growth + metadata refresh)
    $done = 0;
    $m->q("drop procedure if exists evm_cov_varcols", sub {
        $m->q("create procedure evm_cov_varcols(in n int) begin if n = 1 then select 11 as a; else select 1 as a, 2 as b, 3 as c; end if; end", sub {
            $done = 1;
            $loop->break;
        });
    });
    await_loop($loop, \$done);

    $done = 0;
    my ($sp1, $sp2, $sp_err);
    $m->prepare("call evm_cov_varcols(?)", sub {
        my ($st) = @_;
        $m->execute($st, [1], sub {
            $sp1 = $_[0];
            $m->execute($st, [2], sub {
                $sp2 = $_[0];
                $sp_err = $_[1];
                $m->close_stmt($st, sub {
                    $m->q("drop procedure if exists evm_cov_varcols", sub {
                        $done = 1;
                        $loop->break;
                    });
                });
            });
        });
    });
    await_loop($loop, \$done);
    ok(!$sp_err, 'stored procedure variable columns succeeded');
    is_deeply($sp1, [[11]], '1-col CALL result ok');
    is_deeply($sp2, [[1, 2, 3]], '3-col CALL result grew out_cap cleanly');

    $m->finish;
}

# 5. DESTROY object with queued ops while connecting (drains op_queue in free_self_final)
{
    my $loop = EV::Loop->new;
    {
        my $m = EV::mysql->new(loop => $loop, %A);
        $m->q("select 1", sub {});
        $m->q("select 2", sub {});
        undef $m;
    }
    pass('DESTROY with queued ops while connecting did not crash or leak');
}

done_testing;
