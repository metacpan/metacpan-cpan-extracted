use v5.36;
use Test::More;

plan skip_all => $@ if !eval { require FU::Pg; } && $@ =~ /Unable to load libpq/;
die $@ if $@;
plan skip_all => 'Please set FU_TEST_DB to a PostgreSQL connection string to run these tests' if !$ENV{FU_TEST_DB};

sub okerr($sev, $act, $msg) {
    is ref $@, 'FU::Pg::error';
    is $@->{severity}, $sev;
    is $@->{action}, $act;
    like "$@", $msg;
}

ok !eval { FU::Pg->connect("invalid") };
okerr FATAL => connect => qr/missing "=" after "invalid"/;

ok FU::Pg::lib_version() > 100000;

my $conn = FU::Pg->connect($ENV{FU_TEST_DB});
$conn->text;
$conn->cache(0);
$conn->_debug_trace(0);

is ref $conn, 'FU::Pg::conn';
ok $conn->server_version > 100000;
is $conn->lib_version, FU::Pg::lib_version();
is $conn->status, 'idle';

subtest '$conn->exec', sub {
    ok !eval { $conn->exec('COPY (SELECT 1) TO STDOUT'); };
    okerr FATAL => exec => qr/unexpected status code/;

    ok !eval { $conn->exec('SELEXT'); };
    okerr ERROR => exec => qr/syntax error/;

    ok !defined $conn->exec('');
    is $conn->exec('SELECT 1'), 1;

    ok !eval { $conn->q('SELEXT')->param_types; };
    okerr ERROR => prepare => qr/syntax error/;

    is $conn->exec('SET client_encoding=utf8'), undef;
};


subtest '$st prepare & exec', sub {
    {
        my $st = $conn->q('SELECT 1');
        is_deeply $st->param_types, [];
        is_deeply $st->columns, [{ name => '?column?', oid => 23 }];

        ok !eval { $st->cache; 1 };
        like $@, qr/Invalid attempt to change statement configuration/;
        $st = $st->text;

        is $conn->exec('SELECT 1 FROM pg_prepared_statements'), 1;

        is $st->exec, 1;

        ok !eval { $st->exec; 1 };
        like $@, qr/Invalid attempt to execute statement multiple times/;
    }

    {
        my $st = $conn->q("SELECT \$1::int AS a, \$2::char(5) AS \"\x{1F603}\"", 1, 2);
        is_deeply $st->param_types, [ 23, 1042 ];
        is_deeply $st->columns, [
            { oid => 23, name => 'a' },
            { oid => 1042, name => "\x{1F603}", typemod => 9 },
        ];
        is $st->exec, 1;
    }

    is $conn->exec('SELECT 1 FROM pg_prepared_statements'), 0;

    ok !eval { $conn->q('SELECT 1', 1)->exec; 1 };
    like $@, qr/bind message supplies 1 parameters, but prepared statement/;

    ok !eval { $conn->q('SELECT $1')->exec; 1 };
    like $@, qr/bind message supplies 0 parameters, but prepared statement/;

    # prepare + describe won't let us detect empty queries, hmm...
    is_deeply $conn->q('')->param_types, [];
    is_deeply $conn->q('')->columns, [];

    ok !eval { $conn->q('')->exec; 1 };
    okerr FATAL => exec => qr/unexpected status code/;

    is $conn->q('SET client_encoding=utf8')->exec, undef;

    ok !eval { $conn->q('select 1; select 2')->exec; 1 };
    okerr ERROR => exec => qr/cannot insert multiple commands into a prepared statement/;

    # Interleaved
    {
        my $x = $conn->q('SELECT 1 as a');
        my $y = $conn->q('SELECT 2 as b');
        is_deeply $x->columns, [ { oid => 23, name => 'a' } ];
        is_deeply $y->columns, [ { oid => 23, name => 'b' } ];
        is $x->val, 1;
        is $y->val, 2;
    }
};

subtest '$st->val', sub {
    ok !eval { $conn->q('SELECT')->val; 1 };
    like $@, qr/on query returning no data/;

    ok !eval { $conn->q('SELECT 1, 2')->val; 1 };
    like $@, qr/on query returning more than one column/;

    ok !eval { $conn->q('SELECT 1 UNION SELECT 2')->val; 1 };
    like $@, qr/on query returning more than one row/;

    ok !defined $conn->q('SELECT 1 WHERE false')->val;
    ok !defined $conn->q('SELECT null')->val;
    is $conn->q('SELECT $1::text', "\x{1F603}")->val, "\x{1F603}";
};

