use strict;
use warnings;
use Test::More;
use Eshu;

sub sql { Eshu->indent_sql($_[0]) }

# subquery in WHERE — closing ) is at depth 0 after paren closes
{
    my $input = <<'END';
SELECT col
FROM t
WHERE col IN (
SELECT col FROM other
)
END
    my $expected = <<'END';
SELECT col
FROM t
WHERE col IN (
    SELECT col FROM other
)
END
    is(sql($input), $expected, 'subquery in WHERE IN ()');
}

# CTE WITH — closing ) is at depth 0 after paren closes
{
    my $input = <<'END';
WITH cte AS (
SELECT id, val
FROM t
WHERE val > 0
)
SELECT *
FROM cte
END
    my $expected = <<'END';
WITH cte AS (
    SELECT id, val
    FROM t
    WHERE val > 0
)
SELECT *
FROM cte
END
    is(sql($input), $expected, 'CTE with WITH');
}

done_testing;
