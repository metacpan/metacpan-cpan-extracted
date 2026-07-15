use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# anchors and aliases don't affect indentation
{
    my $input = <<'END';
defaults: &defaults
  host: localhost
  port: 8080
production:
  <<: *defaults
  host: prod.example.com
END
    is(yaml($input), $input, 'anchor and alias preserved');
}

# anchor on a scalar value
{
    my $input = <<'END';
version: &ver 1.0
service:
  api_version: *ver
END
    is(yaml($input), $input, 'inline anchor/alias idempotent');
}

# anchor normalisation 4->2
{
    my $input = <<'END';
base: &base
    key: value
extended:
    <<: *base
    extra: more
END
    my $expected = <<'END';
base: &base
  key: value
extended:
  <<: *base
  extra: more
END
    is(yaml($input), $expected, 'anchor block normalised 4->2');
}

done_testing;
