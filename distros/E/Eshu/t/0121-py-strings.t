use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── single-line double-quoted string: content unchanged ──────────

{
    my $src = "x = \"hello world\"\n";
    is(py($src), $src, 'double-quoted string unchanged');
}

# ── single-line single-quoted string ─────────────────────────────

{
    my $src = "x = 'hello world'\n";
    is(py($src), $src, 'single-quoted string unchanged');
}

# ── string with colon: not treated as block opener ────────────────

{
    my $src = "x = 'a: b'\n";
    is(py($src), $src, 'colon inside string not treated as block opener');
}

# ── string with hash: not treated as comment ──────────────────────

{
    my $src = "x = 'not # a comment'\n";
    is(py($src), $src, 'hash inside string not treated as comment');
}

# ── escaped quote inside string ───────────────────────────────────

{
    my $src = "x = \"say \\\"hi\\\"\"\n";
    is(py($src), $src, 'escaped double quote inside string');
}

# ── triple double-quoted string, single line ──────────────────────

{
    my $src = "x = \"\"\"triple\"\"\"\n";
    is(py($src), $src, 'triple double-quoted string (single line)');
}

# ── triple single-quoted string, single line ──────────────────────

{
    my $src = "x = '''triple'''\n";
    is(py($src), $src, 'triple single-quoted string (single line)');
}

# ── multi-line triple double-quoted: body lines NOT re-indented ───

{
    my $src = "x = \"\"\"\n  line one\n  line two\n\"\"\"\n";
    is(py($src), $src, 'triple-dq multi-line body preserved verbatim');
}

# ── multi-line triple single-quoted: body lines NOT re-indented ───

{
    my $src = "x = '''\n  line one\n  line two\n'''\n";
    is(py($src), $src, 'triple-sq multi-line body preserved verbatim');
}

# ── docstring inside function: body not re-indented ───────────────

{
    my $src = "def f():\n    \"\"\"\n    This is a docstring.\n    \"\"\"\n    pass\n";
    my $out = py($src);
    like($out, qr/^    """$/m,                    'docstring open at depth 1');
    like($out, qr/^    This is a docstring\.$/m, 'docstring body preserved');
    like($out, qr/^    """$/m,                    'docstring close preserved');
    like($out, qr/^    pass$/m,                   'code after docstring at depth 1');
}

# ── code after triple-quoted string resumes normal depth ──────────

{
    my $src = <<'SRC';
def f():
    x = """
    multi
    line
    """
    return x
SRC
    my $out = py($src);
    like($out, qr/^    return x$/m, 'code after triple-string at correct depth');
}

# ── f-string ─────────────────────────────────────────────────────

{
    my $src = "msg = f\"hello {name}\"\n";
    is(py($src), $src, 'f-string unchanged');
}

# ── b-string (bytes) ─────────────────────────────────────────────

{
    my $src = "data = b'\\x00\\x01'\n";
    is(py($src), $src, 'byte string unchanged');
}

# ── r-string (raw) ───────────────────────────────────────────────

{
    my $src = "pat = r'\\d+\\.\\d+'\n";
    is(py($src), $src, 'raw string unchanged');
}

# ── string with indentation-like content doesn't affect depth ─────

{
    my $src = "def f():\n    x = '    indented content'\n    return x\n";
    my $out = py($src);
    like($out, qr/^    x = '    indented content'$/m,
         'string with leading spaces not mistaken for new indent level');
    like($out, qr/^    return x$/m, 'return still at depth 1');
}

done_testing;
