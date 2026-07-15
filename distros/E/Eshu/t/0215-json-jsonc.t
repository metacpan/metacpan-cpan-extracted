use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_json($_[0], indent_char => ' ', indent_width => 2) }

# ── // comment stripped during reformat ──────────────────────────

{
    my $src = "// top-level comment\n{\"a\":1}";
    my $out = j($src);
    like($out, qr/^\{$/m,        '// comment: object opens at depth 0');
    like($out, qr/^\s+"a": 1$/m, '// comment: value correctly formatted');
}

# ── inline // comment after value ────────────────────────────────

{
    my $src = "{\"x\":1 // inline\n}";
    my $out = j($src);
    like($out, qr/^\s+"x": 1$/m, 'inline // comment does not corrupt value');
    like($out, qr/^\}$/m,        'object closes correctly after inline comment');
}

# ── block comment between keys ────────────────────────────────────

{
    my $src = '{"a":1,/* a comment */"b":2}';
    my $out = j($src);
    like($out, qr/^\s+"a": 1,?$/m, 'block comment: a still present');
    like($out, qr/^\s+"b": 2$/m,   'block comment: b still present');
}

# ── // comment inside array ───────────────────────────────────────

{
    my $src = "[1,// second\n2,3]";
    my $out = j($src);
    like($out, qr/^\s+1,?$/m, '// in array: first element');
    like($out, qr/^\s+2,?$/m, '// in array: second element');
    like($out, qr/^\s+3$/m,   '// in array: third element');
}

# ── // comment on own line: structure intact ─────────────────────

{
    my $src = "// header\n{\"k\":\"v\"}";
    my $out = j($src);
    like($out, qr/^\{$/m,          'object opens after leading comment');
    like($out, qr/^\s+"k": "v"$/m, 'key/value after leading comment formatted correctly');
}

# ── block comment on own line: structure intact ───────────────────

{
    my $src = "/* block */\n{\"k\":1}";
    my $out = j($src);
    like($out, qr/^\{$/m,         'object follows block comment');
    like($out, qr/^\s+"k": 1$/m,  'value after block comment formatted correctly');
}

# ── trailing comma (JSON5-style) tolerated ────────────────────────

{
    my $src = '{"a":1,}';
    my $out = j($src);
    like($out, qr/^\s+"a": 1,?$/m, 'trailing comma tolerated in object');
    like($out, qr/^\}$/m,          'object closes after trailing comma');
}

{
    my $src = '[1,2,]';
    my $out = j($src);
    like($out, qr/^\s+1,?$/m, 'trailing comma tolerated in array');
    like($out, qr/^\s+2,?$/m, 'second element before trailing comma');
}

# ── detect_lang .jsonc ────────────────────────────────────────────

is(Eshu->detect_lang('settings.jsonc'), 'json', 'detect_lang .jsonc → json');

done_testing;
