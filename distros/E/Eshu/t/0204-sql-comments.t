use strict;
use warnings;
use Test::More;
use Eshu;

sub sql { Eshu->indent_sql($_[0]) }

# line comment -- should not affect depth
{
    my $input = <<'END';
SELECT
col1, -- important column
col2
FROM
t
END
    my $expected = <<'END';
SELECT
    col1, -- important column
    col2
FROM
    t
END
    is(sql($input), $expected, '-- comment on continuation line');
}

# block comment /* */
{
    my $input = <<'END';
SELECT
/* pick these two */
col1,
col2
FROM t
END
    my $expected = <<'END';
SELECT
    /* pick these two */
    col1,
    col2
FROM t
END
    is(sql($input), $expected, '/* */ comment on continuation line');
}

# brace/paren inside comment not counted
{
    my $input = <<'END';
SELECT
col1 -- FROM t (fake)
FROM
real_table
END
    my $expected = <<'END';
SELECT
    col1 -- FROM t (fake)
FROM
    real_table
END
    is(sql($input), $expected, 'keywords in comment not parsed');
}

done_testing;
