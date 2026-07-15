use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── basic try / catch / finally ───────────────────────────────────

{
    my $src = <<'END';
void go() {
try {
riskyOp();
} catch (Exception e) {
handle(e);
} finally {
cleanup();
}
}
END
    my $out = j($src);
    like($out, qr/^    try \{$/m,               'try at depth 1');
    like($out, qr/^        riskyOp\(\);$/m,     'try body at depth 2');
    like($out, qr/^    \} catch \(Exception/m,  'catch at depth 1');
    like($out, qr/^        handle\(e\);$/m,     'catch body at depth 2');
    like($out, qr/^    \} finally \{$/m,        'finally at depth 1');
    like($out, qr/^        cleanup\(\);$/m,     'finally body at depth 2');
}

# ── multi-catch ───────────────────────────────────────────────────

{
    my $src = <<'END';
void go() {
try {
op();
} catch (IOException | SQLException e) {
log(e);
}
}
END
    my $out = j($src);
    like($out, qr/^    \} catch \(IOException \| SQLException/m,
         'multi-catch syntax preserved');
    like($out, qr/^        log\(e\);$/m, 'multi-catch body at depth 2');
}

# ── try-with-resources ───────────────────────────────────────────

{
    my $src = <<'END';
void go() throws IOException {
try (InputStream in = openStream()) {
process(in);
} catch (IOException e) {
throw e;
}
}
END
    my $out = j($src);
    like($out, qr/^    try \(InputStream in/m,    'try-with-resources header');
    like($out, qr/^        process\(in\);$/m,     'try-with-resources body');
    like($out, qr/^    \} catch \(IOException/m,  'catch after try-with-resources');
}

# ── nested try ────────────────────────────────────────────────────

{
    my $src = <<'END';
void go() {
try {
try {
inner();
} catch (InnerException e) {
handleInner(e);
}
} catch (OuterException e) {
handleOuter(e);
}
}
END
    my $out = j($src);
    like($out, qr/^    try \{$/m,                    'outer try');
    like($out, qr/^        try \{$/m,                'inner try at depth 2');
    like($out, qr/^            inner\(\);$/m,        'inner try body at depth 3');
    like($out, qr/^        \} catch \(InnerEx/m,    'inner catch');
    like($out, qr/^    \} catch \(OuterEx/m,         'outer catch');
}

# ── try without catch (finally only) ─────────────────────────────

{
    my $src = <<'END';
void go() {
try {
op();
} finally {
done();
}
}
END
    my $out = j($src);
    like($out, qr/^    try \{$/m,          'try-finally: try');
    like($out, qr/^        op\(\);$/m,    'try-finally: body');
    like($out, qr/^    \} finally \{$/m,  'try-finally: finally');
    like($out, qr/^        done\(\);$/m,  'try-finally: finally body');
}

done_testing;
