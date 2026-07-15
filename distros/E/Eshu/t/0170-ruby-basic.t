use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── def/end ──────────────────────────────────────────────────────

{
    my $src = <<'END';
def greet(name)
puts "Hello, #{name}"
end
END
    my $out = r($src);
    like($out, qr/^def greet\(name\)$/m,        'def at depth 0');
    like($out, qr/^  puts "Hello/m,              'body at depth 1');
    like($out, qr/^end$/m,                        'end at depth 0');
}

# ── class/end ────────────────────────────────────────────────────

{
    my $src = <<'END';
class Dog
def bark
puts "Woof!"
end
end
END
    my $out = r($src);
    like($out, qr/^class Dog$/m,       'class at depth 0');
    like($out, qr/^  def bark$/m,      'def at depth 1');
    like($out, qr/^    puts "Woof!"/m, 'puts at depth 2');
    like($out, qr/^  end$/m,           'inner end at depth 1');
    like($out, qr/^end$/m,             'outer end at depth 0');
}

# ── if/elsif/else/end ────────────────────────────────────────────

{
    my $src = <<'END';
if x > 0
puts "positive"
elsif x < 0
puts "negative"
else
puts "zero"
end
END
    my $out = r($src);
    like($out, qr/^if x > 0$/m,          'if at depth 0');
    like($out, qr/^  puts "positive"$/m,  'if body at depth 1');
    like($out, qr/^elsif x < 0$/m,        'elsif at depth 0');
    like($out, qr/^  puts "negative"$/m,  'elsif body at depth 1');
    like($out, qr/^else$/m,               'else at depth 0');
    like($out, qr/^  puts "zero"$/m,      'else body at depth 1');
    like($out, qr/^end$/m,                'end at depth 0');
}

# ── unless/end ───────────────────────────────────────────────────

{
    my $src = <<'END';
unless done
work
end
END
    my $out = r($src);
    like($out, qr/^unless done$/m, 'unless at depth 0');
    like($out, qr/^  work$/m,      'body at depth 1');
    like($out, qr/^end$/m,         'end at depth 0');
}

# ── modifier if — no depth change ────────────────────────────────

{
    my $src = <<'END';
def check
x = 1
return false if x > 10
x
end
END
    my $out = r($src);
    like($out, qr/^def check$/m,                   'def at depth 0');
    like($out, qr/^  x = 1$/m,                     'x at depth 1');
    like($out, qr/^  return false if x > 10$/m,    'modifier if at depth 1');
    like($out, qr/^  x$/m,                          'x after modifier if at depth 1');
    like($out, qr/^end$/m,                          'end at depth 0');
}

# ── detect_lang ──────────────────────────────────────────────────

{
    is(Eshu->detect_lang('foo.rb'),    'ruby', '.rb detected');
    is(Eshu->detect_lang('foo.RB'),    'ruby', '.RB detected');
    is(Eshu->detect_lang('foo.rake'),  'ruby', '.rake detected');
    is(Eshu->detect_lang('Gemfile'),   'ruby', 'Gemfile detected');
    is(Eshu->detect_lang('Rakefile'),  'ruby', 'Rakefile detected');
}

done_testing;
