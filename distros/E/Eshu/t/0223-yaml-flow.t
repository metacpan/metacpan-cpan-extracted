use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# inline flow mapping (single line, unchanged)
{
    my $input = <<'END';
key: {a: 1, b: 2}
END
    is(yaml($input), $input, 'inline flow mapping unchanged');
}

# inline flow sequence (single line, unchanged)
{
    my $input = <<'END';
key: [1, 2, 3]
END
    is(yaml($input), $input, 'inline flow sequence unchanged');
}

# multi-line flow sequence (continuation lines verbatim)
{
    my $input = <<'END';
key:
  [1,
   2,
   3]
END
    my $expected = <<'END';
key:
  [1,
   2,
   3]
END
    is(yaml($input), $expected, 'multi-line flow sequence verbatim');
}

# nested inline flow
{
    my $input = <<'END';
config:
  env: {HOST: localhost, PORT: 8080}
  tags: [web, api, v2]
END
    is(yaml($input), $input, 'nested inline flow unchanged');
}

done_testing;
