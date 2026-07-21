#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── measure => 'simple': 0.6em wide per char, 1.4em tall ─────────

{
    # "Hello" = 5 chars, font_size=10 → w=30, h=14
    my @o = c(
        main_size  => 200,
        cross_size => 100,
        measure    => 'simple',
        items      => [
            { text => 'Hello',  font_size => 10 },
            { text => 'World!', font_size => 10 },
        ],
    );
    # "Hello" = 5 chars × 10 × 0.6 = 30; "World!" = 6 × 10 × 0.6 = 36
    approx_ok($o[0][2], 30, 0.01, 'simple: item0 w=30');
    approx_ok($o[1][2], 36, 0.01, 'simple: item1 w=36');
    # height from single-line fill (cross_size=100, stretch default)
    approx_ok($o[0][3], 100, 0.01, 'simple: items stretch to cross_size');
}

# ── font_size scales both width and height ────────────────────────

{
    my @o = c(
        main_size  => 400,
        cross_size => 200,
        align      => 'start',
        measure    => 'simple',
        items      => [
            { text => 'Hi', font_size => 10 },
            { text => 'Hi', font_size => 20 },
        ],
    );
    # "Hi" = 2 chars; font10 → w=12, h=14; font20 → w=24, h=28
    approx_ok($o[0][2], 12, 0.01, 'font_size: item0 w=12 at 10pt');
    approx_ok($o[0][3], 14, 0.01, 'font_size: item0 h=14 at 10pt');
    approx_ok($o[1][2], 24, 0.01, 'font_size: item1 w=24 at 20pt');
    approx_ok($o[1][3], 28, 0.01, 'font_size: item1 h=28 at 20pt');
}

# ── explicit basis overrides measured width ───────────────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        measure    => 'simple',
        items      => [
            { text => 'Hello', font_size => 10, basis => 100 },
        ],
    );
    # basis=100 wins over measured 30
    approx_ok($o[0][2], 100, 0.01, 'explicit basis overrides measure');
}

# ── explicit cross overrides measured height ──────────────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 80,
        align      => 'start',
        measure    => 'simple',
        items      => [
            { text => 'Hi', font_size => 10, cross => 40 },
        ],
    );
    # cross=40 wins over measured 14
    approx_ok($o[0][3], 40, 0.01, 'explicit cross overrides measured height');
}

# ── text items can grow into free space ───────────────────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        measure    => 'simple',
        items      => [
            { text => 'AB', font_size => 10, grow => 1 },
            { text => 'CD', font_size => 10, grow => 1 },
        ],
    );
    # each text measures 12; total=24; free=276; grow equally → each 12+138=150
    approx_ok($o[0][2], 150, 0.01, 'text+grow: item0 w=150');
    approx_ok($o[1][2], 150, 0.01, 'text+grow: item1 w=150');
}

# ── column direction: text height → basis, text width → cross ─────

{
    my @o = c(
        main_size  => 200,
        cross_size => 100,
        direction  => 'column',
        align      => 'start',
        measure    => 'simple',
        items      => [
            { text => 'Hello', font_size => 10 },
        ],
    );
    # column: basis=h=14, cross=w=30
    approx_ok($o[0][3], 14, 0.01, 'column text: h=measured height (basis)');
    approx_ok($o[0][2], 30, 0.01, 'column text: w=measured width (cross)');
}

# ── measure code ref: user-supplied measurer ──────────────────────

{
    # measurer that returns fixed 50×20 for any text
    my $measurer = sub {
        my ($item) = @_;
        return (50, 20);
    };

    my @o = c(
        main_size  => 300,
        cross_size => 80,
        align      => 'start',
        measure    => $measurer,
        items      => [
            { text => 'anything' },
            { text => 'also anything' },
        ],
    );
    approx_ok($o[0][2], 50, 0.01, 'code ref measure: item0 w=50');
    approx_ok($o[0][3], 20, 0.01, 'code ref measure: item0 h=20');
    approx_ok($o[1][2], 50, 0.01, 'code ref measure: item1 w=50');
}

# ── code ref receives full item hashref ──────────────────────────

