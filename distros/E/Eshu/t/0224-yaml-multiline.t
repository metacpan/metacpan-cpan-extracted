use strict;
use warnings;
use Test::More;
use Eshu;

sub yaml { Eshu->indent_yaml($_[0]) }

# normalise a multi-level 4-space document to 2-space
{
    my $input = <<'END';
service:
    name: myapp
    version: 1.0
    config:
        host: localhost
        port: 8080
        database:
            name: mydb
            pool: 5
END
    my $expected = <<'END';
service:
  name: myapp
  version: 1.0
  config:
    host: localhost
    port: 8080
    database:
      name: mydb
      pool: 5
END
    is(yaml($input), $expected, 'deep 4->2 normalisation');
}

# normalise 4-space document with sequences
{
    my $input = <<'END';
servers:
    - host: web1
      port: 80
    - host: web2
      port: 80
END
    my $expected = <<'END';
servers:
  - host: web1
    port: 80
  - host: web2
    port: 80
END
    is(yaml($input), $expected, 'sequence with mapping values 4->2');
}

# already 2-space is idempotent
{
    my $input = <<'END';
a:
  b:
    c: 1
  d: 2
e: 3
END
    is(yaml($input), $input, '2-space input idempotent');
}

done_testing;
