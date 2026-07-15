use strict;
use warnings;
use Test::More;
use Eshu;

sub j2 { Eshu->indent_json($_[0], indent_char => ' ', indent_width => 2) }
sub j4 { Eshu->indent_json($_[0], indent_char => ' ', indent_width => 4) }

# ── empty object ─────────────────────────────────────────────────

is(j2('{}'), "{}\n", 'empty object stays inline');

# ── empty array ──────────────────────────────────────────────────

is(j2('[]'), "[]\n", 'empty array stays inline');

# ── flat object: compact → formatted ─────────────────────────────

{
    my $src = '{"a":1,"b":2}';
    my $expected = <<'END';
{
  "a": 1,
  "b": 2
}
END
    is(j2($src), $expected, 'compact flat object → 2-space formatted');
}

# ── flat array: compact → formatted ──────────────────────────────

{
    my $src = '[1,2,3]';
    my $expected = <<'END';
[
  1,
  2,
  3
]
END
    is(j2($src), $expected, 'compact flat array → 2-space formatted');
}

# ── null, true, false values ──────────────────────────────────────

{
    my $src = '{"a":null,"b":true,"c":false}';
    my $expected = <<'END';
{
  "a": null,
  "b": true,
  "c": false
}
END
    is(j2($src), $expected, 'null/true/false values formatted correctly');
}

# ── string value ─────────────────────────────────────────────────

{
    my $src = '{"name":"Alice","city":"Berlin"}';
    my $expected = <<'END';
{
  "name": "Alice",
  "city": "Berlin"
}
END
    is(j2($src), $expected, 'string values formatted correctly');
}

# ── idempotent: already 2-space formatted ────────────────────────

{
    my $src = <<'END';
{
  "a": 1,
  "b": 2
}
END
    is(j2($src), $src, 'already-2-space JSON is idempotent');
}

# ── idempotent: empty containers inline ──────────────────────────

{
    my $src = <<'END';
{
  "obj": {},
  "arr": []
}
END
    is(j2($src), $src, 'formatted JSON with empty containers is idempotent');
}

# ── 4-space indent ────────────────────────────────────────────────

{
    my $src = '{"x":1}';
    my $expected = <<'END';
{
    "x": 1
}
END
    is(j4($src), $expected, '4-space indent');
}

# ── tab indent ───────────────────────────────────────────────────

{
    my $src = '{"x":1}';
    my $out = Eshu->indent_json($src, indent_char => "\t", indent_width => 1);
    is($out, "{\n\t\"x\": 1\n}\n", 'tab indent');
}

# ── single-key object ─────────────────────────────────────────────

{
    is(j2('{"key":"value"}'), "{\n  \"key\": \"value\"\n}\n",
       'single-key object');
}

# ── single-element array ──────────────────────────────────────────

{
    is(j2('[42]'), "[\n  42\n]\n", 'single-element array');
}

# ── detect_lang .json ─────────────────────────────────────────────

{
    is(Eshu->detect_lang('data.json'),  'json', 'detect_lang .json');
    is(Eshu->detect_lang('config.JSONC'), 'json', 'detect_lang .JSONC');
}

done_testing;
