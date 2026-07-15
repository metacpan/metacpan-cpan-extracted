use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_json($_[0], indent_char => ' ', indent_width => 2) }

# ── nested object ────────────────────────────────────────────────

{
    my $src = '{"a":{"b":1}}';
    my $expected = <<'END';
{
  "a": {
    "b": 1
  }
}
END
    is(j($src), $expected, 'nested object 2 levels');
}

# ── nested array ─────────────────────────────────────────────────

{
    my $src = '[[1,2],[3,4]]';
    my $expected = <<'END';
[
  [
    1,
    2
  ],
  [
    3,
    4
  ]
]
END
    is(j($src), $expected, 'nested array 2 levels');
}

# ── object containing array ───────────────────────────────────────

{
    my $src = '{"items":[1,2,3]}';
    my $expected = <<'END';
{
  "items": [
    1,
    2,
    3
  ]
}
END
    is(j($src), $expected, 'object with array value');
}

# ── array containing object ───────────────────────────────────────

{
    my $src = '[{"x":1},{"x":2}]';
    my $expected = <<'END';
[
  {
    "x": 1
  },
  {
    "x": 2
  }
]
END
    is(j($src), $expected, 'array of objects');
}

# ── deeply nested ────────────────────────────────────────────────

{
    my $src = '{"a":{"b":{"c":42}}}';
    my $expected = <<'END';
{
  "a": {
    "b": {
      "c": 42
    }
  }
}
END
    is(j($src), $expected, '3-level nested object');
}

# ── empty containers nested ───────────────────────────────────────

{
    my $src = '{"a":{},"b":[]}';
    my $expected = <<'END';
{
  "a": {},
  "b": []
}
END
    is(j($src), $expected, 'nested empty containers stay inline');
}

# ── mixed types in object ─────────────────────────────────────────

{
    my $src = '{"s":"hi","n":1,"b":true,"z":null,"a":[1],"o":{"x":2}}';
    my $out = j($src);
    like($out, qr/^\s+"s": "hi",?$/m,    'string in mixed object');
    like($out, qr/^\s+"n": 1,?$/m,       'number in mixed object');
    like($out, qr/^\s+"b": true,?$/m,    'bool in mixed object');
    like($out, qr/^\s+"z": null,?$/m,    'null in mixed object');
    like($out, qr/^\s+"a": \[/m,         'array value in mixed object');
    like($out, qr/^\s+"o": \{/m,         'object value in mixed object');
}

# ── idempotent: nested already-formatted ─────────────────────────

{
    my $src = <<'END';
{
  "a": {
    "b": 1
  },
  "c": [
    2,
    3
  ]
}
END
    is(j($src), $src, 'already-nested formatted JSON is idempotent');
}

done_testing;
