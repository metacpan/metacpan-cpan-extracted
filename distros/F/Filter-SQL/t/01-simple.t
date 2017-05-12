#! /usr/bin/perl

use strict;
use warnings;
use Filter::SQL;
use Test::More;

BEGIN {
    if (! $ENV{FILTER_SQL_DBI}) {
        plan skip_all => 'Set FILTER_SQL_DBI to run these tests';
    } else {
        plan tests => 35;
    }
};

ok(ref Filter::SQL->dbh);

is(SELECT ROW 1;, 1);
is(SELECT ROW "test";, 'test');
is(SELECT ROW 'test';, 'test');
is(SELECT ROW "foo'a";, "foo'a");
my $a = 'foo';
is(SELECT ROW $a;, 'foo');
$a = "foo'a";
is(SELECT ROW $a;, $a);
is(SELECT ROW ${a};, $a);
is(SELECT ROW "hoge$a";, "hoge$a");
is(SELECT ROW 'hoge$a';, 'hoge$a');
$a = [ 5 ];
is(SELECT ROW $a->[0+0]+1;, 6);
$a = { foo => 3 };
is(SELECT ROW $a->{foo}-1;, 2);

is(SELECT ROW {1 + 2};, 3);

ok(EXEC CREATE TEMPORARY TABLE filter_sql_t (v INT NOT NULL););

is_deeply(
    [ SELECT ROW * FROM filter_sql_t; ],
    [],
);
is_deeply(
    { SELECT ROW AS HASH * FROM filter_sql_t; },
    {},
);

is_deeply(
    scalar(SELECT ROW * FROM filter_sql_t;),
    undef,
);

for (my $n = 0; $n < 3; $n++) {
    ok(INSERT INTO filter_sql_t (v) VALUES ($n););
}

is_deeply(
    scalar(SELECT ROW * FROM filter_sql_t;),
    0,
);

is_deeply(
    [ SELECT ROW * FROM filter_sql_t; ],
    [ 0 ],
);

is_deeply(
    { SELECT ROW AS HASH * FROM filter_sql_t; },
    { v => 0 },
);

my $sth = EXEC SELECT v FROM filter_sql_t;;
ok($sth);
is_deeply(
    $sth->fetchall_arrayref,
    [ [ 0 ], [ 1 ], [ 2 ], ],
);

is_deeply(
    [ SELECT * FROM filter_sql_t; ],
    [ [ 0 ], [ 1 ], [ 2 ], ],
);
is_deeply(
    [ SELECT AS HASH * FROM filter_sql_t; ],
    [ { v => 0 }, { v => 1 }, { v => 2 }, ],
);
is(SELECT ROW COUNT(*) FROM filter_sql_t;, 3);

ok(EXEC DROP TEMPORARY TABLE filter_sql_t;);

ok(EXEC CREATE TEMPORARY TABLE filter_sql_t (
    S INT NOT NULL,
    Q INT NOT NULL,
    G INT NOT NULL
););
ok(INSERT INTO filter_sql_t (`s`,`q`,`g`) VALUES (11,21,31););
ok(DELETE FROM filter_sql_t;);
ok(INSERT INTO filter_sql_t (s,q,g) VALUES (11,21,31););
is_deeply(
    [ SELECT ROW s,1,2,g FROM filter_sql_t; ],
    [ 11,1,2,31 ],
);
is_deeply(
    [ SELECT ROW q,1,g FROM filter_sql_t; ],
    [ 21,1,31 ],
);
