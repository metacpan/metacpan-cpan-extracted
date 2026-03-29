use strict;
use warnings;
use Test::More;

use_ok('Litavis');

my $d = Litavis->new;
isa_ok($d, 'Litavis');

# ── Insertion order ──────────────────────────────────────────

$d->_ast_add_rule('.alpha');
$d->_ast_add_rule('.beta');
$d->_ast_add_rule('.gamma');

is($d->_ast_rule_count, 3, 'three rules added');
is($d->_ast_rule_selector(0), '.alpha', 'first rule is .alpha');
is($d->_ast_rule_selector(1), '.beta',  'second rule is .beta');
is($d->_ast_rule_selector(2), '.gamma', 'third rule is .gamma');

# ── Lookup ───────────────────────────────────────────────────

ok($d->_ast_has_rule('.alpha'),  'has .alpha');
ok($d->_ast_has_rule('.beta'),   'has .beta');
ok(!$d->_ast_has_rule('.delta'), 'does not have .delta');

# ── Duplicate add returns existing ───────────────────────────

$d->_ast_add_rule('.alpha');
is($d->_ast_rule_count, 3, 'duplicate add does not increase count');

# ── Properties ───────────────────────────────────────────────

$d->_ast_add_prop('.alpha', 'color', 'red');
$d->_ast_add_prop('.alpha', 'font-size', '16px');

is($d->_ast_get_prop('.alpha', 'color'), 'red', 'get prop color');
is($d->_ast_get_prop('.alpha', 'font-size'), '16px', 'get prop font-size');
ok($d->_ast_has_prop('.alpha', 'color'), 'has prop color');
ok(!$d->_ast_has_prop('.alpha', 'margin'), 'does not have prop margin');
is($d->_ast_prop_count('.alpha'), 2, 'alpha has 2 props');

# ── Property update (same key overwrites value) ─────────────

$d->_ast_add_prop('.alpha', 'color', 'blue');
is($d->_ast_get_prop('.alpha', 'color'), 'blue', 'prop overwritten to blue');
is($d->_ast_prop_count('.alpha'), 2, 'prop count unchanged after overwrite');

# ── Props equal ──────────────────────────────────────────────

$d->_ast_add_prop('.beta', 'color', 'blue');
$d->_ast_add_prop('.beta', 'font-size', '16px');
ok($d->_ast_rules_props_equal('.alpha', '.beta'), 'alpha and beta have equal props');

$d->_ast_add_prop('.gamma', 'color', 'green');
ok(!$d->_ast_rules_props_equal('.alpha', '.gamma'), 'alpha and gamma have different props');

# ── Merge props ──────────────────────────────────────────────

$d->_ast_add_rule('.merge-dst');
$d->_ast_add_prop('.merge-dst', 'color', 'red');
$d->_ast_add_prop('.merge-dst', 'margin', '10px');

$d->_ast_add_rule('.merge-src');
$d->_ast_add_prop('.merge-src', 'color', 'blue');
$d->_ast_add_prop('.merge-src', 'padding', '5px');

$d->_ast_merge_props('.merge-dst', '.merge-src');
is($d->_ast_get_prop('.merge-dst', 'color'), 'blue', 'merge: src wins on conflict');
is($d->_ast_get_prop('.merge-dst', 'margin'), '10px', 'merge: dst keeps own');
is($d->_ast_get_prop('.merge-dst', 'padding'), '5px', 'merge: new prop added from src');
is($d->_ast_prop_count('.merge-dst'), 3, 'merge: prop count is 3');

# ── Remove rule ──────────────────────────────────────────────

my $count_before = $d->_ast_rule_count;
$d->_ast_remove_rule(1);  # remove .beta
is($d->_ast_rule_count, $count_before - 1, 'rule count decreased');
ok(!$d->_ast_has_rule('.beta'), '.beta removed');
ok($d->_ast_has_rule('.alpha'), '.alpha still present');
ok($d->_ast_has_rule('.gamma'), '.gamma still present');

# Verify order preserved after removal
is($d->_ast_rule_selector(0), '.alpha', 'after remove: first is .alpha');
is($d->_ast_rule_selector(1), '.gamma', 'after remove: second is .gamma');

# ── Rename rule ──────────────────────────────────────────────

$d->_ast_rename_rule(0, '.renamed');
is($d->_ast_rule_selector(0), '.renamed', 'rule renamed');
ok($d->_ast_has_rule('.renamed'), 'can look up renamed rule');
ok(!$d->_ast_has_rule('.alpha'), 'old name no longer found');
# Properties preserved after rename
is($d->_ast_get_prop('.renamed', 'color'), 'blue', 'props preserved after rename');

# ── Reset clears everything ──────────────────────────────────

$d->reset;
is($d->_ast_rule_count, 0, 'reset clears all rules');

# ── Constructor options ──────────────────────────────────────

my $d2 = Litavis->new(pretty => 1, dedupe => 2);
is($d2->pretty, 1, 'pretty set via constructor');
is($d2->dedupe, 2, 'dedupe set via constructor');

# ── Accessor set/get ─────────────────────────────────────────

$d2->pretty(0);
is($d2->pretty, 0, 'pretty toggled off');
$d2->dedupe(0);
is($d2->dedupe, 0, 'dedupe toggled off');

# ── Large number of rules (test rehashing) ───────────────────

my $d3 = Litavis->new;
for my $i (1..200) {
    $d3->_ast_add_rule(".rule-$i");
}
is($d3->_ast_rule_count, 200, '200 rules added');

# Verify insertion order is preserved
is($d3->_ast_rule_selector(0), '.rule-1', 'first rule correct after rehash');
is($d3->_ast_rule_selector(99), '.rule-100', '100th rule correct after rehash');
is($d3->_ast_rule_selector(199), '.rule-200', 'last rule correct after rehash');

# Verify lookup still works after rehashes
ok($d3->_ast_has_rule('.rule-1'), 'lookup works for first rule');
ok($d3->_ast_has_rule('.rule-100'), 'lookup works for middle rule');
ok($d3->_ast_has_rule('.rule-200'), 'lookup works for last rule');
ok(!$d3->_ast_has_rule('.rule-201'), 'lookup correctly returns false');

done_testing;
