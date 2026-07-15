use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── static inner class ────────────────────────────────────────────

{
    my $src = <<'END';
class Outer {
static class Inner {
void go() {
work();
}
}
}
END
    my $out = j($src);
    like($out, qr/^class Outer \{$/m,          'outer class at depth 0');
    like($out, qr/^    static class Inner \{$/m,'inner class at depth 1');
    like($out, qr/^        void go\(\) \{$/m,  'inner method at depth 2');
    like($out, qr/^            work\(\);$/m,   'inner method body at depth 3');
    like($out, qr/^        \}$/m,              'inner method close at depth 2');
    like($out, qr/^    \}$/m,                  'inner class close at depth 1');
    like($out, qr/^\}$/m,                      'outer class close at depth 0');
}

# ── anonymous class ───────────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
void go() {
Runnable r = new Runnable() {
public void run() {
doWork();
}
};
r.run();
}
}
END
    my $out = j($src);
    like($out, qr/^        Runnable r = new Runnable\(\) \{$/m,
         'anonymous class at depth 2');
    like($out, qr/^            public void run\(\) \{$/m,
         'anon class method at depth 3');
    like($out, qr/^                doWork\(\);$/m,
         'anon method body at depth 4');
    like($out, qr/^        \};$/m,   'anonymous class close at depth 2');
    like($out, qr/^        r\.run/m, 'code after anon class at depth 2');
}

# ── lambda expression ─────────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
void go() {
list.stream().filter(x -> x > 0).forEach(x -> {
process(x);
});
}
}
END
    my $out = j($src);
    like($out, qr/^        list\.stream/m,    'lambda chain at depth 2');
    like($out, qr/^            process\(x\)/m,'lambda body at depth 3');
}

# ── interface with default methods ────────────────────────────────

{
    my $src = <<'END';
interface MyInterface {
void required();
default void optional() {
doDefault();
}
}
END
    my $out = j($src);
    like($out, qr/^    void required\(\);$/m,      'interface abstract method at depth 1');
    like($out, qr/^    default void optional/m,    'default method at depth 1');
    like($out, qr/^        doDefault\(\);$/m,      'default method body at depth 2');
}

done_testing;
