use 5.008003;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test2::Bundle::Numerical;
use Font::Metrics;

plan tests => 27;

my $hv = Font::Metrics->new(name => 'Helvetica');
my $tr = Font::Metrics->new(name => 'Times-Roman');
my $cr = Font::Metrics->new(name => 'Courier');

# ── additive property ─────────────────────────────────────────────────────────
# string_width(s) must equal sum of char_width for every character.
# This is the invariant that word-wrap relies on.

sub sum_chars {
    my ($fm, $text, $size) = @_;
    my $w = 0;
    $w += $fm->char_width($_, $size) for split //, $text;
    return $w;
}

{
    my $s = 'The quick brown fox jumps over the lazy dog';
    approx_ok($hv->string_width($s, 12), sum_chars($hv, $s, 12), 0.01,
        'Hv pangram: string_width = sum of char_widths at 12pt');
    approx_ok($tr->string_width($s, 12), sum_chars($tr, $s, 12), 0.01,
        'Tr pangram: string_width = sum of char_widths at 12pt');
    approx_ok($cr->string_width($s, 12), sum_chars($cr, $s, 12), 0.01,
        'Cr pangram: string_width = sum of char_widths at 12pt');
}

# ── split-at-space invariant (word-wrap accumulation) ────────────────────────
# string_width("word1 word2 word3") = sum of string_width(word) + char_width(' ') * gaps

sub measure_words {
    my ($fm, $text, $size) = @_;
    my @words = split / /, $text;
    my $sp = $fm->char_width(' ', $size);
    my $w  = 0;
    $w += $fm->string_width($_, $size) for @words;
    $w += $sp * (@words - 1) if @words > 1;
    return $w;
}

{
    my $sentence = 'Pack my box with five dozen liquor jugs';
    approx_ok($hv->string_width($sentence, 10), measure_words($hv, $sentence, 10), 0.01,
        'Hv word-split invariant: whole == sum of words + spaces');
    approx_ok($tr->string_width($sentence, 10), measure_words($tr, $sentence, 10), 0.01,
        'Tr word-split invariant: whole == sum of words + spaces');
}

# ── concatenation: string_width(a . b) = string_width(a) + string_width(b) ──

{
    my ($a, $b) = ('Hello', ' World');
    approx_ok($hv->string_width($a . $b, 12),
              $hv->string_width($a, 12) + $hv->string_width($b, 12),
              0.001, 'Hv string_width(a.b) = width(a) + width(b)');
    approx_ok($tr->string_width($a . $b, 12),
              $tr->string_width($a, 12) + $tr->string_width($b, 12),
              0.001, 'Tr string_width(a.b) = width(a) + width(b)');
}

# ── long sentence at multiple sizes ──────────────────────────────────────────

{
    my $long = 'Sphinx of black quartz, judge my vow. '
             . 'How vexingly quick daft zebras jump! '
             . 'The five boxing wizards jump quickly.';

    my $w6  = $hv->string_width($long,  6);
    my $w12 = $hv->string_width($long, 12);
    my $w24 = $hv->string_width($long, 24);

    approx_ok($w12, $w6  * 2, 0.1, 'Hv long sentence: 12pt = 2 × 6pt');
    approx_ok($w24, $w12 * 2, 0.1, 'Hv long sentence: 24pt = 2 × 12pt');

    # additive check on the long sentence
    approx_ok($w12, sum_chars($hv, $long, 12), 0.05,
        'Hv long sentence: string_width = sum of char_widths');
}

# ── different fonts differ on same text ──────────────────────────────────────

{
    my $s = 'Typography matters in PDF layout';
    my $w_hv = $hv->string_width($s, 12);
    my $w_tr = $tr->string_width($s, 12);
    my $w_cr = $cr->string_width($s, 12);

    ok($w_hv != $w_tr, 'Helvetica and Times-Roman differ for same text');
    ok($w_cr != $w_hv, 'Courier and Helvetica differ (Courier is fixed-pitch)');

    # Courier: every char is 600/1000 * size → total = n_chars * 0.6 * size
    my $n = length($s);
    approx_ok($w_cr, $n * 0.6 * 12, 0.01,
        'Courier string_width = n_chars * 600/1000 * 12');
}

# ── empty and single-char edge cases ─────────────────────────────────────────

approx_ok($hv->string_width('',  12), 0, 0.001, 'empty string → 0');
approx_ok($hv->string_width(' ', 12), $hv->char_width(' ', 12), 0.001,
    'single space: string_width = char_width');

