use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# literal block scalar | at top level — body preserved verbatim
{
    my $input = <<'END';
key: |
  line1
  line2
next: value
END
    my $expected = <<'END';
key: |
  line1
  line2
next: value
END
    is(yaml($input), $expected, 'literal block scalar body preserved');
}

# folded block scalar > at top level
{
    my $input = <<'END';
key: >
  folded line1
  folded line2
next: value
END
    my $expected = <<'END';
key: >
  folded line1
  folded line2
next: value
END
    is(yaml($input), $expected, 'folded block scalar body preserved');
}

# block scalar in nested context — re-normalise 4->2, body renormalised
{
    my $input = <<'END';
outer:
    key: |
        body line1
        body line2
    next: value
END
    my $expected = <<'END';
outer:
  key: |
    body line1
    body line2
  next: value
END
    is(yaml($input), $expected, 'block scalar in nested context normalised');
}

# block scalar with chomp indicator |-
{
    my $input = <<'END';
key: |-
  content line
next: value
END
    my $expected = <<'END';
key: |-
  content line
next: value
END
    is(yaml($input), $expected, 'block scalar with chomp indicator |-');
}

done_testing;