subtest '$st->rowl', sub {
    ok !eval { $conn->q('SELECT 1 UNION SELECT 2')->rowl; 1 };
    like $@, qr/on query returning more than one row/;

    ok !eval { $conn->q('SELEXT')->rowl; 1; };
    is scalar $conn->q('SELECT')->rowl, 0;
    is scalar $conn->q('SELECT 1, 2')->rowl, 2;
    is_deeply [$conn->q('SELECT')->rowl], [];
    is_deeply [$conn->q('SELECT 1, null')->rowl], [1, undef];
    is_deeply [$conn->q('SELECT 1, $1', undef)->rowl], [1, undef];
    is_deeply [$conn->q('SELECT 1, $1::int', undef)->text_params(0)->rowl], [1, undef];
    is_deeply [$conn->q('SELECT 1 WHERE false')->rowl], [];
};

subtest '$st->rowa', sub {
    ok !eval { $conn->q('SELECT 1 UNION SELECT 2')->rowa; 1 };
    like $@, qr/on query returning more than one row/;

    ok !eval { $conn->q('SELEXT')->rowa; 1; };
    is $conn->q('SELECT 1 WHERE false')->rowa, undef;
    is_deeply $conn->q('SELECT')->rowa, [];
    is_deeply $conn->q('SELECT 1, 2')->rowa, [1, 2];
    is_deeply $conn->q('SELECT 1, null')->rowa, [1, undef];
    is_deeply $conn->q('SELECT 1, $1', undef)->rowa, [1, undef];
    is_deeply $conn->q('SELECT 1, $1::int', undef)->text_params(0)->rowa, [1, undef];

};

subtest '$st->rowh', sub {
    ok !eval { $conn->q('SELECT 1 UNION SELECT 2')->rowh; 1 };
    like $@, qr/on query returning more than one row/;

    ok !eval { $conn->q('SELECT 1 as a, 2 as a')->rowh; 1 };
    like $@, qr/Query returns multiple columns with the same name/;

    is $conn->q('SELECT 1 WHERE false')->rowh, undef;
    is_deeply $conn->q('SELECT')->rowh, {};
    is_deeply $conn->q('SELECT 1 as a, 2 as b')->rowh, {a => 1, b => 2};
    is_deeply $conn->q('SELECT 1 as a, null as b')->rowh, {a => 1, b => undef};
    is_deeply $conn->q('SELECT 1 as a, $1::int as b', undef)->rowh, {a => 1, b => undef};
};

subtest '$st->alla', sub {
    is_deeply $conn->q('SELECT 1 WHERE false')->alla, [];
    is_deeply $conn->q('SELECT')->alla, [[]];
    is_deeply $conn->q('SELECT 1')->alla, [[1]];
    is_deeply $conn->q('SELECT 1, null UNION ALL SELECT NULL, 2')->alla, [[1,undef],[undef,2]];
};

subtest '$st->allh', sub {
    ok !eval { $conn->q('SELECT 1 as a, 2 as a')->allh; 1 };
    like $@, qr/Query returns multiple columns with the same name/;

    is_deeply $conn->q('SELECT 1 WHERE false')->allh, [];
    is_deeply $conn->q('SELECT')->allh, [{}];
    is_deeply $conn->q('SELECT 1 a')->allh, [{a=>1}];
    is_deeply $conn->q('SELECT 1 a, null b UNION ALL SELECT NULL, 2')->allh, [{a=>1,b=>undef},{a=>undef,b=>2}];
};

subtest '$st->flat', sub {
    is_deeply $conn->q('SELECT 1 WHERE false')->flat, [];
    is_deeply $conn->q('SELECT')->flat, [];
    is_deeply $conn->q('SELECT 1')->flat, [1];
    is_deeply $conn->q('SELECT 1, null UNION ALL SELECT NULL, 2')->flat, [1,undef,undef,2];
};

subtest '$st->kvv', sub {
    ok !eval { $conn->q('SELECT')->kvv; 1; };
    like $@, qr/returning no data/;

    ok !eval { $conn->q('SELECT 1, 2, 3')->kvv; 1; };
    like $@, qr/returning more than two columns/;

    ok !eval { $conn->q('SELECT 1 UNION ALL SELECT 1')->kvv; 1; };
    like $@, qr/is duplicated/;

    is_deeply $conn->q('SELECT 1 WHERE false')->kvv, {};
    is_deeply $conn->q('SELECT 1')->kvv, {1=>1};
    is_deeply $conn->q('SELECT 1, null UNION ALL SELECT 3, 2')->kvv, {1=>undef,3=>2};
    $conn->q('SELECT 1')->kvv->{1} = 0;
};

subtest '$st->kva', sub {
    ok !eval { $conn->q('SELECT')->kva; 1; };
    like $@, qr/returning no data/;

    ok !eval { $conn->q('SELECT 1 UNION ALL SELECT 1')->kva; 1; };
    like $@, qr/is duplicated/;

    is_deeply $conn->q('SELECT 1 WHERE false')->kva, {};
    is_deeply $conn->q('SELECT 1')->kva, {1=>[]};
    is_deeply $conn->q("SELECT 1, null, 'hi' UNION ALL SELECT 3, 2, 'ok'")->kva,
        {1=>[undef,'hi'], 3=>[2, 'ok']};
};

