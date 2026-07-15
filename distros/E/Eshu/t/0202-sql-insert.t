use strict;
use warnings;
use Test::More;
use Eshu;

sub sql { Eshu->indent_sql($_[0]) }

# INSERT INTO / VALUES — VALUES is a clause keyword at depth 0
{
    my $input = <<'END';
INSERT INTO foo (a, b, c)
VALUES (1, 2, 3)
END
    my $expected = <<'END';
INSERT INTO foo (a, b, c)
VALUES (1, 2, 3)
END
    is(sql($input), $expected, 'INSERT INTO / VALUES');
}

# UPDATE / SET / continuation / WHERE
{
    my $input = <<'END';
UPDATE foo
SET a = 1,
b = 2
WHERE id = 3
END
    my $expected = <<'END';
UPDATE foo
SET a = 1,
    b = 2
WHERE id = 3
END
    is(sql($input), $expected, 'UPDATE / SET / WHERE');
}

# DELETE FROM / WHERE — WHERE is a clause keyword at depth 0
{
    my $input = <<'END';
DELETE FROM foo
WHERE id = 1
END
    my $expected = <<'END';
DELETE FROM foo
WHERE id = 1
END
    is(sql($input), $expected, 'DELETE FROM / WHERE');
}

done_testing;
