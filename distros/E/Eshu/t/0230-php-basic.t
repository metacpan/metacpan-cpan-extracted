use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── function + if/else ───────────────────────────────────────────

{
    my $src = <<'END';
function greet($name) {
if ($name) {
echo "Hello, $name";
} else {
echo "Hello, world";
}
}
END
    my $out = p($src);
    like($out, qr/^function greet\(\$name\) \{$/m,     'function at depth 0');
    like($out, qr/^    if \(\$name\) \{$/m,             'if at depth 1');
    like($out, qr/^        echo "Hello, \$name";$/m,    'echo at depth 2');
    like($out, qr/^    \} else \{$/m,                   'else at depth 1');
    like($out, qr/^        echo "Hello, world";$/m,     'else body at depth 2');
    like($out, qr/^    \}$/m,                           'inner closing brace at depth 1');
    like($out, qr/^\}$/m,                               'function closing brace at depth 0');
}

# ── class + method ───────────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
private $x;
public function bar() {
return $this->x;
}
}
END
    my $out = p($src);
    like($out, qr/^class Foo \{$/m,               'class at depth 0');
    like($out, qr/^    private \$x;$/m,            'property at depth 1');
    like($out, qr/^    public function bar\(\) \{$/m, 'method at depth 1');
    like($out, qr/^        return \$this->x;$/m,   'method body at depth 2');
    like($out, qr/^    \}$/m,                      'method closing brace at depth 1');
    like($out, qr/^\}$/m,                          'class closing brace at depth 0');
}

# ── for / foreach ────────────────────────────────────────────────

{
    my $src = <<'END';
for ($i = 0; $i < 10; $i++) {
echo $i;
}
foreach ($arr as $k => $v) {
echo "$k: $v";
}
END
    my $out = p($src);
    like($out, qr/^for \(/m,                     'for at depth 0');
    like($out, qr/^    echo \$i;$/m,              'for body at depth 1');
    like($out, qr/^foreach \(\$arr as/m,          'foreach at depth 0');
    like($out, qr/^    echo "\$k: \$v";$/m,       'foreach body at depth 1');
}

# ── detect_lang ──────────────────────────────────────────────────

{
    is(Eshu->detect_lang('foo.php'),   'php',  'detect .php');
    is(Eshu->detect_lang('foo.PHP'),   'php',  'detect .PHP');
    is(Eshu->detect_lang('foo.phtml'), 'php',  'detect .phtml');
}

done_testing;
