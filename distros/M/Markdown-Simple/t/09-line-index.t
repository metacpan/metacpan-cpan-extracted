use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Phase 09: line index (find_newlines) must produce a byte-exact list of
# '\n' offsets for the active SIMD backend, matching the scalar
# reference and a pure-Perl re-implementation, including the overflow
# sentinel.

sub perl_newlines {
    my ($s) = @_;
    my @out;
    while ($s =~ /\n/g) { push @out, pos($s) - 1 }
    return @out;
}

sub unpack_offsets { return unpack 'L*', $_[0] }       # native u32

# ---- known-content sanity checks --------------------------------------
my @fixtures = (
    [ ""              , []                    ],
    [ "no newline"    , []                    ],
    [ "\n"            , [0]                   ],
    [ "a\nb\nc\n"     , [1, 3, 5]             ],
    [ "abc\n"         , [3]                   ],
    [ "\n\n\n"        , [0, 1, 2]             ],
    [ ("x" x 31) . "\n" . ("y" x 31) . "\n", [31, 63] ], # straddles 32-byte chunk
    [ ("a" x 100) . "\n" , [100]              ],
);

for my $i (0 .. $#fixtures) {
    my ($s, $expect) = @{$fixtures[$i]};
    my $av = Markdown::Simple::_find_newlines($s);        $av = '' unless defined $av;
    my $bv = Markdown::Simple::_find_newlines_scalar($s); $bv = '' unless defined $bv;
    my $a = [ unpack_offsets( $av ) ];
    my $b = [ unpack_offsets( $bv ) ];
    is_deeply $a, $expect, "active backend: fixture $i";
    is_deeply $b, $expect, "scalar backend: fixture $i";
}

# ---- fuzz: random bytes, all backends must agree with Perl ------------
srand(0xC0DE);
my $mismatches = 0;
for my $k (1 .. 200) {
    my $n = 1 + int(rand 4096);
    my $s = '';
    for (1 .. $n) {
        my $r = rand;
        $s .= $r < 0.1 ? "\n" :
              $r < 0.5 ? ' '  :
                         chr(ord('a') + int rand 26);
    }
    my @ref   = perl_newlines($s);
    my $av2 = Markdown::Simple::_find_newlines($s);        $av2 = '' unless defined $av2;
    my $bv2 = Markdown::Simple::_find_newlines_scalar($s); $bv2 = '' unless defined $bv2;
    my @act   = unpack_offsets( $av2 );
    my @sca   = unpack_offsets( $bv2 );
    if (join(',', @act) ne join(',', @ref) ||
        join(',', @sca) ne join(',', @ref)) {
        diag "mismatch iter=$k len=$n";
        diag "  ref: @ref";
        diag "  act: @act";
        diag "  sca: @sca";
        $mismatches++;
        last if $mismatches > 3;
    }
}
is $mismatches, 0, "fuzz: active + scalar agree with Perl on 200 random inputs";

# ---- boundary lengths: every length in 0..96 --------------------------
my $bm_total = 0; my $bm_ok = 0;
for my $n (0 .. 96) {
    my $s = '';
    for (1 .. $n) {
        $s .= rand() < 0.2 ? "\n" : 'x';
    }
    my @ref = perl_newlines($s);
    my $av3 = Markdown::Simple::_find_newlines($s); $av3 = '' unless defined $av3;
    my @act = unpack_offsets( $av3 );
    $bm_total++;
    $bm_ok++ if join(',', @act) eq join(',', @ref);
}
is $bm_ok, $bm_total, "active matches Perl across small lengths (0..96)";

# ---- overflow sentinel: cap=1 with multi-newline input ----------------
{
    my $s = "a\nb\nc\nd\n";        # 4 newlines
    my $r = Markdown::Simple::_find_newlines_capped($s, 1);
    is $r, undef, 'cap=1 overflows -> undef sentinel';
    my $r2 = Markdown::Simple::_find_newlines_capped($s, 4);
    is_deeply [ unpack_offsets($r2) ], [1,3,5,7],
        'cap=4 (exact) fits without overflow';
    my $r3 = Markdown::Simple::_find_newlines_capped($s, 100);
    is_deeply [ unpack_offsets($r3) ], [1,3,5,7],
        'cap > count succeeds';
}

# ---- forced-scalar: trivially equal to itself -------------------------
Markdown::Simple::_simd_force_scalar(1);
{
    my $s = '';
    $s .= rand() < 0.1 ? "\n" : 'x' for 1..4096;
    my $a = Markdown::Simple::_find_newlines($s);
    my $b = Markdown::Simple::_find_newlines_scalar($s);
    is $a, $b, 'force_scalar=1: self-equality on 4096 B';
}
Markdown::Simple::_simd_force_scalar(0);

done_testing;
