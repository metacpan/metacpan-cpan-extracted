use strict;
use warnings;
use Test::More;
use Eshu;

sub py  { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }
sub pyt { Eshu->indent_python($_[0], indent_char => "\t", indent_width => 1) }

# ── detect_lang ───────────────────────────────────────────────────

is(Eshu->detect_lang('foo.py'),  'python', 'detect_lang .py');
is(Eshu->detect_lang('foo.pyw'), 'python', 'detect_lang .pyw');

# ── indent_string dispatch ────────────────────────────────────────

{
    my $src = "def f():\n    pass\n";
    my $out = Eshu->indent_string($src, lang => 'python',
                                  indent_char => ' ', indent_width => 4);
    like($out, qr/^def f\(\):$/m, 'indent_string python: top-level def preserved');
}

{
    my $out = Eshu->indent_string("def f():\n    pass\n",
                                  lang => 'py',
                                  indent_char => ' ', indent_width => 4);
    like($out, qr/^def f\(\):$/m, 'indent_string py alias works');
}

# ── empty / blank lines ───────────────────────────────────────────

is(py(''), '', 'empty string');
is(py("\n"), "\n", 'single blank line');
is(py("\n\n"), "\n\n", 'two blank lines');

# ── top-level code (depth 0) ──────────────────────────────────────

{
    my $src = "x = 1\ny = 2\n";
    is(py($src), $src, 'top-level assignments unchanged');
}

# ── simple def block ─────────────────────────────────────────────

{
    my $src = "def hello():\n    print('hi')\n";
    my $out = py($src);
    like($out, qr/^def hello\(\):$/m,   'def line at depth 0');
    like($out, qr/^    print\('hi'\)$/m, 'body at depth 1 (4 spaces)');
}

# ── re-indent from 2-space source to 4-space output ───────────────

{
    my $src = "def f():\n  x = 1\n  y = 2\n";
    my $out = py($src);
    like($out, qr/^    x = 1$/m, 're-indent 2→4: body line 1');
    like($out, qr/^    y = 2$/m, 're-indent 2→4: body line 2');
}

# ── re-indent from 8-space source to 4-space output ───────────────

{
    my $src = "def f():\n        x = 1\n";
    my $out = py($src);
    like($out, qr/^    x = 1$/m, 're-indent 8→4: body at depth 1');
}

# ── if / elif / else ─────────────────────────────────────────────

{
    my $src = <<'SRC';
if x > 0:
    print('pos')
elif x < 0:
    print('neg')
else:
    print('zero')
SRC
    my $out = py($src);
    like($out, qr/^if x > 0:$/m,         'if at depth 0');
    like($out, qr/^    print\('pos'\)$/m, 'if body at depth 1');
    like($out, qr/^elif x < 0:$/m,       'elif at depth 0');
    like($out, qr/^    print\('neg'\)$/m, 'elif body at depth 1');
    like($out, qr/^else:$/m,             'else at depth 0');
    like($out, qr/^    print\('zero'\)$/m,'else body at depth 1');
}

# ── for loop ─────────────────────────────────────────────────────

{
    my $src = "for i in range(10):\n    print(i)\n";
    my $out = py($src);
    like($out, qr/^for i in range\(10\):$/m, 'for at depth 0');
    like($out, qr/^    print\(i\)$/m,         'for body at depth 1');
}

# ── while loop ───────────────────────────────────────────────────

{
    my $src = "while True:\n    break\n";
    my $out = py($src);
    like($out, qr/^while True:$/m, 'while at depth 0');
    like($out, qr/^    break$/m,   'while body at depth 1');
}

# ── nested blocks ────────────────────────────────────────────────

{
    my $src = <<'SRC';
def outer():
    if True:
        x = 1
    return x
SRC
    my $out = py($src);
    like($out, qr/^def outer\(\):$/m, 'outer def at depth 0');
    like($out, qr/^    if True:$/m,   'if at depth 1');
    like($out, qr/^        x = 1$/m,  'x at depth 2');
    like($out, qr/^    return x$/m,   'return at depth 1 (dedented)');
}

# ── pass as sole body ─────────────────────────────────────────────

{
    my $src = "def noop():\n    pass\n";
    my $out = py($src);
    like($out, qr/^    pass$/m, 'pass body at depth 1');
}

# ── tab output ───────────────────────────────────────────────────

{
    my $src = "def f():\n    x = 1\n";
    my $out = pyt($src);
    like($out, qr/^\tx = 1$/m, 'tab-indented body line');
}

# ── blank lines inside a function ────────────────────────────────

{
    my $src = "def f():\n    x = 1\n\n    y = 2\n";
    my $out = py($src);
    like($out, qr/^    x = 1$/m, 'line before blank preserved');
    like($out, qr/^\n/m,         'blank line preserved');
    like($out, qr/^    y = 2$/m, 'line after blank preserved');
}

done_testing;
