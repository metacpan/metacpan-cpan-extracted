use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── DQ string with braces inside — no depth change ───────────────

{
    my $src = <<'END';
def foo
s = "not a {block}"
s
end
END
    my $out = r($src);
    like($out, qr/^def foo$/m,               'def at depth 0');
    like($out, qr/^  s = "not a \{block\}"$/m,'string with braces at depth 1');
    like($out, qr/^  s$/m,                   's at depth 1');
    like($out, qr/^end$/m,                   'end at depth 0');
}

# ── SQ string ────────────────────────────────────────────────────

{
    my $src = <<'END';
def bar
s = 'it\'s fine'
s
end
END
    my $out = r($src);
    like($out, qr/^  s = 'it\\\'s fine'$/m, 'escaped single quote in string at depth 1');
}

# ── heredoc ──────────────────────────────────────────────────────

{
    my $src = <<'END';
def msg
x = <<~HEREDOC
  Hello
  World
HEREDOC
x
end
END
    my $out = r($src);
    like($out, qr/^def msg$/m,           'def at depth 0');
    like($out, qr/^  x = <<~HEREDOC$/m, 'heredoc start at depth 1');
    like($out, qr/^  Hello$/m,           'heredoc body line 1 verbatim');
    like($out, qr/^  World$/m,           'heredoc body line 2 verbatim');
    like($out, qr/^HEREDOC$/m,           'heredoc end marker');
    like($out, qr/^  x$/m,              'code after heredoc at depth 1');
    like($out, qr/^end$/m,              'end at depth 0');
}

# ── %w word array — no depth change ──────────────────────────────

{
    my $src = <<'END';
def words
arr = %w[one two three]
arr
end
END
    my $out = r($src);
    like($out, qr/^  arr = %w\[one two three\]$/m, '%w at depth 1');
    like($out, qr/^  arr$/m,                        'code after %w at depth 1');
    like($out, qr/^end$/m,                           'end at depth 0');
}

# ── %Q interpolated string ────────────────────────────────────────

{
    my $src = <<'END';
def greet(name)
msg = %Q(Hello, #{name}!)
msg
end
END
    my $out = r($src);
    like($out, qr/^  msg = %Q\(Hello/m, '%Q at depth 1');
    like($out, qr/^end$/m,              'end at depth 0');
}

done_testing;
