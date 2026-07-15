use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# top-level comment
{
    my $input = <<'END';
# This is a comment
key: value
END
    is(yaml($input), $input, 'top-level comment unchanged');
}

# inline comment (after value)
{
    my $input = <<'END';
key: value # inline comment
other: val
END
    is(yaml($input), $input, 'inline comment preserved');
}

# indented comment normalised with its context (4->2)
{
    my $input = <<'END';
outer:
    # comment about inner
    inner: value
END
    my $expected = <<'END';
outer:
  # comment about inner
  inner: value
END
    is(yaml($input), $expected, 'indented comment normalised 4->2');
}

# comment between keys at same level
{
    my $input = <<'END';
key1: value1
# between keys
key2: value2
END
    is(yaml($input), $input, 'comment between sibling keys unchanged');
}

done_testing;
