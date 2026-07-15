use strict;
use warnings;
use Test::More;
use Eshu;

sub sql { Eshu->indent_sql($_[0]) }

# parens inside single-quoted string don't affect depth
{
    my $input = <<'END';
SELECT
col1
FROM t
WHERE name = 'foo (bar)'
END
    my $expected = <<'END';
SELECT
    col1
FROM t
WHERE name = 'foo (bar)'
END
    is(sql($input), $expected, 'parens inside string do not affect depth');
}

# keywords inside string not parsed as clause keywords
{
    my $input = <<'END';
SELECT col
FROM t
WHERE s = 'hello FROM world WHERE 1=1'
AND x = 1
END
    my $expected = <<'END';
SELECT col
FROM t
WHERE s = 'hello FROM world WHERE 1=1'
    AND x = 1
END
    is(sql($input), $expected, 'keywords inside string not parsed');
}

# '' escaped quote inside string
{
    my $input = <<'END';
SELECT col
FROM t
WHERE s = 'it''s fine'
AND x = 1
END
    my $expected = <<'END';
SELECT col
FROM t
WHERE s = 'it''s fine'
    AND x = 1
END
    is(sql($input), $expected, "'' escaped single quote in string");
}

done_testing;
