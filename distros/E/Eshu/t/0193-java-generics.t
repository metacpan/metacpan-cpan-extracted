use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── generic field declarations ────────────────────────────────────

{
    my $src = <<'END';
class Foo {
List<String> names;
Map<String, Integer> scores;
}
END
    my $out = j($src);
    like($out, qr/^    List<String> names;$/m,         'List<T> field at depth 1');
    like($out, qr/^    Map<String, Integer> scores;$/m,'Map<K,V> field at depth 1');
}

# ── generic method signatures ─────────────────────────────────────

{
    my $src = <<'END';
class Foo {
<T extends Comparable<T>> T max(T a, T b) {
return a.compareTo(b) >= 0 ? a : b;
}
}
END
    my $out = j($src);
    like($out, qr/^    <T extends Comparable/m, 'generic method at depth 1');
    like($out, qr/^        return a\.compareTo/m,'generic method body at depth 2');
}

# ── nested generics ───────────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
Map<String, List<Integer>> data;
void process() {
Map<String, List<Integer>> tmp = new HashMap<>();
use(tmp);
}
}
END
    my $out = j($src);
    like($out, qr/^    Map<String, List<Integer>> data;$/m,
         'nested generic field');
    like($out, qr/^        Map<String, List<Integer>> tmp/m,
         'nested generic local var at depth 2');
    like($out, qr/^        use\(tmp\);$/m, 'use at depth 2');
}

# ── angle brackets in conditions don't affect depth ──────────────

{
    my $src = <<'END';
class Foo {
void check() {
if (a < b && c > d) {
doWork();
}
}
}
END
    my $out = j($src);
    like($out, qr/^    void check\(\) \{$/m,       'method at depth 1');
    like($out, qr/^        if \(a < b && c > d\)/m,'if with < > at depth 2');
    like($out, qr/^            doWork\(\);$/m,      'if body at depth 3');
}

# ── wildcard generics ─────────────────────────────────────────────

{
    my $src = <<'END';
class Foo {
void accept(List<? extends Number> nums) {
for (Number n : nums) {
use(n);
}
}
}
END
    my $out = j($src);
    like($out, qr/^    void accept\(List<\? extends Number>/m,
         'wildcard generic parameter');
    like($out, qr/^        for \(Number n : nums\)/m,
         'enhanced for loop at depth 2');
    like($out, qr/^            use\(n\);$/m, 'for body at depth 3');
}

done_testing;
