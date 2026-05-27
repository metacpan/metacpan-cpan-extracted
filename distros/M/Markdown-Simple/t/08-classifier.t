use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Phase 08 fuzz: classifier output must be bit-identical between the
# active SIMD backend and the scalar reference, for every length up to
# (and including) sizes that exercise the scalar tail.

# Use a deterministic seed so failures are reproducible.
srand(0xC0FFEE);

sub rand_bytes {
    my ($n) = @_;
    return join '', map { chr int rand 256 } 1 .. $n;
}

# Sanity: known structural bytes light up; ordinary bytes don't.
{
    my @set = ("\t","\n","\r"," ","!","\"","#","&","(",")",
               "*","+","-",".",":","<","=",">","[","\\",
               "]","_","`","|","~");
    my $s = join '', @set;
    my $bm = Markdown::Simple::_classify_structural_scalar($s);
    for my $i (0 .. $#set) {
        my $byte = ord substr $bm, $i >> 3, 1;
        ok($byte & (1 << ($i & 7)),
           sprintf("scalar: structural byte %s (idx %d) classified",
                   _esc($set[$i]), $i));
    }
}
{
    my $s = "abcdefghijklmnopqrstuvwxyz0123456789";
    my $bm = Markdown::Simple::_classify_structural_scalar($s);
    for my $i (0 .. length($s) - 1) {
        my $byte = ord substr $bm, $i >> 3, 1;
        ok(!($byte & (1 << ($i & 7))),
           sprintf("scalar: ordinary byte '%s' not classified",
                   substr($s,$i,1)));
    }
}

# Fuzz: 500 random inputs, lengths 1..2048, compare active backend to scalar.
my $iters = 500;
my $mismatch = 0;
for my $k (1 .. $iters) {
    my $n = int(rand 2048) + 1;
    my $s = rand_bytes($n);
    my $a = Markdown::Simple::_classify_structural($s);
    my $b = Markdown::Simple::_classify_structural_scalar($s);
    if ($a ne $b) {
        diag "mismatch iter=$k n=$n";
        diag "active: ", unpack('H*', $a);
        diag "scalar: ", unpack('H*', $b);
        $mismatch++;
        last if $mismatch > 3;
    }
}
is $mismatch, 0, "active backend matches scalar across $iters random inputs";

# Boundary lengths: every length in 0..96 exercises the scalar tail.
my $bm_match = 0; my $bm_total = 0;
for my $n (0 .. 96) {
    my $s = rand_bytes($n);
    my $a = Markdown::Simple::_classify_structural($s);
    my $b = Markdown::Simple::_classify_structural_scalar($s);
    $bm_total++;
    $bm_match++ if $a eq $b;
}
is $bm_match, $bm_total, "active backend matches scalar across small lengths (0..96)";

# Forced-scalar path is trivially identical to itself.
Markdown::Simple::_simd_force_scalar(1);
{
    my $s = rand_bytes(4096);
    my $a = Markdown::Simple::_classify_structural($s);
    my $b = Markdown::Simple::_classify_structural_scalar($s);
    is $a, $b, "force_scalar=1: trivial self-equality on 4096 B";
}
Markdown::Simple::_simd_force_scalar(0);

done_testing;

sub _esc {
    my ($c) = @_;
    return '\\t' if $c eq "\t";
    return '\\n' if $c eq "\n";
    return '\\r' if $c eq "\r";
    return "'$c'";
}
