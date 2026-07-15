use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── module/class nesting ─────────────────────────────────────────

{
    my $src = <<'END';
module Animals
class Dog
def bark
puts "Woof!"
end
end
end
END
    my $out = r($src);
    like($out, qr/^module Animals$/m,  'module at depth 0');
    like($out, qr/^  class Dog$/m,     'class at depth 1');
    like($out, qr/^    def bark$/m,    'def at depth 2');
    like($out, qr/^      puts "Woof!"/m,'body at depth 3');
    like($out, qr/^    end$/m,         'def end at depth 2');
    like($out, qr/^  end$/m,           'class end at depth 1');
    like($out, qr/^end$/m,             'module end at depth 0');
}

# ── include/extend don't affect depth ────────────────────────────

{
    my $src = <<'END';
class Foo
include Comparable
extend ClassMethods
def bar
1
end
end
END
    my $out = r($src);
    like($out, qr/^  include Comparable$/m,    'include at depth 1');
    like($out, qr/^  extend ClassMethods$/m,   'extend at depth 1');
    like($out, qr/^  def bar$/m,               'def after include at depth 1');
    like($out, qr/^    1$/m,                   'def body at depth 2');
}

# ── class with inheritance ────────────────────────────────────────

{
    my $src = <<'END';
class Cat < Animal
def speak
"Meow"
end
end
END
    my $out = r($src);
    like($out, qr/^class Cat < Animal$/m, 'class with inheritance at depth 0');
    like($out, qr/^  def speak$/m,         'def at depth 1');
    like($out, qr/^    "Meow"$/m,          'body at depth 2');
}

# ── attr_accessor (single-line, no depth) ───────────────────────

{
    my $src = <<'END';
class Person
attr_accessor :name, :age
def initialize(name, age)
@name = name
@age = age
end
end
END
    my $out = r($src);
    like($out, qr/^  attr_accessor :name, :age$/m, 'attr_accessor at depth 1');
    like($out, qr/^  def initialize/m,              'def at depth 1');
    like($out, qr/^    \@name = name$/m,             'ivar assignment at depth 2');
}

done_testing;
