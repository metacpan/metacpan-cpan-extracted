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

# The server's canonical masking cases ([statement, db.system, expected]), copied in whole so every
# SDK's port is checked against exactly the same set.
my @CORPUS = (
    ['SELECT * FROM orders WHERE email = \'a@b.co\' AND id = 42 LIMIT 10', undef, 'SELECT * FROM orders WHERE email = ? AND id = ? LIMIT ?'],
    ['EXEC sp_note @text = \'it\'\'s broken\'', undef, 'EXEC sp_note @text = ?'],
    ['SELECT 1 WHERE name = \'unterminated', undef, 'SELECT ? WHERE name = ?'],
    ['DO $body$ BEGIN PERFORM 1; END $body$', undef, 'DO ?'],
    ['SELECT "user id" FROM orders2 WHERE id = $1 AND v = sp_v2(?)', undef, 'SELECT "user id" FROM orders2 WHERE id = $1 AND v = sp_v2(?)'],
    ['SELECT price * 1.5 FROM t', undef, 'SELECT price * ? FROM t'],
    ['SELECT * FROM users WHERE name = E\'o\\\'brien\' AND id = 1', undef, 'SELECT * FROM users WHERE name = ? AND id = ?'],
    ['SELECT * FROM users WHERE name = \'o\\\'brien\' AND id = 1', undef, 'SELECT * FROM users WHERE name = ? AND id = ?'],
    ['SELECT * FROM t WHERE b = X\'DEADBEEF\' AND s = N\'uni\' AND u = U&\'d\\0061t\' AND e = e\'x\'', undef, 'SELECT * FROM t WHERE b = ? AND s = ? AND u = ? AND e = ?'],
    ['SELECT * FROM t WHERE a LIKE\'%secret%\'', undef, 'SELECT * FROM t WHERE a LIKE?'],
    ['SELECT * FROM t WHERE f = 0x1F AND b = 0b101 AND n = 3e10 AND m = 1.5E-3 AND k = .5', undef, 'SELECT * FROM t WHERE f = ? AND b = ? AND n = ? AND m = ? AND k = ?'],
    ['SELECT e, t.col, 1e5e FROM t', undef, 'SELECT e, t.col, 1e5e FROM t'],
    ['SELECT "user id" FROM t WHERE token = "abc123secret"', 'mysql', 'SELECT ? FROM t WHERE token = ?'],
    ['SELECT "user id" FROM t WHERE token = "abc123secret"', 'MariaDB', 'SELECT ? FROM t WHERE token = ?'],
    ['SELECT "user id" FROM t WHERE token = "abc123secret"', 'postgresql', 'SELECT "user id" FROM t WHERE token = "abc123secret"'],
    ['SELECT "user id" FROM t WHERE token = "abc123secret"', undef, 'SELECT "user id" FROM t WHERE token = "abc123secret"'],
    ['SELECT * FROM t WHERE a = \'x\' AND b = 9', undef, 'SELECT * FROM t WHERE a = ? AND b = ?'],
    ['SELECT * FROM t WHERE a = ? AND b = ?', undef, 'SELECT * FROM t WHERE a = ? AND b = ?'],
    ['SELECT * FROM t WHERE path = \'C:\\\\dir\\\\\' AND n = 5', undef, 'SELECT * FROM t WHERE path = ? AND n = ?'],
    ['INSERT INTO t (a, b) VALUES (-5, +3.25e+2)', undef, 'INSERT INTO t (a, b) VALUES (-?, +?)'],
    ['SELECT * FROM t WHERE a = \'secret\\', undef, 'SELECT * FROM t WHERE a = ?'],
    ['SELECT * FROM t WHERE a = "secret\\', 'mysql', 'SELECT * FROM t WHERE a = ?'],
);

subtest 'mask matches the server on every canonical case' => sub {
    for my $case (@CORPUS) {
        my ($statement, $system, $expected) = @$case;
        my $label = $statement . (defined $system ? " on $system" : '');
        is(mask($statement, system => $system), $expected, $label);
        is(mask($expected, system => $system), $expected, "$label, masked again");
    }
};

subtest 'mask covers a string longer than Perl repeats a complex group' => sub {
    is(mask(q{SELECT '} . ('ab\\x' x 40000) . q{' AND n = 5}), 'SELECT ? AND n = ?');
    is(mask('SELECT "' . ('xy' x 80000) . '" FROM t', system => 'mysql'), 'SELECT ? FROM t');
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
