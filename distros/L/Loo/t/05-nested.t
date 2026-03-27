use strict;
use warnings;
use Test::More;
use Loo;

sub dump_sorted {
    my ($data) = @_;
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    return $dd->Dump;
}

# ── Deeply nested structure ───────────────────────────────────────
my $deep = { a => { b => { c => [1, 2, { d => 'end' }] } } };
my $out = dump_sorted($deep);
like($out, qr/'a'/, 'deep: has key a');
like($out, qr/'b'/, 'deep: has key b');
like($out, qr/'c'/, 'deep: has key c');
like($out, qr/'d' => 'end'/, 'deep: nested leaf');
like($out, qr/\[/, 'deep: has array bracket');

# ── Array of hashes ───────────────────────────────────────────────
my $aoh = [{name => 'a'}, {name => 'b'}];
$out = dump_sorted($aoh);
like($out, qr/'name' => 'a'/, 'aoh: first element');
like($out, qr/'name' => 'b'/, 'aoh: second element');

# ── Hash of arrays ────────────────────────────────────────────────
my $hoa = {x => [1, 2], y => [3, 4]};
$out = dump_sorted($hoa);
like($out, qr/'x' => \[/, 'hoa: key x has array');
like($out, qr/'y' => \[/, 'hoa: key y has array');

# ── Mixed nesting ─────────────────────────────────────────────────
my $mix = [1, {a => [2, {b => 3}]}, 'end'];
$out = dump_sorted($mix);
like($out, qr/1/, 'mixed: top-level integer');
like($out, qr/'a'/, 'mixed: hash key');
like($out, qr/'b' => 3/, 'mixed: deep key/value');
like($out, qr/'end'/, 'mixed: trailing string');

done_testing;
