use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── classic switch/case ──────────────────────────────────────────

{
    my $src = <<'END';
switch ($x) {
case 1:
echo "one";
break;
case 2:
echo "two";
break;
default:
echo "other";
}
END
    my $out = p($src);
    like($out, qr/^switch \(\$x\) \{$/m,    'switch at depth 0');
    like($out, qr/^    case 1:$/m,           'case label at depth 1');
    like($out, qr/^        echo "one";$/m,   'case body at depth 2');
    like($out, qr/^        break;$/m,        'break at depth 2');
    like($out, qr/^    case 2:$/m,           'second case label');
    like($out, qr/^    default:$/m,          'default label at depth 1');
    like($out, qr/^        echo "other";$/m, 'default body at depth 2');
    like($out, qr/^\}$/m,                   'switch closing brace at depth 0');
}

# ── switch inside function ────────────────────────────────────────

{
    my $src = <<'END';
function go($x) {
switch ($x) {
case 'a':
return 1;
case 'b':
return 2;
default:
return 0;
}
}
END
    my $out = p($src);
    like($out, qr/^function go\(\$x\) \{$/m,  'function at depth 0');
    like($out, qr/^    switch \(\$x\) \{$/m,  'switch at depth 1');
    like($out, qr/^        case 'a':$/m,       'case at depth 2');
    like($out, qr/^            return 1;$/m,   'case body at depth 3');
    like($out, qr/^        default:$/m,        'default at depth 2');
    like($out, qr/^    \}$/m,                  'switch closing brace at depth 1');
    like($out, qr/^\}$/m,                      'function closing brace at depth 0');
}

# ── match expression (PHP 8) ─────────────────────────────────────

{
    my $src = <<'END';
$result = match($x) {
1 => 'one',
2 => 'two',
default => 'other',
};
END
    my $out = p($src);
    like($out, qr/^\$result = match\(\$x\) \{$/m, 'match at depth 0');
    like($out, qr/^    1 => 'one',$/m,              'match arm at depth 1');
    like($out, qr/^    default => 'other',$/m,      'default arm at depth 1');
    like($out, qr/^\};$/m,                          'match closing at depth 0');
}

done_testing;
