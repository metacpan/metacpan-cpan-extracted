use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── simple class ─────────────────────────────────────────────────

{
    my $src = "class Foo:\n    pass\n";
    my $out = py($src);
    like($out, qr/^class Foo:$/m, 'class at depth 0');
    like($out, qr/^    pass$/m,   'class body at depth 1');
}

# ── class with base class ────────────────────────────────────────

{
    my $src = "class Bar(Foo):\n    pass\n";
    my $out = py($src);
    like($out, qr/^class Bar\(Foo\):$/m, 'class with base at depth 0');
}

# ── class with __init__ ──────────────────────────────────────────

{
    my $src = <<'SRC';
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y
SRC
    my $out = py($src);
    like($out, qr/^class Point:$/m,             'class at depth 0');
    like($out, qr/^    def __init__/m,           '__init__ at depth 1');
    like($out, qr/^        self\.x = x$/m,       'self.x at depth 2');
    like($out, qr/^        self\.y = y$/m,       'self.y at depth 2');
}

# ── class with multiple methods ───────────────────────────────────

{
    my $src = <<'SRC';
class Animal:
    def __init__(self, name):
        self.name = name
    def speak(self):
        pass
    def move(self):
        pass
SRC
    my $out = py($src);
    like($out, qr/^    def __init__/m,   '__init__ at depth 1');
    like($out, qr/^        self\.name/m, 'self.name at depth 2');
    like($out, qr/^    def speak/m,      'speak at depth 1 (dedented from depth 2)');
    like($out, qr/^    def move/m,       'move at depth 1');
}

# ── class method body ────────────────────────────────────────────

{
    my $src = <<'SRC';
class Calc:
    def add(self, a, b):
        return a + b
    def sub(self, a, b):
        return a - b
SRC
    my $out = py($src);
    like($out, qr/^        return a \+ b$/m, 'add body at depth 2');
    like($out, qr/^        return a - b$/m,  'sub body at depth 2');
}

# ── nested class ─────────────────────────────────────────────────

{
    my $src = <<'SRC';
class Outer:
    class Inner:
        def method(self):
            return 42
    def outer_method(self):
        pass
SRC
    my $out = py($src);
    like($out, qr/^class Outer:$/m,          'Outer at depth 0');
    like($out, qr/^    class Inner:$/m,      'Inner at depth 1');
    like($out, qr/^        def method/m,     'Inner.method at depth 2');
    like($out, qr/^            return 42$/m, 'Inner.method body at depth 3');
    like($out, qr/^    def outer_method/m,   'outer_method at depth 1 (dedented)');
}

# ── class with class variables ───────────────────────────────────

{
    my $src = <<'SRC';
class Config:
    DEBUG = False
    VERSION = '1.0'
    def __init__(self):
        pass
SRC
    my $out = py($src);
    like($out, qr/^    DEBUG = False$/m,     'class variable at depth 1');
    like($out, qr/^    VERSION = '1\.0'$/m,  'class variable at depth 1');
    like($out, qr/^    def __init__/m,       '__init__ at depth 1');
}

# ── re-indent class from wrong indentation ───────────────────────

{
    my $src = "class X:\n  def f(self):\n    return 1\n";
    my $out = py($src);
    like($out, qr/^    def f\(self\):$/m, 'method re-indented to 4 spaces');
    like($out, qr/^        return 1$/m,   'body re-indented to 8 spaces');
}

done_testing;
