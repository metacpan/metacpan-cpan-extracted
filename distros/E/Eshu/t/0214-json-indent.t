use strict;
use warnings;
use Test::More;
use Eshu;

# ── compact → 2-space ────────────────────────────────────────────

{
    my $compact = '{"a":1,"b":[1,2],"c":{"d":3}}';
    my $out = Eshu->indent_json($compact, indent_char => ' ', indent_width => 2);
    my $expected = <<'END';
{
  "a": 1,
  "b": [
    1,
    2
  ],
  "c": {
    "d": 3
  }
}
END
    is($out, $expected, 'compact → 2-space formatted');
}

# ── compact → 4-space ────────────────────────────────────────────

{
    my $compact = '{"x":1,"y":2}';
    my $out = Eshu->indent_json($compact, indent_char => ' ', indent_width => 4);
    my $expected = <<'END';
{
    "x": 1,
    "y": 2
}
END
    is($out, $expected, 'compact → 4-space formatted');
}

# ── compact → tab ────────────────────────────────────────────────

{
    my $compact = '{"x":1}';
    my $out = Eshu->indent_json($compact, indent_char => "\t");
    is($out, "{\n\t\"x\": 1\n}\n", 'compact → tab-indented');
}

# ── 2-space → 4-space ────────────────────────────────────────────

{
    my $two = "{\n  \"a\": 1,\n  \"b\": 2\n}\n";
    my $out  = Eshu->indent_json($two, indent_char => ' ', indent_width => 4);
    my $expected = "{\n    \"a\": 1,\n    \"b\": 2\n}\n";
    is($out, $expected, '2-space → 4-space conversion');
}

# ── 4-space → 2-space ────────────────────────────────────────────

{
    my $four = "{\n    \"a\": 1,\n    \"b\": 2\n}\n";
    my $out  = Eshu->indent_json($four, indent_char => ' ', indent_width => 2);
    my $expected = "{\n  \"a\": 1,\n  \"b\": 2\n}\n";
    is($out, $expected, '4-space → 2-space conversion');
}

# ── tab → 2-space ─────────────────────────────────────────────────

{
    my $tab = "{\n\t\"a\": 1\n}\n";
    my $out = Eshu->indent_json($tab, indent_char => ' ', indent_width => 2);
    is($out, "{\n  \"a\": 1\n}\n", 'tab → 2-space conversion');
}

# ── indent_string dispatch ────────────────────────────────────────

{
    my $compact = '{"a":1}';
    my $out = Eshu->indent_string($compact, lang => 'json');
    like($out, qr/^\{$/m,        'indent_string json: open brace');
    like($out, qr/^\s+"a": 1$/m, 'indent_string json: key/value');
    like($out, qr/^\}$/m,        'indent_string json: close brace');
}

# ── default 2-space via indent_json ───────────────────────────────

{
    my $out = Eshu->indent_json('{"x":1}');
    is($out, "{\n  \"x\": 1\n}\n", 'indent_json default is 2-space');
}

# ── deeply nested indent widths ───────────────────────────────────

{
    my $compact = '{"a":{"b":{"c":1}}}';
    my $out = Eshu->indent_json($compact, indent_char => ' ', indent_width => 2);
    like($out, qr/^  "a": \{$/m,     'depth 1 key at 2-space');
    like($out, qr/^    "b": \{$/m,   'depth 2 key at 4-space');
    like($out, qr/^      "c": 1$/m,  'depth 3 value at 6-space');
}

done_testing;
