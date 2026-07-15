use strict;
use warnings;
use Test::More;
use Eshu;

sub sql { Eshu->indent_sql($_[0]) }

# basic SELECT/FROM/WHERE
{
    my $input = "SELECT\ncol1,\ncol2\nFROM\ntable1\nWHERE\ncol1 = 1\n";
    my $expected = "SELECT\n    col1,\n    col2\nFROM\n    table1\nWHERE\n    col1 = 1\n";
    is(sql($input), $expected, 'SELECT/FROM/WHERE');
}

# JOIN with ON — ON is a continuation of JOIN, not a clause reset
{
    my $input = <<'END';
SELECT
col1
FROM
t1
JOIN t2
ON t1.id = t2.id
WHERE
t1.x = 1
END
    my $expected = <<'END';
SELECT
    col1
FROM
    t1
JOIN t2
    ON t1.id = t2.id
WHERE
    t1.x = 1
END
    is(sql($input), $expected, 'JOIN/ON');
}

# GROUP BY / HAVING / ORDER BY / LIMIT — all clause keywords at depth 0
{
    my $input = <<'END';
SELECT col, COUNT(*)
FROM t
GROUP BY col
HAVING COUNT(*) > 1
ORDER BY col
LIMIT 10
END
    my $expected = <<'END';
SELECT col, COUNT(*)
FROM t
GROUP BY col
HAVING COUNT(*) > 1
ORDER BY col
LIMIT 10
END
    is(sql($input), $expected, 'GROUP BY / ORDER BY / LIMIT');
}

# UNION — SELECT after UNION resets to depth 0 as a clause keyword
{
    my $input = <<'END';
SELECT a FROM t1
UNION
SELECT a FROM t2
END
    my $expected = <<'END';
SELECT a FROM t1
UNION
SELECT a FROM t2
END
    is(sql($input), $expected, 'UNION');
}

# already-correct input is preserved
{
    my $input = <<'END';
SELECT
    col1,
    col2
FROM
    table1
WHERE
    col1 = 1
END
    is(sql($input), $input, 'idempotent: correct input unchanged');
}

done_testing;
