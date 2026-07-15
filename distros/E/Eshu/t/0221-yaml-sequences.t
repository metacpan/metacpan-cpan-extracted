use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# simple sequence (2-space, idempotent)
{
    my $input = <<'END';
items:
  - item1
  - item2
  - item3
END
    is(yaml($input), $input, 'simple sequence idempotent');
}

# sequence normalise 4->2 space
{
    my $input = <<'END';
outer:
    items:
        - item1
        - item2
END
    my $expected = <<'END';
outer:
  items:
    - item1
    - item2
END
    is(yaml($input), $expected, 'nested sequence 4->2 space');
}

# sequence with nested mappings
{
    my $input = <<'END';
list:
  - name: alice
    age: 30
  - name: bob
    age: 25
END
    is(yaml($input), $input, 'sequence with nested mappings idempotent');
}

# top-level sequence
{
    my $input = <<'END';
- first
- second
- third
END
    is(yaml($input), $input, 'top-level sequence unchanged');
}

done_testing;
