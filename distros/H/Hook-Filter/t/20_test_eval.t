#################################################################
#
#   $Id: 20_test_eval.t,v 1.1 2007/05/25 12:39:27 erwan_lemonnier Exp $
#
#   test that Hook::Filter works well even when used in an eval/require
#

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib "../lib/";

my $called = 0;

sub foo { $called = 1 }

BEGIN {
    eval "use Module::Pluggable"; plan skip_all => "Module::Pluggable required for testing Hook::Filter" if $@;

    plan tests => 6;
};

$called = 0;
foo();
is($called,1,"foo not filtered when Hook::Filter not loaded");

#
# eval 'Hook::Filter' should yield a warning
#

$SIG{__WARN__} = sub {
   my $msg = shift;
   ok("$msg" =~ /Too late to run INIT block at .*Hook.Filter/i, "caught warning 'Too late to run INIT block'");
};

eval "use Hook::Filter hook => 'foo'";
ok($@ eq "", "used Hook::Filter");

$SIG{__WARN__} = 'DEFAULT';

my $pool = Hook::Filter::RulePool::get_rule_pool();
is(scalar $pool->get_rules, 0, "pool is empty");

# adding a block all rule
$pool->add_rule("0");

$called = 0;
foo();
is($called,1,"foo is not blocked since INIT not executed");

# now execute INIT explicitly
Hook::Filter::_filter_subs();

$called = 0;
foo();
is($called,0,"foo is now blocked after running _filter_subs");
