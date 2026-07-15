use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ruby($_[0], indent_char => ' ', indent_width => 2) }

# ── instance / class / global vars don't affect depth ────────────

{
    my $src = <<'END';
class Counter
@@count = 0
def initialize
@value = 0
@@count += 1
$last = self
end
end
END
    my $out = r($src);
    like($out, qr/^class Counter$/m,    'class at depth 0');
    like($out, qr/^  \@\@count = 0$/m,   '@@class var at depth 1');
    like($out, qr/^  def initialize$/m,'def at depth 1');
    like($out, qr/^    \@value = 0$/m,  '@ivar at depth 2');
    like($out, qr/^    \@\@count \+= 1$/m,'@@class var in method at depth 2');
    like($out, qr/^    \$last = self$/m,'$global at depth 2');
    like($out, qr/^  end$/m,           'def end at depth 1');
    like($out, qr/^end$/m,             'class end at depth 0');
}

# ── indent_string dispatch ───────────────────────────────────────

{
    my $src = "def foo\nputs 1\nend\n";
    my $out = Eshu->indent_string($src, lang => 'ruby');
    like($out, qr/^def foo$/m,   'indent_string ruby: def');
    like($out, qr/^  puts 1$/m,  'indent_string ruby: body at 2 spaces');
    like($out, qr/^end$/m,       'indent_string ruby: end');
}

# ── indent_string with rb alias ──────────────────────────────────

{
    my $src = "def bar\nx = 1\nend\n";
    my $out = Eshu->indent_string($src, lang => 'rb');
    like($out, qr/^  x = 1$/m, 'indent_string rb alias works');
}

done_testing;
