use strict;
use warnings;
use Test::More;
use Eshu;

sub p { Eshu->indent_php($_[0], indent_char => ' ', indent_width => 4) }

# ── try / catch / finally ────────────────────────────────────────

{
    my $src = <<'END';
try {
$r = doSomething();
} catch (RuntimeException $e) {
echo $e->getMessage();
} finally {
cleanup();
}
END
    my $out = p($src);
    like($out, qr/^try \{$/m,                      'try at depth 0');
    like($out, qr/^    \$r = doSomething\(\);$/m,  'try body at depth 1');
    like($out, qr/^\} catch \(RuntimeException/m,  'catch at depth 0');
    like($out, qr/^    echo \$e->getMessage/m,      'catch body at depth 1');
    like($out, qr/^\} finally \{$/m,               'finally at depth 0');
    like($out, qr/^    cleanup\(\);$/m,             'finally body at depth 1');
    like($out, qr/^\}$/m,                           'closing brace at depth 0');
}

# ── multi-catch (PHP 8) ───────────────────────────────────────────

{
    my $src = <<'END';
try {
foo();
} catch (IOException | RuntimeException $e) {
handle($e);
}
END
    my $out = p($src);
    like($out, qr/^try \{$/m,                           'try at depth 0');
    like($out, qr/^\} catch \(IOException \| RuntimeException/m, 'multi-catch');
    like($out, qr/^    handle\(\$e\);$/m,                'catch body at depth 1');
}

# ── nested try ───────────────────────────────────────────────────

{
    my $src = <<'END';
function riskyOp() {
try {
try {
innerOp();
} catch (InnerException $e) {
log($e);
}
outerOp();
} catch (OuterException $e) {
bail($e);
}
}
END
    my $out = p($src);
    like($out, qr/^function riskyOp\(\) \{$/m,    'function at depth 0');
    like($out, qr/^    try \{$/m,                  'outer try at depth 1');
    like($out, qr/^        try \{$/m,              'inner try at depth 2');
    like($out, qr/^            innerOp\(\);$/m,    'inner try body at depth 3');
    like($out, qr/^        \} catch \(InnerException/m, 'inner catch');
    like($out, qr/^            log\(\$e\);$/m,     'inner catch body at depth 3');
    like($out, qr/^        outerOp\(\);$/m,        'after inner try at depth 2');
    like($out, qr/^    \} catch \(OuterException/m,'outer catch at depth 1');
}

done_testing;
