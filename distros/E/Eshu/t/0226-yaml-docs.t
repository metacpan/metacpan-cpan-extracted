use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# document marker --- emitted at depth 0
{
    my $input = <<'END';
---
key: value
END
    is(yaml($input), $input, '--- marker unchanged');
}

# multi-document file
{
    my $input = <<'END';
---
key1: value1
---
key2: value2
END
    is(yaml($input), $input, 'multi-document markers preserved');
}

# depth reset after --- marker
{
    my $input = <<'END';
---
outer:
    nested: value
---
top: other
END
    my $expected = <<'END';
---
outer:
  nested: value
---
top: other
END
    is(yaml($input), $expected, 'depth reset after --- normalises next doc');
}

# end-of-document marker ...
{
    my $input = <<'END';
key: value
...
END
    is(yaml($input), $input, '... end marker preserved');
}

done_testing;
