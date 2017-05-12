#################################################################
#
#   $Id: 08_test_injecting_rules.t,v 1.2 2007/05/24 14:52:37 erwan_lemonnier Exp $
#
#   test injecting rules during runtime
#

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 10;
use lib "../lib/";
use Hook::Filter hook => ['mylog1','mylog2','mylog3'];
use Hook::Filter::RulePool qw(get_rule_pool);

sub mylog1 { return 1; }
sub mylog2 { return 1; }
sub mylog3 { return 1; }

sub call_log1 { mylog1; }
sub call_log2 { mylog2; }
sub call_log3 { mylog3; }

# there should be no rules in the pool
my $pool = get_rule_pool;
is(scalar $pool->get_rules, 0, "pool is empty to start with (no rule file)");

# calls are not filtered by default
is(call_log1, 1, "main::mylog1 ok");
is(call_log2, 1, "main::mylog2 ok");
is(call_log3, 1, "main::mylog3 ok");

# now inject a rule
$pool->add_rule('from !~ /2/');

is(call_log1, 1,     "added rule. main::mylog1 ok");
is(call_log2, undef, "added rule. main::mylog2 skipped");
is(call_log3, 1,     "added rule. main::mylog3 ok");

# and an other
$pool->add_rule("from eq 'main::call_log3'");

is(call_log1, 1,     "added 2nd rule. main::mylog1 ok");
is(call_log2, undef, "added 2nd rule. main::mylog2 skipped");
is(call_log3, 1,     "added 2nd rule. main::mylog3 skipped");

