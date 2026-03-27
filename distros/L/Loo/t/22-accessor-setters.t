use strict;
use warnings;
use Test::More;
use Loo;

my $dd = Loo->new([1]);

# ── Pad ───────────────────────────────────────────────────────────
is($dd->Pad, '', 'pad default empty');
$dd->Pad('  ');
is($dd->Pad, '  ', 'pad set to two spaces');
$dd->Pad('# ');
is($dd->Pad, '# ', 'pad set to hash-space');

# ── Purity ────────────────────────────────────────────────────────
is($dd->Purity, 0, 'purity default 0');
$dd->Purity(1);
is($dd->Purity, 1, 'purity set to 1');

# ── Deepcopy ──────────────────────────────────────────────────────
is($dd->Deepcopy, 0, 'deepcopy default 0');
$dd->Deepcopy(1);
is($dd->Deepcopy, 1, 'deepcopy set to 1');

# ── Freezer ───────────────────────────────────────────────────────
is($dd->Freezer, '', 'freezer default empty');
$dd->Freezer('freeze');
is($dd->Freezer, 'freeze', 'freezer set');

# ── Toaster ───────────────────────────────────────────────────────
is($dd->Toaster, '', 'toaster default empty');
$dd->Toaster('thaw');
is($dd->Toaster, 'thaw', 'toaster set');

# ── Bless ─────────────────────────────────────────────────────────
is($dd->Bless, 'bless', 'bless default');
$dd->Bless('rebless');
is($dd->Bless, 'rebless', 'bless set');

# ── Sparseseen ────────────────────────────────────────────────────
is($dd->Sparseseen, 0, 'sparseseen default 0');
$dd->Sparseseen(1);
is($dd->Sparseseen, 1, 'sparseseen set to 1');

# ── Deparse ───────────────────────────────────────────────────────
is($dd->Deparse, 0, 'deparse default 0');
$dd->Deparse(1);
is($dd->Deparse, 1, 'deparse set to 1');

# ── Trailingcomma ─────────────────────────────────────────────────
is($dd->Trailingcomma, 0, 'trailingcomma default 0');
$dd->Trailingcomma(1);
is($dd->Trailingcomma, 1, 'trailingcomma set to 1');

# ── All setters return $self ──────────────────────────────────────
my $dd2 = Loo->new([1]);
for my $m (qw(Indent Pad Varname Terse Purity Useqq Quotekeys
              Maxdepth Maxrecurse Pair Trailingcomma Deepcopy
              Freezer Toaster Bless Deparse Sparseseen)) {
    my $ret = $dd2->$m($m =~ /^(Pad|Varname|Pair|Freezer|Toaster|Bless)$/
                        ? 'x' : 1);
    is($ret, $dd2, "$m setter returns \$self");
}

done_testing;
