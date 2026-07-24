#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

eval { require Font::Metrics };
if ($@) {
    plan skip_all => 'Font::Metrics not installed';
    exit 0;
}

use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

my $fm = Font::Metrics->new(name => 'Helvetica');

# ── object type ───────────────────────────────────────────────────────────────

{
    my $fmm = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);
    ok(ref($fmm) eq 'Layout::Flex::FMeasure', 'returns Layout::Flex::FMeasure object');
    ok($fmm->isa('Layout::Flex::FMeasure'),   'isa check passes');
}

# ── missing fm arg croaks ─────────────────────────────────────────────────────

{
    eval { Layout::Flex->font_metrics_measure(size => 12) };
    ok($@, 'croaks when fm is missing');
}

# ── natural sizing (first pass) ───────────────────────────────────────────────
# width = string_width; height = default line_height (size × 1.2)

{
    my $fmm    = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);
    my $expect_w = $fm->string_width('Hello', 12);
    my $expect_h = 12 * 1.2;

    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => 'Hello' }],
    );
    approx_ok($o[0][2], $expect_w, 0.5, 'natural width = string_width("Hello",12)');
    approx_ok($o[0][3], $expect_h, 0.5, 'natural height = size × 1.2 = 14.4');
}

# ── custom size ───────────────────────────────────────────────────────────────

{
    my $fmm10    = Layout::Flex->font_metrics_measure(fm => $fm, size => 10);
    my $expect_w = $fm->string_width('Hi', 10);
    my $expect_h = 10 * 1.2;

    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm10,
        items      => [{ text => 'Hi' }],
    );
    approx_ok($o[0][2], $expect_w, 0.5, 'custom size: width at size=10');
    approx_ok($o[0][3], $expect_h, 0.5, 'custom size: height = 10 × 1.2 = 12');
}

# ── custom line_height ────────────────────────────────────────────────────────

{
    my $fmm = Layout::Flex->font_metrics_measure(fm => $fm, size => 12, line_height => 20);

    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => 'Hi' }],
    );
    approx_ok($o[0][3], 20, 0.5, 'custom line_height overrides size × 1.2');
}

# ── wrap_text: single line (text fits in available width) ────────────────────

{
    my $fmm  = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);
    my $w    = $fm->string_width('Hi there', 12);

    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => 'Hi there', basis => $w + 20, wrap_text => 1 }],
    );
    approx_ok($o[0][3], 12 * 1.2, 0.5, 'wrap_text: text fits → h = 1 × line_height');
}

# ── wrap_text: breaks to 2 lines ─────────────────────────────────────────────

{
    my $fmm   = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);
    my $w_hi  = $fm->string_width('Hi',    12);
    my $w_all = $fm->string_width('Hi there', 12);
    my $narrow = ($w_hi + $w_all) / 2;   # wider than "Hi" but narrower than "Hi there"

    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => 'Hi there', basis => $narrow, wrap_text => 1 }],
    );
    approx_ok($o[0][3], 2 * 12 * 1.2, 0.5, 'wrap_text: "Hi there" too wide → 2 lines');
}

# ── wrap_text: breaks to 3 lines ─────────────────────────────────────────────

{
    my $fmm    = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);
    my $w_one  = $fm->string_width('A',   12);
    my $w_two  = $fm->string_width('A B', 12);
    my $narrow = ($w_one + $w_two) / 2;   # fits one word per line

    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => 'A B C', basis => $narrow, wrap_text => 1 }],
    );
    approx_ok($o[0][3], 3 * 12 * 1.2, 0.5, 'wrap_text: "A B C" at 1-word width → 3 lines');
}

# ── empty text ────────────────────────────────────────────────────────────────

{
    my $fmm = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);

    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => '' }],
    );
    approx_ok($o[0][2], 0,        0.01, 'empty text: width = 0');
    approx_ok($o[0][3], 12 * 1.2, 0.5,  'empty text: height = line_height');
}

# ── two items without grow keep natural widths ────────────────────────────────

{
    my $fmm = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);
    my $w1  = $fm->string_width('AB',   12);
    my $w2  = $fm->string_width('CDEF', 12);

    my @o = c(
        main_size  => $w1 + $w2 + 100,
        cross_size => 200,
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => 'AB' }, { text => 'CDEF' }],
    );
    approx_ok($o[0][2], $w1, 0.5, 'two items: first item width');
    approx_ok($o[1][2], $w2, 0.5, 'two items: second item width');
    approx_ok($o[1][0], $w1, 0.5, 'two items: second item x-pos = first item width');
}

# ── column direction: height → basis, width → cross ──────────────────────────

{
    my $fmm   = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);
    my $w_hi  = $fm->string_width('Hi', 12);
    my $lh    = 12 * 1.2;

    my @o = c(
        main_size  => 200,
        cross_size => 100,
        direction  => 'column',
        align      => 'start',
        measure    => $fmm,
        items      => [{ text => 'Hi' }],
    );
    approx_ok($o[0][3], $lh,   0.5, 'column: h = line_height (main-axis basis)');
    approx_ok($o[0][2], $w_hi, 0.5, 'column: w = string_width (cross-axis)');
}

done_testing;