subtest '$st->kvh', sub {
    ok !eval { $conn->q('SELECT')->kvh; 1; };
    like $@, qr/returning no data/;

    ok !eval { $conn->q('SELECT 1 UNION ALL SELECT 1')->kvh; 1; };
    like $@, qr/is duplicated/;

    ok !eval { $conn->q('SELECT 1, 2, 3')->kvh; 1; };
    like $@, qr/Query returns multiple columns with the same name/;

    is_deeply $conn->q('SELECT 1 WHERE false')->kvh, {};
    is_deeply $conn->q('SELECT 1')->kvh, {1=>{}};
    is_deeply $conn->q("SELECT 1 as a , null as a, 'hi' as b UNION ALL SELECT 3, 2, 'ok'")->kvh,
        {1=>{a=>undef,b=>'hi'}, 3=>{a=>2,b=>'ok'}};
};

subtest 'txn', sub {
    $conn->exec('CREATE TEMPORARY TABLE fupg_tst (id int)');
    $conn->txn->exec('INSERT INTO fupg_tst VALUES (1)'); # rolled back
    is $conn->q('SELECT COUNT(*) FROM fupg_tst')->val, 0;

    my $st = $conn->q('SELECT COUNT(*) FROM fupg_tst');
    my $sst;
    {
        my $txn = $conn->txn;
        is $conn->status, 'txn_idle';
        is $txn->status, 'idle';

        ok !eval { $st->exec; 1 };
        like $@, qr/Invalid cross-transaction/;

        ok !eval { $conn->exec('SELECT 1'); 1 };
        like $@, qr/Invalid operation on the top-level connection/;
        ok !eval { $conn->q('SELECT 1'); 1 };
        like $@, qr/Invalid operation on the top-level connection/;
        ok !eval { $conn->txn; 1 };
        like $@, qr/Invalid operation on the top-level connection/;

        $txn->exec('INSERT INTO fupg_tst VALUES (1)');
        $sst = $txn->q('SELECT 1');

        is $conn->status, 'txn_idle';
        is $txn->status, 'idle';
        $txn->commit;
        is $conn->status, 'txn_done';
        is $txn->status, 'done';

        ok !eval { $txn->rollback; 1 };
        like $@, qr/Invalid operation on a transaction that has already been marked as done/;
        ok !eval { $txn->commit; 1 };
        like $@, qr/Invalid operation on a transaction that has already been marked as done/;
        ok !eval { $txn->txn; 1 };
        like $@, qr/Invalid operation on a transaction that has already been marked as done/;
        ok !eval { $txn->exec('select 1'); 1 };
        like $@, qr/Invalid operation on a transaction that has already been marked as done/;
        ok !eval { $txn->q('select 1'); 1 };
        like $@, qr/Invalid operation on a transaction that has already been marked as done/;

        ok !eval { $conn->exec('SELECT 1'); 1 };
        like $@, qr/Invalid operation on the top-level connection/;
    }
    is $conn->status, 'idle';
    is $st->val, 1;
    ok !eval { $sst->exec; 1 };
    like $@, qr/Invalid cross-transaction/;

    {
        my $txn = $conn->txn;
        ok !eval { $txn->exec('SELEXT'); 1 }; # puts txn in error state
        is $conn->status, 'txn_error';
        is $txn->status, 'error';
        ok !eval { $txn->exec('SELECT 1'); 1 };
        like $@, qr/current transaction is aborted/;

        $txn->rollback;
        is $conn->status, 'txn_done';
        is $txn->status, 'done';
    }
    ok $conn->exec('SELECT 1');

    {
        my $txn = $conn->txn;
        my $st = $txn->q('SELECT count(*) FROM fupg_tst WHERE id = 2');
        {
            my $sub = $txn->txn;
            is $conn->status, 'txn_idle';
            is $txn->status, 'txn_idle';
            is $sub->status, 'idle';

            $sub->exec('INSERT INTO fupg_tst VALUES (2)');
            ok !eval { $sub->exec('SELEXT'); 1 };

            ok !eval { $txn->rollback; 1 };
            like $@, qr/Invalid operation on transaction/;

            is $conn->status, 'txn_error';
            is $txn->status, 'txn_error';
            is $sub->status, 'error';
        }
        is $conn->status, 'txn_idle';
        is $txn->status, 'idle';
        is $st->val, 0;

        $st = $txn->q('SELECT count(*) FROM fupg_tst WHERE id = 2');
        {
            my $sub = $txn->txn;
            $sub->exec('INSERT INTO fupg_tst VALUES (2)');
            $sub->commit;
            is $conn->status, 'txn_idle';
            is $txn->status, 'txn_idle'; # No way to tell that it's actually done
            is $sub->status, 'done';
        }
        is $st->val, 1;
    }
    is $conn->status, 'idle';

    {
        my $txn = $conn->txn;
        my $sub = $txn->txn;
        undef $txn; # sub keeps a ref on $txn
        is $sub->status, 'idle';
        is $conn->status, 'txn_idle';
        $sub->exec('INSERT INTO fupg_tst VALUES (3)');
        $sub->commit;
    }
    # We didn't commit $txn, so $sub got aborted as well
    is $conn->q('SELECT count(*) FROM fupg_tst WHERE id = 3')->val, 0;
};

