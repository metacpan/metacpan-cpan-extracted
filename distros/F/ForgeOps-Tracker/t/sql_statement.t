use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::EventBuilder;
use ForgeOps::Tracker::SqlStatement qw(find_in mask objects);

subtest 'find_in reads the statement out of DBI and SQLite error text' => sub {
    is(find_in('DBD::Pg::st execute failed: ERROR: boom [for Statement "SELECT 1"] at app.pl line 3.'), 'SELECT 1');
    is(
        find_in('DBD::mysql::st execute failed: bad [for Statement "CALL refund_order(?)" with ParamValues: 1=\'a@b.co\'] at app.pl line 3.'),
        'CALL refund_order(?)',
        'the ParamValues part is never read'
    );
    is(find_in('near "FORM": syntax error (code 1 SQLITE_ERROR), while compiling: SELECT * FORM t'), 'SELECT * FORM t');
    is(find_in('the multi-line [for Statement "SELECT 1' . "\n" . 'FROM t"] error'), "SELECT 1\nFROM t");
};

subtest 'find_in reads an exception object through ->message and returns undef without SQL' => sub {
    {
        package FakeDbError;
        sub new { bless { message => $_[1] }, $_[0] }
        sub message { $_[0]{message} }
    }
    is(find_in(FakeDbError->new('failed [for Statement "SELECT 2"]')), 'SELECT 2');
    is(find_in('just a plain error at app.pl line 3.'), undef);
    is(find_in(undef), undef);
};

subtest 'mask replaces strings and numbers, leaving identifiers and placeholders' => sub {
    is(
        mask(q{SELECT * FROM orders2 WHERE email = 'a@b.co' AND id = 42 AND x = $1}),
        'SELECT * FROM orders2 WHERE email = ? AND id = ? AND x = $1'
    );
    is(mask('SELECT price * 1.5 FROM t'), 'SELECT price * ? FROM t');
    is(mask(q{EXEC sp_x @t = 'it''s'}), 'EXEC sp_x @t = ?');
    is(mask(q{SELECT 1 WHERE n = 'oops}), 'SELECT ? WHERE n = ?');
    is(mask('DO $b$ BEGIN PERFORM 1; END $b$'), 'DO ?');
};

subtest 'mask is idempotent, truncates, and returns undef for blank input' => sub {
    my $once = mask(q{SELECT * FROM t WHERE a = 'x' AND b = 9});
    is(mask($once), $once);
    is(length(mask('SELECT ' . ('a, ' x 3000) . ' b')), 4003);
    is(mask('  '), undef);
    is(mask(undef), undef);
};

subtest 'objects finds a stored procedure with its schema' => sub {
    is_deeply(objects('EXEC dbo.sp_refund_order @id = ?'), { operation => 'EXEC', procedures => ['dbo.sp_refund_order'], relations => [] });
    is_deeply(objects('CALL refund_order(?, ?)')->{procedures}, ['refund_order']);
    is_deeply(objects('SELECT refund_order(?, ?)')->{procedures}, ['refund_order']);
};

subtest 'objects finds views, joined tables and table functions' => sub {
    is_deeply(objects('SELECT * FROM v_totals t JOIN public.customers c ON c.id = t.id')->{relations}, ['v_totals', 'public.customers']);
    is_deeply(objects('SELECT * FROM get_open_orders(?) o')->{procedures}, ['get_open_orders']);
};

subtest 'objects does not misread column lists or builtins, and returns undef for garbage' => sub {
    is_deeply(objects('INSERT INTO audit_log (a) VALUES (?)')->{procedures}, []);
    is_deeply(objects('SELECT count(*) FROM orders')->{procedures}, []);
    is(objects('garbage'), undef);
};

subtest 'EventBuilder sends the procedure name by default, the masked statement only when opted in' => sub {
    my $error = q{DBD::Pg::st execute failed: boom [for Statement "EXEC dbo.sp_refund_order @order_id = 8814, @note = 'a@b.co'"] at app.pl line 3.};
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{environment} = 'production';

    my $payload = ForgeOps::Tracker::EventBuilder->new($config)->build($error);
    is_deeply($payload->{sql_objects}{procedures}, ['dbo.sp_refund_order']);
    ok(!exists $payload->{sql_statement});

    $config->{capture_sql_statement} = 1;
    is(ForgeOps::Tracker::EventBuilder->new($config)->build($error)->{sql_statement}, 'EXEC dbo.sp_refund_order @order_id = ?, @note = ?');

    $config->{capture_sql_objects} = 0;
    $config->{capture_sql_statement} = 0;
    my $off = ForgeOps::Tracker::EventBuilder->new($config)->build($error);
    ok(!exists $off->{sql_objects} && !exists $off->{sql_statement});

    $config->{capture_sql_objects} = 1;
    ok(!exists ForgeOps::Tracker::EventBuilder->new($config)->build('plain error at x line 1.')->{sql_objects});
};

done_testing;
