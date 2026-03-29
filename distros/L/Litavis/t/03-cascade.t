use strict;
use warnings;
use Test::More;

use_ok('Litavis');

# Strategy constants
use constant {
    DEDUPE_OFF          => 0,
    DEDUPE_CONSERVATIVE => 1,
    DEDUPE_AGGRESSIVE   => 2,
};

# ── Same-selector merging ────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    $d->parse('.a { background: blue; }');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'same-sel merge: collapsed to one rule');
    is($d->_ast_get_prop('.a', 'color'), 'red', 'same-sel merge: keeps first prop');
    is($d->_ast_get_prop('.a', 'background'), 'blue', 'same-sel merge: adds second prop');
}

# ── Same-selector: later value wins on conflict ──────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    $d->parse('.a { color: blue; }');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'same-sel conflict: one rule');
    is($d->_ast_get_prop('.a', 'color'), 'blue', 'same-sel conflict: later value wins');
}

# ── Conservative: merge identical props, no conflict ─────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; padding: 8px; }
        .b { font-size: 16px; }
        .c { color: red; padding: 8px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 2, 'conservative safe merge: 3 → 2');
    is($d->_ast_rule_selector(0), '.a, .c', 'conservative safe merge: selectors joined');
    is($d->_ast_rule_selector(1), '.b', 'conservative safe merge: .b kept');
}

# ── Conservative: DO NOT merge when intervening conflict ─────

{
    my $d = Litavis->new;
    $d->parse('
        .reset { color: black; padding: 8px; }
        .theme { color: red; }
        .override { color: black; padding: 8px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 3, 'conservative cascade: no merge (intervening color conflict)');
    is($d->_ast_rule_selector(0), '.reset', 'conservative cascade: .reset stays at 0');
    is($d->_ast_rule_selector(1), '.theme', 'conservative cascade: .theme stays at 1');
    is($d->_ast_rule_selector(2), '.override', 'conservative cascade: .override stays at 2');
}

# ── Conservative: partial conflict blocks merge ──────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; margin: 10px; }
        .b { margin: 20px; }
        .c { color: red; margin: 10px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 3, 'conservative partial conflict: no merge (margin conflict)');
}

# ── Conservative: no conflict with unrelated props ───────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .b { font-size: 16px; }
        .c { color: red; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 2, 'conservative no conflict: merged');
    is($d->_ast_rule_selector(0), '.a, .c', 'conservative no conflict: selectors joined');
}

# ── Aggressive: merge despite intervening conflict ───────────

{
    my $d = Litavis->new;
    $d->parse('
        .reset { color: black; }
        .theme { color: red; }
        .override { color: black; }
    ');
    $d->_dedupe(DEDUPE_AGGRESSIVE);
    is($d->_ast_rule_count, 2, 'aggressive: merged despite conflict');
    is($d->_ast_rule_selector(0), '.reset, .override', 'aggressive: selectors joined');
    is($d->_ast_rule_selector(1), '.theme', 'aggressive: .theme kept');
}

# ── Dedupe OFF: no changes ───────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .b { color: red; }
    ');
    $d->_dedupe(DEDUPE_OFF);
    is($d->_ast_rule_count, 2, 'dedupe off: no merge');
}

# ── @-rules are skipped (never merged across) ────────────────

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
    # .a and .b have identical props, @media is between them but is an at-rule
    # so it's skipped during conflict checking — .a and .b should merge
    is($d->_ast_rule_selector(0), '.a, .b', 'at-rule skip: .a and .b merged across @media');
}

# ── Multiple same-selector merges ────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .a { background: blue; }
        .a { font-size: 16px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'triple same-sel: all merged');
    is($d->_ast_get_prop('.a', 'color'), 'red', 'triple same-sel: color');
    is($d->_ast_get_prop('.a', 'background'), 'blue', 'triple same-sel: background');
    is($d->_ast_get_prop('.a', 'font-size'), '16px', 'triple same-sel: font-size');
}

# ── Conservative: chain of merges ────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { padding: 8px; }
        .b { padding: 8px; }
        .c { padding: 8px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'chain merge: all three merged');
    like($d->_ast_rule_selector(0), qr/\.a.*\.b.*\.c/, 'chain merge: all selectors present');
}

# ── Conservative: different prop counts blocks merge ─────────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .b { color: red; font-size: 16px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 2, 'diff prop count: no merge');
}

# ── Conservative: same keys different values blocks merge ────

{
    my $d = Litavis->new;
    $d->parse('
        .a { color: red; }
        .b { color: blue; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 2, 'diff values: no merge');
}

# ── Empty rules merge ────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->_ast_add_rule('.a');
    $d->_ast_add_rule('.b');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 1, 'empty rules: merged (both have 0 props)');
}

# ── Dedupe preserves rule order when no merge ────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .first  { color: red; }
        .second { color: blue; }
        .third  { color: green; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    is($d->_ast_rule_count, 3, 'order preserved: all different');
    is($d->_ast_rule_selector(0), '.first',  'order preserved: 0');
    is($d->_ast_rule_selector(1), '.second', 'order preserved: 1');
    is($d->_ast_rule_selector(2), '.third',  'order preserved: 2');
}

# ── The cascade problem from the plan ────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .btn     { background: grey; color: white; padding: 8px; }
        .primary { background: blue; color: white; padding: 8px; }
        .btn     { background: grey; color: white; padding: 8px; }
    ');
    $d->_dedupe(DEDUPE_CONSERVATIVE);
    # Same-selector merge collapses the two .btn into one
    # But .btn and .primary share properties, so conservative dedup
    # should NOT merge them
    is($d->_ast_rule_count, 2, 'cascade problem: .btn merged with itself');
    is($d->_ast_rule_selector(0), '.btn', 'cascade problem: .btn first');
    is($d->_ast_rule_selector(1), '.primary', 'cascade problem: .primary second');
}

done_testing;
