use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── single-line list comprehension ───────────────────────────────

{
    my $src = "squares = [x**2 for x in range(10)]\n";
    is(py($src), $src, 'single-line list comprehension unchanged');
}

# ── single-line dict comprehension ───────────────────────────────

{
    my $src = "d = {k: v for k, v in items}\n";
    is(py($src), $src, 'single-line dict comprehension unchanged');
}

# ── single-line set comprehension ────────────────────────────────

{
    my $src = "s = {x for x in lst if x > 0}\n";
    is(py($src), $src, 'single-line set comprehension unchanged');
}

# ── single-line generator expression ─────────────────────────────

{
    my $src = "total = sum(x**2 for x in range(10))\n";
    is(py($src), $src, 'single-line generator expression unchanged');
}

# ── multi-line list comprehension ────────────────────────────────

{
    my $src = <<'SRC';
squares = [
    x**2
    for x in range(10)
    if x % 2 == 0
]
SRC
    my $out = py($src);
    like($out, qr/^squares = \[$/m,       'list comp opener at depth 0');
    like($out, qr/^    x\*\*2$/m,         'expression line preserved in bracket');
    like($out, qr/^    for x in range/m,  'for clause preserved');
    like($out, qr/^    if x % 2 == 0$/m,  'if clause preserved');
    like($out, qr/^\]$/m,                 'closing bracket at depth 0');
}

# ── multi-line dict comprehension ────────────────────────────────

{
    my $src = <<'SRC';
d = {
    k: v
    for k, v in items.items()
    if v is not None
}
SRC
    my $out = py($src);
    like($out, qr/^d = \{$/m,            'dict comp opener at depth 0');
    like($out, qr/^    k: v$/m,          'k: v preserved');
    like($out, qr/^    for k, v in/m,    'for clause preserved');
    like($out, qr/^\}$/m,                'closing brace at depth 0');
}

# ── comprehension inside function ────────────────────────────────

{
    my $src = <<'SRC';
def get_evens(n):
    return [
        x
        for x in range(n)
        if x % 2 == 0
    ]
SRC
    my $out = py($src);
    like($out, qr/^    return \[$/m,         'return [ at depth 1');
    like($out, qr/^        x$/m,             'x at continuation depth');
    like($out, qr/^        for x in range/m, 'for clause preserved');
    like($out, qr/^    \]$/m,                'closing ] at depth 1');
}

# ── nested comprehension ─────────────────────────────────────────

{
    my $src = "matrix = [[row[i] for row in matrix] for i in range(4)]\n";
    is(py($src), $src, 'nested single-line comprehension unchanged');
}

# ── comprehension does not affect subsequent line depth ───────────

{
    my $src = <<'SRC';
def f():
    result = [x for x in items]
    return result
SRC
    my $out = py($src);
    like($out, qr/^    result = /m,    'result at depth 1');
    like($out, qr/^    return result$/m, 'return at depth 1 (not confused by [])');
}

done_testing;
