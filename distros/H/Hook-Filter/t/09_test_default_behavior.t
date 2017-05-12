#################################################################
#
#   $Id: 09_test_default_behavior.t,v 1.2 2007/05/25 12:52:00 erwan_lemonnier Exp $
#
#   test that calls are allowed by default
#

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib "../lib/";

BEGIN {
    eval "use Module::Pluggable"; plan skip_all => "Module::Pluggable required for testing Hook::Filter" if $@;
    eval "use File::Spec"; plan skip_all => "File::Spec required for testing Hook::Filter" if $@;
    plan tests => 9;

    use_ok('Hook::Filter','hook','mylog');
    use_ok('Hook::Filter::RulePool','get_rule_pool');
}

# expect 2 warnings

my @warnings = ("invalid Hook::Filter rule .1 -.",
		"invalid Hook::Filter rule .croak 'blob'.",
		);

$SIG{__WARN__} = sub {
    my $msg = shift;
    my $expect = shift @warnings;
    ok($msg =~ /$expect/i, "got warning matching [$expect]");
    return if ($msg =~ /$expect/i);
    CORE::warn($msg);
};

#
# go on with normal tests
#

my $CALLED;

sub mylog { $CALLED = 1 }

# by default, allow calls
$CALLED = 0;
mylog();
is($CALLED,1,"calls are allowed by default");

# if all rules fail, calls are also allowed by default
get_rule_pool->add_rule("1 -"); # doesn't compile

$CALLED = 0;
mylog();
is($CALLED,1,"calls are allowed by default when all rules die");

# same, but croaks
get_rule_pool->flush_rules->add_rule("croak 'blob'");

$CALLED = 0;
mylog();
is($CALLED,1,"calls are allowed by default when all rules die");

# now inject a default rule defaulting to false
get_rule_pool->flush_rules;

$CALLED = 0;
mylog();
is($CALLED,1,"calls when pool empty");

get_rule_pool->add_rule("0");

$CALLED = 0;
mylog();
is($CALLED,0,"blocks when default rule is false");


