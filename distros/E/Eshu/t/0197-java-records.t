use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── simple record ─────────────────────────────────────────────────

{
    my $src = <<'END';
record Point(int x, int y) {
}
END
    my $out = j($src);
    like($out, qr/^record Point\(int x, int y\) \{$/m, 'record header at depth 0');
    like($out, qr/^\}$/m, 'record close at depth 0');
}

# ── record with compact constructor ──────────────────────────────

{
    my $src = <<'END';
record Range(int lo, int hi) {
Range {
if (lo > hi) throw new IllegalArgumentException();
}
}
END
    my $out = j($src);
    like($out, qr/^record Range/m,                           'record header');
    like($out, qr/^    Range \{$/m,                          'compact constructor at depth 1');
    like($out, qr/^        if \(lo > hi\) throw/m,           'constructor body at depth 2');
}

# ── record with methods ───────────────────────────────────────────

{
    my $src = <<'END';
record Person(String name, int age) {
public String greeting() {
return "Hello, " + name;
}
public boolean isAdult() {
return age >= 18;
}
}
END
    my $out = j($src);
    like($out, qr/^    public String greeting\(\) \{$/m, 'first method at depth 1');
    like($out, qr/^        return "Hello, "/m,           'first method body at depth 2');
    like($out, qr/^    public boolean isAdult\(\) \{$/m, 'second method at depth 1');
    like($out, qr/^        return age >= 18;$/m,         'second method body at depth 2');
}

# ── record implementing interface ─────────────────────────────────

{
    my $src = <<'END';
record Wrapper<T>(T value) implements Comparable<Wrapper<T>> {
@Override
public int compareTo(Wrapper<T> other) {
return 0;
}
}
END
    my $out = j($src);
    like($out, qr/^record Wrapper<T>/m,                  'generic record');
    like($out, qr/^    \@Override$/m,                    '@Override in record at depth 1');
    like($out, qr/^    public int compareTo/m,           'method at depth 1');
    like($out, qr/^        return 0;$/m,                 'method body at depth 2');
}

# ── sealed class with permits ─────────────────────────────────────

{
    my $src = <<'END';
sealed class Shape permits Circle, Square {
abstract double area();
}
END
    my $out = j($src);
    like($out, qr/^sealed class Shape permits/m,    'sealed class at depth 0');
    like($out, qr/^    abstract double area\(\);$/m,'abstract method at depth 1');
}

done_testing;