# ── word-wrap simulation ──────────────────────────────────────────────────────
# Verify that greedily accumulating words until they exceed avail_w matches
# what we would expect from line counts.

{
    my $text   = 'The quick brown fox jumps over the lazy dog';
    my @words  = split / /, $text;
    my $size   = 12;
    my $sp_w   = $hv->char_width(' ', $size);

    # measure at 200pt wide
    my $avail  = 200;
    my $lines  = 0;
    my $line_w = 0;
    for my $word (@words) {
        my $ww = $hv->string_width($word, $size);
        if ($line_w == 0) {
            $line_w = $ww; $lines = 1;
        } elsif ($line_w + $sp_w + $ww > $avail) {
            $line_w = $ww; $lines++;
        } else {
            $line_w += $sp_w + $ww;
        }
    }
    ok($lines >= 2, "pangram at 200pt wraps to at least 2 lines (got $lines)");
    ok($lines <= 5, "pangram at 200pt wraps to at most 5 lines (got $lines)");

    # at 2000pt it fits on one line
    $avail  = 2000;
    $lines  = 0; $line_w = 0;
    for my $word (@words) {
        my $ww = $hv->string_width($word, $size);
        if ($line_w == 0) { $line_w = $ww; $lines = 1; }
        elsif ($line_w + $sp_w + $ww > $avail) { $line_w = $ww; $lines++; }
        else { $line_w += $sp_w + $ww; }
    }
    ok($lines == 1, 'pangram at 2000pt fits on one line');
}

# ── UTF-8 long string additive invariant ─────────────────────────────────────

{
    my $utf8 = "R\x{E9}sum\x{E9} of a caf\x{E9} owner in M\x{F6}bius";
    approx_ok($hv->string_width($utf8, 12), sum_chars($hv, $utf8, 12), 0.01,
        'Hv UTF-8 long string: string_width = sum of char_widths');
    approx_ok($tr->string_width($utf8, 12), sum_chars($tr, $utf8, 12), 0.01,
        'Tr UTF-8 long string: string_width = sum of char_widths');
}

# ── TrueType ──────────────────────────────────────────────────────────────────

my $ttf = 't/TrebuchetMS.ttf';
SKIP: {
    skip 'TrebuchetMS.ttf not present in t/', 7 unless -f $ttf;

    my $f = Font::Metrics->new(file => $ttf);

    my $long = 'The five boxing wizards jump quickly over lazy sphinx';
    approx_ok($f->string_width($long, 12), sum_chars($f, $long, 12), 0.1,
        'TT long sentence: string_width = sum of char_widths');

    # split at spaces
    approx_ok($f->string_width($long, 12), measure_words($f, $long, 12), 0.1,
        'TT long sentence: word-split invariant');

    # scale linearity
    approx_ok($f->string_width($long, 24), $f->string_width($long, 12) * 2, 0.2,
        'TT long sentence: 24pt = 2 × 12pt');

    # UTF-8 long string additive
    my $utf8 = "caf\x{E9} r\x{E9}sum\x{E9} na\x{EF}ve";
    approx_ok($f->string_width($utf8, 12), sum_chars($f, $utf8, 12), 0.1,
        'TT UTF-8 long string: string_width = sum of char_widths');

    # word-wrap simulation
    my $text   = 'Pack my box with five dozen liquor jugs';
    my @words  = split / /, $text;
    my $size   = 12;
    my $sp_w   = $f->char_width(' ', $size);
    my $avail  = 150;   # sentence is ~214pt wide at 12pt; 150pt forces wrap
    my ($lines, $line_w) = (0, 0);
    for my $word (@words) {
        my $ww = $f->string_width($word, $size);
        if ($line_w == 0) { $line_w = $ww; $lines = 1; }
        elsif ($line_w + $sp_w + $ww > $avail) { $line_w = $ww; $lines++; }
        else { $line_w += $sp_w + $ww; }
    }
    ok($lines >= 2, "TT sentence at 250pt wraps to at least 2 lines (got $lines)");
    ok($lines <= 4, "TT sentence at 250pt wraps to at most 4 lines (got $lines)");

    # consistency: same string measured twice gives same result
    approx_ok($f->string_width($long, 12), $f->string_width($long, 12), 0.001,
        'TT string_width is deterministic');
}

done_testing;
