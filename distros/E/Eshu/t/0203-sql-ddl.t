use strict;
use warnings;
use Test::More;
use Eshu;

sub sql { Eshu->indent_sql($_[0]) }

# CREATE TABLE — columns at depth 1, closing ) at depth 0
{
    my $input = <<'END';
CREATE TABLE foo (
id INT PRIMARY KEY,
name VARCHAR(255) NOT NULL,
val DECIMAL(10,2) DEFAULT 0
)
END
    my $expected = <<'END';
CREATE TABLE foo (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    val DECIMAL(10,2) DEFAULT 0
)
END
    is(sql($input), $expected, 'CREATE TABLE with columns');
}

# CREATE INDEX — ON is a continuation (not a clause reset)
{
    my $input = <<'END';
CREATE INDEX idx_foo
ON foo (name)
END
    my $expected = <<'END';
CREATE INDEX idx_foo
    ON foo (name)
END
    is(sql($input), $expected, 'CREATE INDEX');
}

# ALTER TABLE / continuation
{
    my $input = <<'END';
ALTER TABLE foo
ADD COLUMN extra INT
END
    my $expected = <<'END';
ALTER TABLE foo
    ADD COLUMN extra INT
END
    is(sql($input), $expected, 'ALTER TABLE');
}

done_testing;
