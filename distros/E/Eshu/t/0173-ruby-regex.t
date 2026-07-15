use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── regex with braces doesn't affect depth ───────────────────────

{
    my $src = <<'END';
def check(s)
if s =~ /\{.*\}/
puts "has braces"
end
end
END
    my $out = r($src);
    like($out, qr/^def check\(s\)$/m,    'def at depth 0');
    like($out, qr/^  if s =~ \//m,       'if with regex at depth 1');
    like($out, qr/^    puts "has braces"$/m, 'if body at depth 2');
    like($out, qr/^  end$/m,             'inner end at depth 1');
    like($out, qr/^end$/m,               'outer end at depth 0');
}

# ── division operator not mistaken for regex ──────────────────────

{
    my $src = <<'END';
def calc(x, y)
result = x / y
result
end
END
    my $out = r($src);
    like($out, qr/^  result = x \/ y$/m,  'division at depth 1');
    like($out, qr/^  result$/m,            'code after division at depth 1');
    like($out, qr/^end$/m,                 'end at depth 0');
}

# ── %r regex literal ─────────────────────────────────────────────

{
    my $src = <<'END';
def match(s)
if s =~ %r{foo\{bar\}}
puts "yes"
end
end
END
    my $out = r($src);
    like($out, qr/^  if s =~ %r\{/m,  '%r regex at depth 1 (no depth change)');
    like($out, qr/^    puts "yes"$/m,  'body at depth 2');
    like($out, qr/^  end$/m,           'inner end at depth 1');
    like($out, qr/^end$/m,             'outer end at depth 0');
}

done_testing;
