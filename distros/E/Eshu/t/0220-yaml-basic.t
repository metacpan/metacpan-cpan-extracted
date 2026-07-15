use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# simple flat key/value pairs (already at depth 0, idempotent)
{
    my $input = <<'END';
key1: value1
key2: value2
key3: value3
END
    is(yaml($input), $input, 'flat key/value pairs unchanged');
}

# nested mapping — normalise 4-space source to 2-space
{
    my $input = <<'END';
key1: value1
key2:
    nested: value2
    key3:
        deep: value3
END
    my $expected = <<'END';
key1: value1
key2:
  nested: value2
  key3:
    deep: value3
END
    is(yaml($input), $expected, 'nested mapping 4->2 space');
}

# already 2-space — idempotent
{
    my $input = <<'END';
outer:
  inner:
    deep: value
END
    is(yaml($input), $input, 'idempotent: 2-space input unchanged');
}

# empty lines preserved inside mappings
{
    my $input = <<'END';
key1: v1

key2: v2
END
    is(yaml($input), $input, 'empty lines preserved');
}

# multiple nesting levels
{
    my $input = <<'END';
a:
    b:
        c:
            d: leaf
END
    my $expected = <<'END';
a:
  b:
    c:
      d: leaf
END
    is(yaml($input), $expected, 'four levels of nesting 4->2 space');
}

done_testing;
