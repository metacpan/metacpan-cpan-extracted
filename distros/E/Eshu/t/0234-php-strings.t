use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── double-quoted string with braces inside doesn't affect depth ──

{
    my $src = <<'END';
function foo() {
$s = "not a {block}";
return $s;
}
END
    my $out = p($src);
    like($out, qr/^function foo\(\) \{$/m,     'function at depth 0');
    like($out, qr/^    \$s = "not a \{block\}";$/m, 'string with braces at depth 1');
    like($out, qr/^    return \$s;$/m,          'return at depth 1');
    like($out, qr/^\}$/m,                       'closing brace at depth 0');
}

# ── single-quoted string ─────────────────────────────────────────

{
    my $src = <<'END';
if ($x) {
$msg = 'it\'s fine';
echo $msg;
}
END
    my $out = p($src);
    like($out, qr/^if \(\$x\) \{$/m,              'if at depth 0');
    like($out, qr/^    \$msg = 'it\\\'s fine';$/m, 'escaped single quote in string at depth 1');
    like($out, qr/^    echo \$msg;$/m,             'echo at depth 1');
}

# ── string with apparent keywords inside ─────────────────────────

{
    my $src = <<'END';
$s = "if (true) { return false; }";
echo $s;
END
    my $out = p($src);
    like($out, qr/^\$s = "if \(true\)/m,  'string content not parsed as code');
    like($out, qr/^echo \$s;$/m,           'next statement at depth 0');
}

# ── concatenation operators don't affect depth ───────────────────

{
    my $src = <<'END';
function build() {
$r = 'a' . 'b'
. 'c';
return $r;
}
END
    my $out = p($src);
    like($out, qr/^    \$r = 'a' \. 'b'$/m,   'concat start at depth 1');
    like($out, qr/^    \. 'c';$/m,             'continuation at depth 1');
    like($out, qr/^    return \$r;$/m,          'return at depth 1');
}

done_testing;
