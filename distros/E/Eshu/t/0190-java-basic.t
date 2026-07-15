use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── class body ───────────────────────────────────────────────────

{
    my $src = <<'END';
public class Foo {
int x;
void hello() {
System.out.println("hi");
}
}
END
    my $out = j($src);
    like($out, qr/^public class Foo \{$/m,          'class declaration at depth 0');
    like($out, qr/^    int x;$/m,                   'field at depth 1');
    like($out, qr/^    void hello\(\) \{$/m,        'method declaration at depth 1');
    like($out, qr/^        System\.out\.println/m,  'method body at depth 2');
    like($out, qr/^    \}$/m,                       'method closing brace at depth 1');
    like($out, qr/^\}$/m,                           'class closing brace at depth 0');
}

# ── if / else ────────────────────────────────────────────────────

{
    my $src = <<'END';
void check(int x) {
if (x > 0) {
return;
} else {
throw new IllegalArgumentException();
}
}
END
    my $out = j($src);
    like($out, qr/^    if \(x > 0\) \{$/m,             'if at depth 1');
    like($out, qr/^        return;$/m,                  'if body at depth 2');
    like($out, qr/^    \} else \{$/m,                   'else at depth 1');
    like($out, qr/^        throw new IllegalArgument/m, 'else body at depth 2');
}

# ── for loop ─────────────────────────────────────────────────────

{
    my $src = <<'END';
void loop() {
for (int i = 0; i < 10; i++) {
doWork(i);
}
}
END
    my $out = j($src);
    like($out, qr/^    for \(int i/m,    'for header at depth 1');
    like($out, qr/^        doWork\(i\)/m,'for body at depth 2');
}

# ── while loop ───────────────────────────────────────────────────

{
    my $src = <<'END';
void run() {
while (running) {
tick();
}
}
END
    my $out = j($src);
    like($out, qr/^    while \(running\) \{$/m, 'while header at depth 1');
    like($out, qr/^        tick\(\);$/m,         'while body at depth 2');
}

# ── empty class ───────────────────────────────────────────────────

{
    my $src = "class Empty {\n}\n";
    my $out = j($src);
    like($out, qr/^class Empty \{$/m, 'empty class open');
    like($out, qr/^\}$/m,             'empty class close');
}

# ── detect_lang .java ─────────────────────────────────────────────

is(Eshu->detect_lang('Foo.java'), 'java', 'detect_lang .java → java');
is(Eshu->detect_lang('Bar.JAVA'), 'java', 'detect_lang .JAVA → java (case-insensitive)');

# ── indent_string dispatch ────────────────────────────────────────

{
    my $src = "class A {\nvoid f() {\nreturn;\n}\n}";
    my $out = Eshu->indent_string($src, lang => 'java');
    like($out, qr/^    void f/m,     'indent_string java: method at depth 1');
    like($out, qr/^        return/m, 'indent_string java: body at depth 2');
}

# ── default 4-space indent ────────────────────────────────────────

{
    my $out = Eshu->indent_java("class A {\nvoid f() {}\n}");
    like($out, qr/^    void f/m, 'indent_java default is 4-space');
}

done_testing;
