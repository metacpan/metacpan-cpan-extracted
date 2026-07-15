use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── classic switch: case X: ───────────────────────────────────────
# switch { opens depth: method at d0→d1, switch at d1→d2.
# case labels stay at brace depth (8sp=d2); body at d3 (12sp).

{
    my $src = <<'END';
void go(int x) {
switch (x) {
case 1:
doOne();
break;
case 2:
doTwo();
break;
default:
doDefault();
}
}
END
    my $out = j($src);
    like($out, qr/^    switch \(x\) \{$/m,        'switch header at depth 1');
    like($out, qr/^        case 1:$/m,             'case label at brace depth (d2)');
    like($out, qr/^            doOne\(\);$/m,      'case body at d3');
    like($out, qr/^            break;$/m,          'break at d3');
    like($out, qr/^        case 2:$/m,             'second case at brace depth');
    like($out, qr/^        default:$/m,            'default at brace depth');
    like($out, qr/^            doDefault\(\);$/m,  'default body at d3');
    like($out, qr/^    \}$/m,                      'switch close at d1');
}

# ── arrow switch: case X -> body-on-next-line ─────────────────────

{
    my $src = <<'END';
void go(int x) {
switch (x) {
case 1 ->
doOne();
case 2 ->
doTwo();
default ->
doDefault();
}
}
END
    my $out = j($src);
    like($out, qr/^        case 1 ->$/m,          'arrow case label at brace depth');
    like($out, qr/^            doOne\(\);$/m,     'arrow case body at d3');
    like($out, qr/^        case 2 ->$/m,          'second arrow case');
    like($out, qr/^        default ->$/m,         'arrow default');
    like($out, qr/^            doDefault\(\);$/m, 'arrow default body at d3');
}

# ── arrow switch with braces ──────────────────────────────────────

{
    my $src = <<'END';
void go(String s) {
switch (s) {
case "hello" -> {
greet();
wave();
}
default -> {
ignore();
}
}
}
END
    my $out = j($src);
    like($out, qr/^        case "hello" -> \{$/m, 'arrow case with brace at d2');
    like($out, qr/greet\(\)/,                     'arrow brace body present');
    like($out, qr/wave\(\)/,                      'arrow brace body line 2 present');
    like($out, qr/^        default -> \{$/m,      'arrow default with brace at d2');
    like($out, qr/ignore\(\)/,                    'arrow default body present');
}

# ── fall-through ──────────────────────────────────────────────────

{
    my $src = <<'END';
void go(int x) {
switch (x) {
case 1:
case 2:
handleBoth();
break;
default:
handleDefault();
}
}
END
    my $out = j($src);
    like($out, qr/^        case 1:$/m,           'fall-through first case at d2');
    like($out, qr/^        case 2:$/m,           'fall-through second case at d2');
    like($out, qr/^            handleBoth/m,     'fall-through body at d3');
}

# ── standalone switch (no enclosing method) ───────────────────────

{
    my $src = <<'END';
switch (x) {
case 1:
doOne();
break;
default:
doDefault();
}
END
    my $out = j($src);
    like($out, qr/^    case 1:$/m,       'case at brace depth (d1) when switch is d0');
    like($out, qr/^        doOne/m,      'body at d2');
    like($out, qr/^    default:$/m,      'default at brace depth');
    like($out, qr/^        doDefault/m,  'default body at d2');
    like($out, qr/^\}$/m,            'switch close at d0');
}

done_testing;
