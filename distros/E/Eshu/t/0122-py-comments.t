use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── top-level comment ────────────────────────────────────────────

{
    my $src = "# this is a comment\n";
    is(py($src), $src, 'top-level comment unchanged');
}

# ── comment with no space after hash ─────────────────────────────

{
    my $src = "#comment no space\n";
    is(py($src), $src, 'comment without space unchanged');
}

# ── shebang line ─────────────────────────────────────────────────

{
    my $src = "#!/usr/bin/env python3\n";
    is(py($src), $src, 'shebang line unchanged');
}

# ── inline comment does not affect depth ─────────────────────────

{
    my $src = "def f():  # a function\n    pass\n";
    my $out = py($src);
    like($out, qr/^def f\(\):  # a function$/m, 'inline comment on def preserved');
    like($out, qr/^    pass$/m, 'body after inline comment at depth 1');
}

# ── indented comment stays at its level ──────────────────────────

{
    my $src = "def f():\n    # inner comment\n    pass\n";
    my $out = py($src);
    like($out, qr/^    # inner comment$/m, 'indented comment at depth 1');
    like($out, qr/^    pass$/m,            'pass still at depth 1');
}

# ── comment between blocks doesn't reset depth ───────────────────

{
    my $src = <<'SRC';
def f():
    x = 1
    # comment between statements
    y = 2
SRC
    my $out = py($src);
    like($out, qr/^    x = 1$/m,                  'x at depth 1');
    like($out, qr/^    # comment between/m,        'comment stays at depth 1');
    like($out, qr/^    y = 2$/m,                   'y at depth 1');
}

# ── comment after dedent ──────────────────────────────────────────

{
    my $src = <<'SRC';
def f():
    pass
# module-level comment
x = 1
SRC
    my $out = py($src);
    like($out, qr/^# module-level comment$/m, 'comment after dedent at depth 0');
    like($out, qr/^x = 1$/m,                 'code after comment at depth 0');
}

# ── comment with hash in string on same line ──────────────────────

{
    my $src = "x = '#not a comment'  # real comment\n";
    is(py($src), $src, 'hash in string followed by real inline comment');
}

# ── multi-line block: comment between them preserved ─────────────

{
    my $src = <<'SRC';
for i in range(3):
    # comment inside loop
    print(i)
SRC
    my $out = py($src);
    like($out, qr/^    # comment inside loop$/m, 'comment inside for at depth 1');
    like($out, qr/^    print\(i\)$/m,            'print inside for at depth 1');
}

done_testing;