{
    local $_ = 'x';
    my $st = $conn->q('SELECT $1', $_);
    $_ = 'y';
    is $st->val, 'x', 'shallow copy';
}

{
    my $x = [1,2];
    my $st = $conn->q('SELECT $1::int[]', $x)->text(0);
    $x->[1] = 3;
    is_deeply $st->val, [1,3], 'not deep copy';
}


{
    # Exact format returned by escape_literal() can differ between Postgres versions and configurations.
    my $x = q{"' \" \\};
    is $conn->q('SELECT '.$conn->escape_literal($x))->val, $x;

    # Format can also change, but unsure how to test this otherwise.
    is $conn->escape_identifier('hel\l"o'), '"hel\l""o"';
}

subtest 'Prepared statement cache', sub {
    $conn->cache_size(2);
    my $txn = $conn->txn;
    $txn->cache;
    my $numexec = sub($sql) {
        $txn->q('SELECT generic_plans + custom_plans FROM pg_prepared_statements WHERE statement = $1', $sql)->cache(0)->val
    };
    is $txn->q('SELECT 1')->val, 1;
    is $numexec->('SELECT 1'), 1;

    my $sql = 'SELECT $1::int as a, $2::text as b';
    ok !defined $numexec->($sql);

    my $params = $txn->q($sql)->param_types;
    is_deeply $params, [23, 25];
    is $numexec->($sql), 0;
    my $cparams = $txn->q($sql)->param_types;
    is_deeply $cparams, $params;

    my $cols = $txn->q($sql)->columns;
    is_deeply $cols, [{ name => 'a', oid => 23 }, { name => 'b', oid => 25 }];
    my $ccols = $txn->q($sql)->columns;
    is_deeply $ccols, $cols;

    $txn->q($sql, 0, '')->exec;
    is $numexec->($sql), 1;
    $txn->q($sql, 0, '')->exec;
    is $numexec->($sql), 2;

    is $numexec->('SELECT 1'), 1;
    $txn->q('SELECT 2')->exec;
    ok !defined $numexec->('SELECT 1');
    is $numexec->('SELECT 2'), 1;

    $conn->cache_size(1);
    ok !defined $numexec->('SELECT 1');
    ok !defined $numexec->($sql);
    is $numexec->('SELECT 2'), 1;

    $conn->cache_size(0);
    ok !defined $numexec->($sql);
    ok !defined $numexec->('SELECT 2');
};


subtest 'Tracing', sub {
    my @log;
    $conn->query_trace(sub($st) { push @log, $st });

    is_deeply $conn->q('SELECT 1 AS a, $1 AS b', 123)->text_params(0)->rowa, [ 1, 123 ];
    is scalar @log, 1;
    my $st = shift @log;
    is ref $st, 'FU::Pg::st';
    is_deeply $st->param_types, [ 25 ];
    is_deeply $st->param_values, [ 123 ];
    is_deeply $st->columns, [{ name => 'a', oid => 23 }, { name => 'b', oid => 25 }];
    is $st->nrows, 1;
    is $st->query, 'SELECT 1 AS a, $1 AS b';
    ok $st->exec_time > 0 && $st->exec_time < 1;
    ok $st->prepare_time > 0 && $st->prepare_time < 1;
    ok !$st->get_cache;
    ok !$st->get_text_params;
    ok $st->get_text_results;

    $conn->exec('SET client_encoding=UTF8');
    is scalar @log, 1;
    $st = shift @log;
    is ref $st, 'FU::Pg::st';
    is_deeply $st->param_types, [];
    is_deeply $st->param_values, [];
    is_deeply $st->columns, [];
    is $st->nrows, 0;
    is $st->query, 'SET client_encoding=UTF8';
    ok $st->exec_time > 0 && $st->exec_time < 1;
    ok !defined $st->prepare_time;
    ok !$st->get_cache;
    ok $st->get_text_params;
    ok $st->get_text_results;

    $conn->query_trace(undef);
    $conn->exec('SELECT 1');
    is scalar @log, 0;
};

{
    my $st = $conn->q("SELECT 1");
    undef $conn; # statement keeps the connection alive
    is $st->val, 1;
}

done_testing;
