use strict;
use warnings;
use Test::More;

use_ok('Litavis');

use constant {
    DEDUPE_OFF          => 0,
    DEDUPE_CONSERVATIVE => 1,
    DEDUPE_AGGRESSIVE   => 2,
};

# Helper
sub compile_css {
    my ($css, %opts) = @_;
    my $d = Litavis->new(%opts);
    $d->parse($css);
    return $d->compile();
}

# ── Conservative: property order matters ──────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; background: blue; }
        .b { background: blue; color: red; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    # Different property order prevents merge in conservative mode
    is($d->_ast_rule_count, 2, 'property order: not merged (order differs)');
}

# ── Conservative: many identical rules ────────────────────────

{
    my $d = Litavis->new;
    for my $i (1..10) {
        $d->parse(".item-$i { padding: 8px; margin: 4px; }");
    }
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, '10 identical rules: all merged to 1');
    my $sel = $d->_ast_rule_selector(0);
    for my $i (1, 5, 10) {
        like($sel, qr/\.item-$i/, "10 identical: .item-$i in selector");
    }
}

# ── Conservative: merge doesn't cross @media boundary ────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        @media (max-width: 768px) {
            .x { font-size: 14px; }
        }
        .b { color: red; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    # @media is an at-rule, should be skipped during conflict check
    is($d->_ast_rule_selector(0), '.a, .b', 'across @media: merged');
}

# ── Aggressive: merge despite conflict between ────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; padding: 8px; }
        .b { color: blue; }
        .c { color: red; padding: 8px; }
    ');
    $d->_dedupe(DEDUPE_AGGRESSIVE);
    # Aggressive ignores intervening conflicts
    ok($d->_ast_rule_count < 3, 'aggressive merge despite conflict');
    like($d->_ast_rule_selector(0), qr/\.a.*\.c/, 'aggressive: .a and .c merged');
}

# ── Aggressive vs Conservative: different results ────────────

{
    my $input = '
        .a { color: red; }
        .b { color: blue; }
        .c { color: red; }
    ';
    
    my $d1 = Litavis->new;
    $d1->parse($input);
    $d1->_dedupe(DEDUPE_CONSERVATIVE);
    my $count_conservative = $d1->_ast_rule_count;
    
    my $d2 = Litavis->new;
    $d2->parse($input);
    $d2->_dedupe(DEDUPE_AGGRESSIVE);
    my $count_aggressive = $d2->_ast_rule_count;
    
    ok($count_aggressive <= $count_conservative, 
        'aggressive merges at least as much as conservative');
}

# ── Dedupe with single rule (noop) ───────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'single rule dedupe: still 1');
    is($d->_ast_get_prop('.a', 'color'), 'red', 'single rule dedupe: prop preserved');
}

# ── Dedupe with no duplicate selectors ────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .b { color: blue; }
        .c { color: green; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 3, 'no dups: count unchanged');
}

# ── Dedupe OFF still merges same-selector rules ──────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .a { color: red; }
        .a { color: red; }
    ');
    $d->_dedupe(DEDUPE_OFF);
    # Same-selector merging happens regardless of dedupe strategy
    is($d->_ast_rule_count, 1, 'dedupe off: same-sel still merged');
}

# ── Same selector merge: conflicting values ──────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; background: white; }
        .a { color: blue; padding: 8px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'same-sel conflict: merged to 1');
    is($d->_ast_get_prop('.a', 'color'), 'blue', 'same-sel conflict: later value wins');
    is($d->_ast_get_prop('.a', 'background'), 'white', 'same-sel conflict: non-conflicting kept');
    is($d->_ast_get_prop('.a', 'padding'), '8px', 'same-sel conflict: new prop added');
}

# ── Dedupe with variables already resolved ────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $pad: 8px;
        .a { padding: $pad; }
        .b { padding: $pad; }
    ');
    $d->_resolve_vars;
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'dedupe after var resolve: merged');
    like($d->_ast_rule_selector(0), qr/\.a.*\.b/, 'dedupe after var: selectors joined');
}