{
    my $last_item;
    my $measurer = sub {
        $last_item = shift;
        return (60, 15);
    };

    c(
        main_size  => 300,
        cross_size => 50,
        measure    => $measurer,
        items      => [{ text => 'probe', font_size => 14, color => 'red' }],
    );

    is($last_item->{text},      'probe', 'code ref: item hashref has text');
    is($last_item->{font_size}, 14,      'code ref: item hashref has font_size');
    is($last_item->{color},     'red',   'code ref: item hashref passes custom keys');
}

# ── mixed: some items have text, others have explicit basis ───────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        measure    => 'simple',
        items      => [
            { basis => 100 },
            { text => 'Hi', font_size => 10 },
        ],
    );
    approx_ok($o[0][2], 100, 0.01, 'mixed: explicit basis item unchanged');
    approx_ok($o[1][2], 12,  0.01, 'mixed: text item measured');
    approx_ok($o[1][0], 100, 0.01, 'mixed: text item placed after explicit item');
}

# ── wrap_text: simple built-in wraps at resolved width ───────────

{
    # item grows to fill 300px; "Hello World" = 11 chars × 10 × 0.6 = 66px
    # resolved w = 300; chars_per_line = floor(300/6) = 50; 11 chars → 1 line
    # h = 1 × 10 × 1.4 = 14
    my @o = c(
        main_size  => 300,
        cross_size => 200,
        align      => 'start',
        measure    => 'simple',
        items      => [
            { text => 'Hello World', font_size => 10, grow => 1, wrap_text => 1 },
        ],
    );
    approx_ok($o[0][2], 300, 0.01, 'wrap_text: item grows to fill main_size');
    approx_ok($o[0][3], 14,  0.01, 'wrap_text: 11 chars fit on 1 line at 300px');
}

{
    # item basis=60; chars_per_line = floor(60 / (10×0.6)) = floor(60/6) = 10
    # "Hello World" = 11 chars → ceil(11/10) = 2 lines; h = 2 × 14 = 28
    my @o = c(
        main_size  => 300,
        cross_size => 200,
        align      => 'start',
        measure    => 'simple',
        items      => [
            { text => 'Hello World', font_size => 10, basis => 60, wrap_text => 1 },
            { basis => 100 },
        ],
    );
    approx_ok($o[0][2], 60, 0.01, 'wrap_text narrow: item stays at basis');
    approx_ok($o[0][3], 28, 0.01, 'wrap_text narrow: 11 chars → 2 lines → h=28');
}

# ── wrap_text: code ref receives resolved width as second arg ─────

{
    my @calls;
    my $measurer = sub {
        my ($item, $avail_w) = @_;
        push @calls, { avail_w => $avail_w };
        if (defined $avail_w) {
            # pretend 10 chars per 100px → compute lines
            my $cpl   = int($avail_w / 10) || 1;
            my $lines = int((length($item->{text}) + $cpl - 1) / $cpl);
            return ($avail_w, $lines * 15);
        }
        return (length($item->{text}) * 10, 15);
    };

    my @o = c(
        main_size  => 200,
        cross_size => 300,
        align      => 'start',
        measure    => $measurer,
        items      => [
            { text => 'Hello World', wrap_text => 1 },
        ],
    );

    # first call: no avail_w (natural sizing); second call: avail_w=resolved_w
    is(scalar @calls, 2, 'code ref wrap: called twice (natural + wrapped)');
    ok(!defined $calls[0]{avail_w}, 'code ref wrap: first call has no avail_w');
    approx_ok($calls[1]{avail_w}, $o[0][2], 0.01, 'code ref wrap: second call passes resolved w');
}

# ── wrap_text => 0: no second pass ───────────────────────────────

{
    my $call_count = 0;
    my $measurer = sub { $call_count++; return (50, 20) };

    c(
        main_size  => 200,
        cross_size => 100,
        measure    => $measurer,
        items      => [{ text => 'x', wrap_text => 0 }],
    );
    is($call_count, 1, 'wrap_text=0: measure called only once');
}

# ── items without wrap_text are not re-measured ───────────────────

{
    my $call_count = 0;
    my $measurer = sub { $call_count++; return (50, 20) };

    c(
        main_size  => 200,
        cross_size => 100,
        measure    => $measurer,
        items      => [
            { text => 'first',  wrap_text => 1 },
            { text => 'second'                  },
        ],
    );
    # first item: 2 calls; second item: 1 call → total 3
    is($call_count, 3, 'only wrap_text items get second measure call');
}

