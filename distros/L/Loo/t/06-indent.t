use strict;
use warnings;
use Test::More;
use Loo;

sub dd {
    my ($data, %opts) = @_;
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    while (my ($k, $v) = each %opts) {
        my $method = ucfirst($k);
        $dd->$method($v) if $dd->can($method);
    }
    return $dd->Dump;
}

# ── Indent 0 (compact) ───────────────────────────────────────────
is(dd([1, 2, 3], indent => 0), "\$VAR1 = [1, 2, 3];\n", 'indent 0 array');
is(dd({a => 1}, indent => 0), "\$VAR1 = {'a' => 1};\n", 'indent 0 hash');

# ── Indent 1 (single space, closing on its own line) ─────────────
my $i1 = dd([1, 2], indent => 1);
like($i1, qr/\[\n/, 'indent 1: opening bracket + newline');
like($i1, qr/^ 1,$/m, 'indent 1: single space indent');

# ── Indent 2 (default, 2-space) ──────────────────────────────────
my $i2 = dd([1, 2], indent => 2);
like($i2, qr/^  1,$/m, 'indent 2: two-space indent');

# ── Nested indent 0 ──────────────────────────────────────────────
is(dd([[1]], indent => 0), "\$VAR1 = [[1]];\n", 'indent 0 nested');

# ── Indentwidth 4 (four-space indentation) ───────────────────────
my $i4 = dd([1, 2], indent => 2, indentwidth => 4);
like($i4, qr/^    1,$/m, 'indentwidth 4: four-space indent on elements');
like($i4, qr/^    2$/m,  'indentwidth 4: four-space indent on last element');

my $i4h = dd({a => 1, b => 2}, indent => 2, indentwidth => 4, sortkeys => 1);
like($i4h, qr/^    'a'/m, 'indentwidth 4: four-space indent on hash keys');

# Nested with 4-space
my $i4n = dd({x => [1, 2]}, indent => 2, indentwidth => 4, sortkeys => 1);
like($i4n, qr/^        1,$/m, 'indentwidth 4: eight-space indent at depth 2');

# ── Usetabs (tab indentation) ───────────────────────────────────
my $it = dd([1, 2], indent => 2, usetabs => 1, indentwidth => 1);
like($it, qr/^\t1,$/m, 'usetabs: single tab indent on elements');
like($it, qr/^\t2$/m,  'usetabs: single tab indent on last element');

my $ith = dd({a => 1, b => 2}, indent => 2, usetabs => 1, indentwidth => 1, sortkeys => 1);
like($ith, qr/^\t'a'/m, 'usetabs: single tab indent on hash keys');

# Nested with tabs
my $itn = dd({x => [1, 2]}, indent => 2, usetabs => 1, indentwidth => 1, sortkeys => 1);
like($itn, qr/^\t\t1,$/m, 'usetabs: double tab indent at depth 2');

# Tabs with wider width (2 tabs per level)
my $it2 = dd([1, 2], indent => 2, usetabs => 1, indentwidth => 2);
like($it2, qr/^\t\t1,$/m, 'usetabs indentwidth 2: two tabs per level');

# ── Indentwidth with deparse ────────────────────────────────────
my $code = sub { my ($x) = @_; return $x * 2 };
my $dep4 = dd($code, indent => 2, indentwidth => 4, deparse => 1, terse => 1);
like($dep4, qr/^    /m, 'deparse indentwidth 4: four-space indent in deparsed code');
unlike($dep4, qr/^  [^ ]/m, 'deparse indentwidth 4: no two-space lines');

my $dept = dd($code, indent => 2, usetabs => 1, indentwidth => 1, deparse => 1, terse => 1);
like($dept, qr/^\t/m, 'deparse usetabs: tab indent in deparsed code');
unlike($dept, qr/^  [^ ]/m, 'deparse usetabs: no space-indented lines');

# ── Default indentwidth unchanged ────────────────────────────────
my $idef = dd([1, 2], indent => 2);
like($idef, qr/^  1,$/m, 'default indentwidth: still two spaces');
unlike($idef, qr/^\t/m,  'default: no tabs');

done_testing;
