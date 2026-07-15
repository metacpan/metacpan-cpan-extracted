use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── do/end block ─────────────────────────────────────────────────

{
    my $src = <<'END';
[1, 2, 3].each do |x|
puts x
end
END
    my $out = r($src);
    like($out, qr/^\[1, 2, 3\]\.each do \|x\|$/m, 'do block opener at depth 0');
    like($out, qr/^  puts x$/m,                     'block body at depth 1');
    like($out, qr/^end$/m,                           'end at depth 0');
}

# ── brace block { } ──────────────────────────────────────────────

{
    my $src = <<'END';
[1, 2, 3].map { |x|
x * 2
}
END
    my $out = r($src);
    like($out, qr/^\[1, 2, 3\]\.map \{ \|x\|$/m, '{ block opener');
    like($out, qr/^  x \* 2$/m,                   'block body at depth 1');
    like($out, qr/^\}$/m,                          '} at depth 0');
}

# ── nested blocks ────────────────────────────────────────────────

{
    my $src = <<'END';
def process(arr)
arr.each do |x|
arr.each do |y|
puts "#{x},#{y}"
end
end
end
END
    my $out = r($src);
    like($out, qr/^def process\(arr\)$/m,  'def at depth 0');
    like($out, qr/^  arr\.each do \|x\|$/m,'outer do at depth 1');
    like($out, qr/^    arr\.each do \|y\|$/m,'inner do at depth 2');
    like($out, qr/^      puts/m,            'innermost body at depth 3');
    like($out, qr/^    end$/m,              'inner end at depth 2');
    like($out, qr/^  end$/m,               'outer end at depth 1');
    like($out, qr/^end$/m,                 'def end at depth 0');
}

# ── lambda ───────────────────────────────────────────────────────

{
    my $src = <<'END';
double = lambda { |x|
x * 2
}
END
    my $out = r($src);
    like($out, qr/^double = lambda \{ \|x\|$/m, 'lambda block');
    like($out, qr/^  x \* 2$/m,                 'lambda body at depth 1');
    like($out, qr/^\}$/m,                        'lambda close');
}

# ── while/until/for ──────────────────────────────────────────────

{
    my $src = <<'END';
while x > 0
x -= 1
end
until done
step
end
for i in 1..10
puts i
end
END
    my $out = r($src);
    like($out, qr/^while x > 0$/m,   'while at depth 0');
    like($out, qr/^  x -= 1$/m,      'while body at depth 1');
    like($out, qr/^until done$/m,    'until at depth 0');
    like($out, qr/^  step$/m,        'until body at depth 1');
    like($out, qr/^for i in 1\.\.10$/m, 'for at depth 0');
    like($out, qr/^  puts i$/m,         'for body at depth 1');
}

done_testing;
