#################################################################
#
#   $Id: 07_test_pool.t,v 1.2 2007/05/24 14:52:37 erwan_lemonnier Exp $
#
#   test Hook::Filter::RulePool
#

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib "../lib/";

BEGIN {
    eval "use Module::Pluggable"; plan skip_all => "Module::Pluggable required for testing Hook::Filter" if $@;
    eval "use File::Spec"; plan skip_all => "File::Spec required for testing Hook::Filter" if $@;
    plan tests => 18;

    use_ok('Hook::Filter::Rule');
    use_ok('Hook::Filter::RulePool','get_rule_pool');
}

# new should be forbidden
eval { new Hook::Filter::RulePool };
ok ( $@ =~ /use get_pool.. instead of new../, "new() is forbidden");

# verify singleton
my $pool = get_rule_pool();
ok(ref $pool eq "Hook::Filter::RulePool", "get_rule_pool returns a pool");

my @rules = $pool->get_rules();
is(scalar @rules, 0, "pool is empty by default");
is($pool->eval_rules, 1, "empty pool evals to true");

# add a false rule as a string
$pool->add_rule("2 == 3");
@rules = $pool->get_rules();
is(scalar @rules, 1, "pool has now 1 element");
is($pool->eval_rules, 0, "pool evals to false");

# check that the rule got a proper source()
my $rule = $rules[0];
ok($rule->{SOURCE} =~ /added by main::main, l.\d+/, "checking rule's source");

# add a true rule as an object
$rule = new Hook::Filter::Rule("1 != 2");
$rule->source("boom boom");

$pool->add_rule($rule);
@rules = $pool->get_rules();
is(scalar @rules, 2, "pool has now 2 elements");
is($pool->eval_rules, 1, "pool evals to true");

# flush pool
$pool->flush_rules();
@rules = $pool->get_rules();
is(scalar @rules, 0, "pool was indeed emptied");
is($pool->eval_rules, 1, "pool evals to true");

# add a true rule first, this time
$pool->add_rule("2 != 3");
@rules = $pool->get_rules();
is(scalar @rules, 1, "pool has now 1 element");
is($pool->eval_rules, 1, "pool evals to true");

# test errors
eval { $pool->add_rule() };
ok($@ =~ /invalid parameters:/, "add_rule croaks on no args");

eval { $pool->add_rule(1,2) };
ok($@ =~ /invalid parameters:/, "add_rule croaks on too many args");

eval { $pool->add_rule([]) };
ok($@ =~ /invalid parameters:/, "add_rule croaks on wrong arg type");


