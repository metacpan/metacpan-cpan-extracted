use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── backslash continuation: lines emitted verbatim ────────────────

{
    my $src = "x = 1 + \\\n    2 + \\\n    3\n";
    my $out = py($src);
    like($out, qr/^x = 1 \+ \\$/m,   'backslash continuation first line at depth 0');
    like($out, qr/^    2 \+ \\$/m,   'continuation line 2 preserved as-is');
    like($out, qr/^    3$/m,          'continuation final line preserved as-is');
}

# ── backslash continuation inside function ────────────────────────

{
    my $src = "def f():\n    x = a + \\\n        b\n    return x\n";
    my $out = py($src);
    like($out, qr/^    x = a \+ \\$/m,  'continuation opener at depth 1');
    like($out, qr/^        b$/m,         'continuation line preserved');
    like($out, qr/^    return x$/m,      'code after continuation at depth 1');
}

# ── open paren: continuation lines preserved ─────────────────────

{
    my $src = "x = (\n    1 +\n    2\n)\n";
    my $out = py($src);
    like($out, qr/^x = \($/m,  'open-paren continuation opener at depth 0');
    like($out, qr/^    1 \+$/m, 'continuation line inside parens preserved');
    like($out, qr/^    2$/m,    'continuation line preserved');
    like($out, qr/^\)$/m,       'closing paren at depth 0');
}

# ── open bracket: continuation lines preserved ───────────────────

{
    my $src = "items = [\n    1,\n    2,\n    3,\n]\n";
    my $out = py($src);
    like($out, qr/^items = \[$/m, 'list open at depth 0');
    like($out, qr/^    1,$/m,     'list item preserved');
    like($out, qr/^    3,$/m,     'list item preserved');
    like($out, qr/^\]$/m,         'closing bracket at depth 0');
}

# ── open brace: continuation lines preserved ─────────────────────

{
    my $src = "d = {\n    'a': 1,\n    'b': 2,\n}\n";
    my $out = py($src);
    like($out, qr/^d = \{$/m,     'dict open at depth 0');
    like($out, qr/^    'a': 1,$/m, 'dict entry preserved');
    like($out, qr/^\}$/m,          'closing brace at depth 0');
}

# ── multi-line function call ──────────────────────────────────────

{
    my $src = <<'SRC';
result = some_function(
    arg1,
    arg2,
    keyword=value,
)
SRC
    my $out = py($src);
    like($out, qr/^result = some_function\($/m, 'function call opener at depth 0');
    like($out, qr/^    arg1,$/m,                 'arg1 preserved');
    like($out, qr/^    keyword=value,$/m,         'keyword arg preserved');
    like($out, qr/^\)$/m,                         'closing paren at depth 0');
}

# ── continuation followed by normal code resumes depth ───────────

{
    my $src = <<'SRC';
def f():
    x = (
        1 + 2
    )
    return x
SRC
    my $out = py($src);
    like($out, qr/^    x = \($/m,    'x at depth 1');
    like($out, qr/^        1 \+ 2$/m, 'continuation line preserved');
    like($out, qr/^    \)$/m,         'closing paren preserved');
    like($out, qr/^    return x$/m,   'return resumes depth 1');
}

# ── nested parens ─────────────────────────────────────────────────

{
    my $src = "x = func(\n    inner(\n        1\n    )\n)\n";
    my $out = py($src);
    like($out, qr/^x = func\($/m, 'outer call at depth 0');
    like($out, qr/^\)$/m,          'outer closing paren');
    ok(defined $out, 'nested parens do not crash');
}

done_testing;
