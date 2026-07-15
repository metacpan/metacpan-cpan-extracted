use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── simple decorator ─────────────────────────────────────────────

{
    my $src = "\@staticmethod\ndef f():\n    pass\n";
    my $out = py($src);
    like($out, qr/^\@staticmethod$/m, 'simple decorator at depth 0');
    like($out, qr/^def f\(\):$/m,     'def after decorator at depth 0');
    like($out, qr/^    pass$/m,       'body at depth 1');
}

# ── decorator with argument ───────────────────────────────────────

{
    my $src = "\@app.route('/home')\ndef index():\n    pass\n";
    my $out = py($src);
    like($out, qr/^\@app\.route/m,   'decorator with argument at depth 0');
    like($out, qr/^def index\(\):$/m, 'def after decorator at depth 0');
}

# ── decorator inside class ────────────────────────────────────────

{
    my $src = <<'SRC';
class MyClass:
    @staticmethod
    def helper():
        return 1
    @classmethod
    def create(cls):
        return cls()
SRC
    my $out = py($src);
    like($out, qr/^    \@staticmethod$/m,  'staticmethod decorator at depth 1');
    like($out, qr/^    def helper\(\):$/m, 'helper at depth 1');
    like($out, qr/^        return 1$/m,    'helper body at depth 2');
    like($out, qr/^    \@classmethod$/m,   'classmethod decorator at depth 1');
    like($out, qr/^    def create/m,       'create at depth 1');
}

# ── multiple decorators stacked ───────────────────────────────────

{
    my $src = <<'SRC';
@login_required
@cache(60)
def dashboard():
    pass
SRC
    my $out = py($src);
    like($out, qr/^\@login_required$/m, 'first decorator at depth 0');
    like($out, qr/^\@cache\(60\)$/m,    'second decorator at depth 0');
    like($out, qr/^def dashboard\(\):$/m, 'def at depth 0');
}

# ── decorator does not shift body indent ─────────────────────────

{
    my $src = <<'SRC';
@decorator
def f():
    x = 1
    return x
SRC
    my $out = py($src);
    like($out, qr/^    x = 1$/m,    'body line 1 at depth 1');
    like($out, qr/^    return x$/m, 'body line 2 at depth 1');
}

# ── property decorator ────────────────────────────────────────────

{
    my $src = <<'SRC';
class Temp:
    @property
    def value(self):
        return self._value
    @value.setter
    def value(self, v):
        self._value = v
SRC
    my $out = py($src);
    like($out, qr/^    \@property$/m,       '@property at depth 1');
    like($out, qr/^    \@value\.setter$/m,  '@value.setter at depth 1');
    like($out, qr/^        return self\._value$/m, 'getter body at depth 2');
    like($out, qr/^        self\._value = v$/m,    'setter body at depth 2');
}

# ── re-indent: decorator at wrong level ──────────────────────────

{
    my $src = "class C:\n  \@staticmethod\n  def f():\n    pass\n";
    my $out = py($src);
    like($out, qr/^    \@staticmethod$/m, 'misindented decorator corrected to depth 1');
    like($out, qr/^    def f\(\):$/m,     'def corrected to depth 1');
}

done_testing;