# ── wrap_text with a real sentence ───────────────────────────────

{
    # "The quick brown fox jumps over the lazy dog" = 43 chars
    # font_size=10 → char_w=6; natural w = 43*6 = 258
    # container main_size=200; item grows to fill → resolved_w=200
    # chars_per_line = floor(200/6) = 33; lines = ceil(43/33) = 2
    # h = 2 * 10 * 1.4 = 28
    my @o = c(
        main_size  => 200,
        cross_size => 300,
        align      => 'start',
        measure    => 'simple',
        items      => [
            {
                text      => 'The quick brown fox jumps over the lazy dog',
                font_size => 10,
                grow      => 1,
                wrap_text => 1,
            },
        ],
    );
    approx_ok($o[0][2], 200, 0.01, 'sentence: item grows to fill 200px');
    approx_ok($o[0][3], 28,  0.01, 'sentence: 43 chars at 200px wraps to 2 lines h=28');
}

{
    # same sentence but narrower container so it breaks into more lines
    # main_size=120; char_w=6; chars_per_line=floor(120/6)=20
    # lines=ceil(43/20)=3; h=3*10*1.4=42
    my @o = c(
        main_size  => 120,
        cross_size => 300,
        align      => 'start',
        measure    => 'simple',
        items      => [
            {
                text      => 'The quick brown fox jumps over the lazy dog',
                font_size => 10,
                grow      => 1,
                wrap_text => 1,
            },
        ],
    );
    approx_ok($o[0][2], 120, 0.01, 'sentence narrow: item fills 120px');
    approx_ok($o[0][3], 42,  0.01, 'sentence narrow: 43 chars at 120px wraps to 3 lines h=42');
}

{
    # sentence alongside a fixed-width item; sentence does not grow
    # main_size=300; fixed item basis=100; sentence: natural w=43*6=258
    # no grow on either → sentence stays at 258 but is clamped to remaining 200
    # actually: shrink=1 so both shrink. free = 300-100-258 = -58 (overflow)
    # shrink factors: fixed shrink=1*100=100, sentence shrink=1*258=258; total=358
    # sentence shrinks: 258 - 58*(258/358) = 258 - 41.8 ≈ 216.2
    # wrap: resolved_w≈216; chars_per_line=floor(216/6)=36; lines=ceil(43/36)=2; h=28
    my @o = c(
        main_size  => 300,
        cross_size => 200,
        align      => 'start',
        measure    => 'simple',
        items      => [
            { basis => 100 },
            {
                text      => 'The quick brown fox jumps over the lazy dog',
                font_size => 10,
                wrap_text => 1,
            },
        ],
    );
    approx_ok($o[1][3], 28, 0.01, 'sentence shrink: 43 chars at ~216px wraps to 2 lines h=28');
}

{
    # code-ref measurer with a real sentence: measure splits on spaces
    my $line_measurer = sub {
        my ($item, $avail_w) = @_;
        my @words = split /\s+/, $item->{text};
        my $fs    = $item->{font_size} || 12;
        my $cw    = $fs * 0.6;
        my $lh    = $fs * 1.4;

        unless (defined $avail_w) {
            # first pass: natural single-line width
            my $total = 0;
            $total += (length($_) + 1) * $cw for @words;
            return ($total, $lh);
        }

        # second pass: word-wrap to avail_w
        my $lines = 1;
        my $used  = 0;
        for my $word (@words) {
            my $ww = (length($word) + 1) * $cw;
            if ($used + $ww > $avail_w && $used > 0) {
                $lines++;
                $used = $ww;
            } else {
                $used += $ww;
            }
        }
        return ($avail_w, $lines * $lh);
    };

    my @o = c(
        main_size  => 200,
        cross_size => 400,
        align      => 'start',
        measure    => $line_measurer,
        items      => [
            {
                text      => 'The quick brown fox jumps over the lazy dog',
                font_size => 10,
                grow      => 1,
                wrap_text => 1,
            },
        ],
    );
    approx_ok($o[0][2], 200, 0.01, 'word-wrap cb: item fills 200px');
    # verify height > single line (14px) — it wrapped
    ok($o[0][3] > 14, 'word-wrap cb: sentence wrapped → height > single line');
}

done_testing;