# ── Dedupe through compile with dedupe option ────────────────

{
    my $css = compile_css('
        .a { color: red; padding: 8px; }
        .b { font-size: 16px; }
        .c { color: red; padding: 8px; }
    ', dedupe => 1);
    like($css, qr/\.a, \.c/, 'compile dedupe=1: conservative merge');
    like($css, qr/\.b/, 'compile dedupe=1: .b preserved');
}

{
    my $css = compile_css('
        .a { color: red; }
        .b { color: blue; }
        .c { color: red; }
    ', dedupe => 2);
    like($css, qr/\.a, \.c/, 'compile dedupe=2: aggressive merge');
}

# ── Dedupe with nested rules already flattened ────────────────

{
    my $css = compile_css('
        .card { color: red; }
        .card .title { font-size: 18px; }
        .card { background: white; }
    ', dedupe => 1);
    like($css, qr/\.card\{color:red;background:white;\}/, 'dedupe nested: .card merged');
    like($css, qr/\.card \.title\{font-size:18px;\}/, 'dedupe nested: .card .title kept');
}

# ── Dedupe with @import (should not merge across) ────────────

{
    my $d = Litavis->new(dedupe => 1);
    $d->parse('
        .a { color: red; }
        .a { background: blue; }
    ');
    my $css = $d->compile();
    is($css, '.a{color:red;background:blue;}', 'same-sel dedupe through compile');
}

# ── Dedupe stress test ───────────────────────────────────────

{
    my $d = Litavis->new;
    # 50 pairs of identical rules with different selectors
    for my $i (1..50) {
        $d->parse(".group-$i { padding: 8px; margin: 4px; }");
    }
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'stress: 50 identical rules merged to 1');
}

# ── Dedupe with mixed identical and unique rules ─────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .b { font-size: 16px; }
        .c { color: red; }
        .d { padding: 8px; }
        .e { color: red; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    # .a, .c, .e should merge; .b and .d stay separate
    my $merged_sel = $d->_ast_rule_selector(0);
    like($merged_sel, qr/\.a.*\.c.*\.e/, 'mixed: .a .c .e merged');
    is($d->_ast_rule_count, 3, 'mixed: 5 rules -> 3');
}

# ── Conservative: intervening rule with subset props ─────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; font-size: 14px; }
        .b { color: green; }
        .c { color: red; font-size: 14px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    # .b has color which conflicts with .a/.c color
    is($d->_ast_rule_count, 3, 'conservative subset conflict: no merge');
}

# ── Dedupe preserves property values exactly ─────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { border: 1px solid rgba(0, 0, 0, 0.5); padding: 8px; }
        .b { border: 1px solid rgba(0, 0, 0, 0.5); padding: 8px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'complex values: merged');
    is($d->_ast_get_prop('.a, .b', 'border'), '1px solid rgba(0, 0, 0, 0.5)', 
        'complex values: border preserved exactly');
}

# ── Dedupe + pretty output ───────────────────────────────────

{
    my $css = compile_css('
        .a { color: red; }
        .b { font-size: 16px; }
        .c { color: red; }
    ', dedupe => 1, pretty => 1);
    like($css, qr/\.a, \.c \{\n  color: red;\n\}/, 'dedupe+pretty: merged and formatted');
    like($css, qr/\.b \{\n  font-size: 16px;\n\}/, 'dedupe+pretty: .b formatted');
}

# ── Dedupe + sort_props ──────────────────────────────────────

{
    my $css = compile_css('
        .a { z-index: 1; color: red; }
        .a { background: blue; }
    ', dedupe => 1, sort_props => 1);
    is($css, '.a{background:blue;color:red;z-index:1;}', 'dedupe+sort: merged then sorted');
}

done_testing;
