use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── // comment doesn't affect depth ─────────────────────────────

{
    my $src = <<'END';
function foo() {
// this is a comment { not a block
$x = 1;
return $x;
}
END
    my $out = p($src);
    like($out, qr/^    \/\/ this is a comment/m, 'line comment at depth 1');
    like($out, qr/^    \$x = 1;$/m,              'code after comment at depth 1');
    like($out, qr/^    return \$x;$/m,            'return at depth 1');
    like($out, qr/^\}$/m,                         'closing brace at depth 0');
}

# ── # comment ────────────────────────────────────────────────────

{
    my $src = <<'END';
if ($x) {
# hash comment
echo $x;
}
END
    my $out = p($src);
    like($out, qr/^    # hash comment$/m,  'hash comment at depth 1');
    like($out, qr/^    echo \$x;$/m,       'code after hash comment at depth 1');
}

# ── block comment ────────────────────────────────────────────────

{
    my $src = <<'END';
function bar() {
/* this is
a block comment */
return 1;
}
END
    my $out = p($src);
    like($out, qr/^    \/\* this is$/m,      'block comment start at depth 1');
    like($out, qr/^    a block comment \*\//m,'block comment end re-indented');
    like($out, qr/^    return 1;$/m,          'code after block comment at depth 1');
}

# ── docblock ─────────────────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
/**
* Gets the bar.
*
* @return string
*/
public function getBar() {
return $this->bar;
}
}
END
    my $out = p($src);
    like($out, qr/^    \/\*\*$/m,           'docblock open at depth 1');
    like($out, qr/^    \* Gets the bar\.$/m,'docblock line at depth 1');
    like($out, qr/^    \*\/$/m,             'docblock close at depth 1');
    like($out, qr/^    public function/m,   'method after docblock at depth 1');
}

done_testing;
