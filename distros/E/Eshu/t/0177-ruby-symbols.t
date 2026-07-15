use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── symbols don't affect depth ───────────────────────────────────

{
    my $src = <<'END';
def foo
x = :hello
y = :"quoted symbol"
[x, y]
end
END
    my $out = r($src);
    like($out, qr/^def foo$/m,                  'def at depth 0');
    like($out, qr/^  x = :hello$/m,             ':symbol at depth 1');
    like($out, qr/^  y = :"quoted symbol"$/m,   ':"quoted" at depth 1');
    like($out, qr/^  \[x, y\]$/m,               'array at depth 1');
    like($out, qr/^end$/m,                       'end at depth 0');
}

# ── symbol with braces inside string ─────────────────────────────

{
    my $src = <<'END';
def bar
h = {key: "value"}
h
end
END
    my $out = r($src);
    like($out, qr/^  h = \{key: "value"\}$/m, 'hash with symbol key at depth 1');
    like($out, qr/^  h$/m,                     'code after hash at depth 1');
    like($out, qr/^end$/m,                     'end at depth 0');
}

# ── %i symbol array ───────────────────────────────────────────────

{
    my $src = <<'END';
def syms
arr = %i[one two three]
arr
end
END
    my $out = r($src);
    like($out, qr/^  arr = %i\[one two three\]$/m, '%i at depth 1');
    like($out, qr/^  arr$/m,                         'code after %i at depth 1');
    like($out, qr/^end$/m,                            'end at depth 0');
}

done_testing;
