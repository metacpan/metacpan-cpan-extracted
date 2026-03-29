use strict;
use warnings;
use Test::More;

use_ok('Litavis');

# Helper
sub compile_css {
    my ($css, %opts) = @_;
    my $d = Litavis->new(%opts);
    $d->parse($css);
    return $d->compile();
}

# ═══════════════════════════════════════════════════════════════
# Regression: Crayon dedup bug — hash modification during iteration
#
# Crayon's _dedupe_struct modified the hash it was iterating over,
# causing some identical selectors to NOT be merged, and others
# to be incorrectly merged when cascade position mattered.
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('.z { color: red; } .a { color: red; } .m { color: red; }');
    # All three have identical props and no intervening conflicts → merge
    like($css, qr/\.z/, 'hash iter bug: .z present');
    like($css, qr/\.a/, 'hash iter bug: .a present');
    like($css, qr/\.m/, 'hash iter bug: .m present');
    # Should be merged into one rule
    my @rules = ($css =~ /\{/g);
    is(scalar @rules, 1, 'hash iter bug: all three merged into one rule');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Crayon unordered hash — sort keys alphabetises
#
# Crayon uses `sort keys` which alphabetises selectors, destroying
# source order. Litavis must preserve insertion order.
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        .zebra { padding: 1px; }
        .apple { padding: 2px; }
        .mango { padding: 3px; }
    ', dedupe => 0);
    # Must be in insertion order, NOT alphabetical
    my ($z_pos) = ($css =~ /\.zebra/g) ? ($-[0]) : (-1);
    my ($a_pos) = ($css =~ /\.apple/g) ? ($-[0]) : (-1);
    my ($m_pos) = ($css =~ /\.mango/g) ? ($-[0]) : (-1);
    ok($z_pos < $a_pos, 'order regression: .zebra before .apple');
    ok($a_pos < $m_pos, 'order regression: .apple before .mango');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Cascade reordering — merging loses cascade position
#
# .reset { color: black; }
# .theme { color: red; }
# .override { color: black; }
#
# Merging .reset and .override would place .override before .theme,
# changing the cascade result for any element with both classes.
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        .reset    { color: black; }
        .theme    { color: red; }
        .override { color: black; }
    ');
    # .override must come AFTER .theme in the output
    my ($theme_pos) = ($css =~ /\.theme/g) ? ($-[0]) : (-1);
    my ($override_pos) = ($css =~ /\.override/g) ? ($-[0]) : (-1);
    ok($override_pos > $theme_pos,
        'cascade regression: .override stays after .theme');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Load order preserved across multiple parse calls
# ═══════════════════════════════════════════════════════════════

{
    my $d = Litavis->new(dedupe => 0);
    $d->parse('.first { color: red; }');
    $d->parse('.second { color: blue; }');
    $d->parse('.third { color: green; }');
    my $css = $d->compile();
    like($css, qr/\.first.*\.second.*\.third/s,
        'load order regression: multiple parse calls preserve order');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Large file (200+ selectors) does not corrupt order
# ═══════════════════════════════════════════════════════════════

{
    my $d = Litavis->new(dedupe => 0);
    my @expected_order;
    for my $i (1..200) {
        $d->parse(".sel-$i { order: $i; }");
        push @expected_order, $i;
    }
    my $css = $d->compile();

    # Extract selector numbers in order from output
    my @found_order;
    while ($css =~ /\.sel-(\d+)/g) {
        push @found_order, $1;
    }
    is_deeply(\@found_order, \@expected_order,
        'large file regression: 200 selectors in correct order');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Same-selector merge must preserve later values
#
# If .btn appears twice with different color values, the later
# one must win (cascade rules).
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        .btn { color: red; padding: 8px; }
        .btn { color: blue; margin: 4px; }
    ');
    like($css, qr/color:blue/, 'same-sel regression: later color wins');
    like($css, qr/padding:8px/, 'same-sel regression: first-only prop kept');
    like($css, qr/margin:4px/, 'same-sel regression: second-only prop added');
    unlike($css, qr/color:red/, 'same-sel regression: earlier color overwritten');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Variable resolution across parse calls
#
# Variables defined in one parse call must be visible in later
# parse calls (global scope accumulates).
# ═══════════════════════════════════════════════════════════════

{
    my $d = Litavis->new;
    $d->parse('$color: red;');
    $d->parse('.a { color: $color; }');
    my $css = $d->compile();
    like($css, qr/\.a\{color:red;\}/, 'var cross-parse regression: resolved across calls');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Mixin expansion with literal values
#
# Mixin values should expand correctly when they contain
# literal (non-variable) values.
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        %box: (
            padding: 8px;
            margin: 0;
        );
        .card { %box; color: red; }
        .panel { %box; color: blue; }
    ');
    like($css, qr/\.card.*padding:8px/s, 'mixin regression: card gets padding');
    like($css, qr/\.panel.*padding:8px/s, 'mixin regression: panel gets padding');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Comments between properties don't break parsing
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        .a {
            color: red;    /* primary */
            background: blue;  /* secondary */
            /* border: none; -- disabled */
            font-size: 14px;
        }
    ');
    like($css, qr/color:red/, 'comment regression: color before comment');
    like($css, qr/background:blue/, 'comment regression: background before comment');
    like($css, qr/font-size:14px/, 'comment regression: font-size after comment');
    unlike($css, qr/border/, 'comment regression: commented-out prop removed');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Empty rules between non-empty rules
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        .a { color: red; }
        .empty { }
        .b { color: blue; }
    ', dedupe => 0);
    unlike($css, qr/empty/, 'empty rule regression: empty stripped');
    like($css, qr/\.a\{color:red;\}/, 'empty rule regression: .a present');
    like($css, qr/\.b\{color:blue;\}/, 'empty rule regression: .b present');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Nested rules produce flat output (no nesting in output)
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        .parent {
            color: red;
            .child {
                color: blue;
                .grandchild {
                    color: green;
                }
            }
        }
    ');
    # Output must be flat — no nested braces
    # Count opening braces — should match closing braces and be one per rule
    my @opens = ($css =~ /\{/g);
    my @closes = ($css =~ /\}/g);
    is(scalar @opens, scalar @closes, 'flat output regression: balanced braces');
    like($css, qr/\.parent\{/, 'flat output regression: .parent');
    like($css, qr/\.parent \.child\{/, 'flat output regression: .parent .child');
    like($css, qr/\.parent \.child \.grandchild\{/, 'flat output regression: .parent .child .grandchild');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Forward reference (variable hoisting)
# ═══════════════════════════════════════════════════════════════

{
    my $css = compile_css('
        .a { color: $color; }
        $color: red;
    ');
    like($css, qr/\.a\{color:red;\}/, 'hoisting regression: forward ref resolved');
}

# ═══════════════════════════════════════════════════════════════
# Regression: Multiple compile() calls don't corrupt state
# ═══════════════════════════════════════════════════════════════

{
    my $d = Litavis->new;
    $d->parse('$x: red; .a { color: $x; }');

    my @results;
    for my $i (1..5) {
        push @results, $d->compile();
    }

    for my $i (1..4) {
        is($results[$i], $results[0],
            "multi-compile regression: call " . ($i+1) . " matches first");
    }
}

done_testing;
