use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── @Override on method ───────────────────────────────────────────

{
    my $src = <<'END';
class Foo extends Base {
@Override
public void run() {
doWork();
}
}
END
    my $out = j($src);
    like($out, qr/^    \@Override$/m,      '@Override at depth 1');
    like($out, qr/^    public void run/m,  'annotated method at depth 1');
    like($out, qr/^        doWork\(\);$/m, 'method body at depth 2');
}

# ── @SuppressWarnings ─────────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
@SuppressWarnings("unchecked")
public List getItems() {
return items;
}
}
END
    my $out = j($src);
    like($out, qr/^    \@SuppressWarnings/m,  '@SuppressWarnings at depth 1');
    like($out, qr/^    public List getItems/m, 'method at depth 1');
    like($out, qr/^        return items/m,     'method body at depth 2');
}

# ── multiple annotations ──────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
@Deprecated
@Override
public void old() {
}
}
END
    my $out = j($src);
    like($out, qr/^    \@Deprecated$/m,    'first annotation at depth 1');
    like($out, qr/^    \@Override$/m,      'second annotation at depth 1');
    like($out, qr/^    public void old/m,  'method at depth 1');
}

# ── annotation on class ───────────────────────────────────────────

{
    my $src = <<'END';
@FunctionalInterface
public interface Runnable {
void run();
}
END
    my $out = j($src);
    like($out, qr/^\@FunctionalInterface$/m,  '@FunctionalInterface at depth 0');
    like($out, qr/^public interface Runnable/m,'interface at depth 0');
    like($out, qr/^    void run\(\);$/m,       'interface method at depth 1');
}

# ── annotation with parens ────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
@SuppressWarnings({"all"})
void go() {
work();
}
}
END
    my $out = j($src);
    like($out, qr/^    \@SuppressWarnings/m, 'annotation with parens at depth 1');
    like($out, qr/^    void go\(\) \{$/m,    'method at depth 1');
    like($out, qr/^        work\(\);$/m,     'method body at depth 2');
}

done_testing;
