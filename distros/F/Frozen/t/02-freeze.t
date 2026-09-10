#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use File::Temp ();

# Determinism, and every refusal.

# ---- deterministic bytes --------------------------------------------------
#
# THE test of this phase. Two child processes with different PERL_HASH_SEED
# and PERL_PERTURB_KEYS freeze the same structure and must produce identical
# bytes. This is what catches the day somebody reaches for PERL_HASH: its seed
# is randomised per process, so a block hashed with it would be unreadable in
# the process next door - intermittently, which is worse than never.

my $prog = <<'CODE';
use strict; use warnings; use Frozen ();
my $d = { zebra => 1, alpha => [3, 2, 1], middle => { b => 'x', a => 'y' },
          nested => { deep => { deeper => [ { k => 'v' } ] } } };
my $b = Frozen->freeze($d);
print unpack('H*', $b), "\n";
CODE

my $tmp = File::Temp->new(SUFFIX => '.pl');
print {$tmp} $prog;
close $tmp;

my @inc = map { "-I$_" } grep { !ref } @INC;
my @out;
for my $seed (0, 12345) {
    local $ENV{PERL_HASH_SEED}    = $seed;
    local $ENV{PERL_PERTURB_KEYS} = 1;
    my $hex = `"$^X" @inc "$tmp" 2>&1`;
    chomp $hex;
    push @out, $hex;
}

ok(length $out[0], 'the child produced bytes') or diag $out[0];
is($out[0], $out[1],
   'the same structure freezes to identical bytes under different '
 . 'PERL_HASH_SEED - hash order never reaches the block');

# ---- refusals, each naming the path ---------------------------------------

my @refusals = (
    ['a code reference', sub { 1 },                     qr/code reference/],
    ['a blessed ref',    bless({}, 'Some::Class'),      qr/blessed reference/],
    ['a glob',           \*STDOUT,                      qr/glob|scalar/],
    ['a scalar ref',     \'x',                          qr/reference to a scalar/],
);

for my $r (@refusals) {
    my ($name, $val, $re) = @$r;
    eval { Frozen->freeze({ top => { inner => $val } }); 1 };
    my $err = $@;
    like($err, $re, "$name is refused");
    like($err, qr/top\.inner/, "...and the message names the path to it")
        or diag $err;
}

# A cycle. The in-progress marker in the address map is what distinguishes
# this from a DAG; getting it wrong is an infinite loop, not a croak.
{
    my $h = { name => 'loop' };
    $h->{self} = $h;
    eval { Frozen->freeze({ outer => $h }); 1 };
    like($@, qr/a cycle/, 'a cycle is refused rather than followed');
    like($@, qr/outer/,   '...and the message names where');
}

# A DAG is NOT a cycle: the same subtree reachable twice is emitted once.
{
    my $shared = { a => 1, b => 2 };
    my $b = Frozen->freeze({ x => $shared, y => $shared });
    cmp_ok(Frozen->_walk_ok($b), '>', 0, 'a shared subtree walks clean');
    my $solo = Frozen->freeze({ x => { a => 1, b => 2 } });
    cmp_ok(length $b, '<', length($solo) + 64,
           'and is emitted once, not twice');
}

# Depth.
{
    my $deep = 'leaf';
    $deep = { d => $deep } for 1 .. 300;
    eval { Frozen->freeze($deep); 1 };
    like($@, qr/deeper than/, 'an over-deep structure croaks rather than '
                            . 'blowing the C stack');
}

# ---- freeze_to writes and renames ----------------------------------------

{
    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $path = "$dir/out.frz";
    Frozen->freeze_to($path, { hello => 'world' });
    ok(-f $path, 'freeze_to wrote the file');
    open my $fh, '<:raw', $path or die $!;
    my $blk = do { local $/; <$fh> };
    close $fh;
    is($blk, Frozen->freeze({ hello => 'world' }),
       'and the bytes are the same as freeze()');
    my @left = glob("$dir/*.tmp*");
    is(scalar @left, 0, 'no temporary file is left behind');
}

done_testing;
