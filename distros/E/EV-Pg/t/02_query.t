use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 27;

# Test simple query
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select 1 as num, 'hello' as greeting", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'query: no error');
        is(ref $rows, 'ARRAY', 'query: got arrayref');
        is(scalar @$rows, 1, 'query: 1 row');
        is(scalar @{$rows->[0]}, 2, 'query: 2 columns');
        is($rows->[0][0], '1', 'query: value(0,0)');
        is($rows->[0][1], 'hello', 'query: value(0,1)');
        EV::break;
    });
});

# Test query_params
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query_params("select \$1::int + \$2::int as sum", [10, 20], sub {
        my ($rows, $err) = @_;
        ok(!$err, 'query_params: no error');
        is($rows->[0][0], '30', 'query_params: 10+20=30');
        EV::break;
    });
});

# Test NULL params
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query_params("select \$1::text is null as isnull", [undef], sub {
        my ($rows, $err) = @_;
        ok(!$err, 'null param: no error');
        is($rows->[0][0], 't', 'null param: IS NULL is true');
        EV::break;
    });
});

# Test that NULs in params raise a clear error rather than silently
# truncating (libpq strlens text-format params, so we must detect NULs
# in the XS layer).
with_pg(cb => sub {
    my ($pg) = @_;
    eval {
        $pg->query_params("select \$1::text", ["ab\0cd"], sub { });
    };
    like($@, qr/NUL byte/, 'NUL in text param: croak rather than truncate');
    like($@, qr/parameter 0/, 'NUL in text param: error names the parameter');
    EV::break;
});

# Test multi-row result
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select 1 as a, 2 as b union all select 3, 4", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multi-row: no error');
        is_deeply($rows, [['1','2'],['3','4']], 'multi-row: correct values');
        EV::break;
    });
});

# Test multi-statement query (only last result delivered)
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select 1 as a; select 2 as b; select 3 as c", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multi-statement: no error');
        is(scalar @$rows, 1, 'multi-statement: 1 row (last result)');
        is($rows->[0][0], '3', 'multi-statement: last result delivered');
        EV::break;
    });
});

# Trailing semicolons should not turn result into PGRES_EMPTY_QUERY error
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select 42 as val;", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'trailing semicolon: no error');
        is($rows->[0][0], '42', 'trailing semicolon: correct value');
        EV::break;
    });
});

# Multiple trailing semicolons
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select 'ok';;;", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multiple trailing semicolons: no error');
        is($rows->[0][0], 'ok', 'multiple trailing semicolons: correct value');
        EV::break;
    });
});

# Multi-statement with trailing semicolon
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select 1; select 2;", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multi-statement trailing semicolon: no error');
        is($rows->[0][0], '2', 'multi-statement trailing semicolon: last result');
        EV::break;
    });
});

# Bare semicolon (no real statement) should be an error
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query(";", sub {
        my ($rows, $err) = @_;
        ok($err, 'bare semicolon: got error');
        ok(!defined $rows, 'bare semicolon: no data');
        EV::break;
    });
});

# Truly empty query should still be an error
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("", sub {
        my ($rows, $err) = @_;
        ok($err, 'empty query: got error');
        ok(!defined $rows, 'empty query: no data');
        EV::break;
    });
});
