use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── case/when/else/end ───────────────────────────────────────────

{
    my $src = <<'END';
case x
when 1
puts "one"
when 2
puts "two"
else
puts "other"
end
END
    my $out = r($src);
    like($out, qr/^case x$/m,        'case at depth 0');
    like($out, qr/^when 1$/m,        'when at depth 0');
    like($out, qr/^  puts "one"$/m,  'when body at depth 1');
    like($out, qr/^when 2$/m,        'second when at depth 0');
    like($out, qr/^  puts "two"$/m,  'second when body at depth 1');
    like($out, qr/^else$/m,          'else at depth 0');
    like($out, qr/^  puts "other"$/m,'else body at depth 1');
    like($out, qr/^end$/m,           'end at depth 0');
}

# ── case inside method ────────────────────────────────────────────

{
    my $src = <<'END';
def classify(x)
case x
when 1..5
"small"
when 6..10
"medium"
else
"large"
end
end
END
    my $out = r($src);
    like($out, qr/^def classify\(x\)$/m,  'def at depth 0');
    like($out, qr/^  case x$/m,            'case at depth 1');
    like($out, qr/^  when 1\.\.5$/m,       'when at depth 1');
    like($out, qr/^    "small"$/m,          'when body at depth 2');
    like($out, qr/^  else$/m,              'else at depth 1');
    like($out, qr/^    "large"$/m,          'else body at depth 2');
    like($out, qr/^  end$/m,              'inner end at depth 1');
    like($out, qr/^end$/m,               'outer end at depth 0');
}

# ── case with string matching ────────────────────────────────────

{
    my $src = <<'END';
case name
when "Alice", "Bob"
puts "friend"
when /^admin/
puts "admin"
end
END
    my $out = r($src);
    like($out, qr/^case name$/m,           'case at depth 0');
    like($out, qr/^when "Alice", "Bob"$/m, 'when with multiple values');
    like($out, qr/^  puts "friend"$/m,     'body at depth 1');
    like($out, qr/^when \/\^admin\//m,     'when with regex');
    like($out, qr/^  puts "admin"$/m,      'regex when body at depth 1');
}

done_testing;
