#################################################################
#
#   $Id: 13_test_from.t,v 1.3 2007/05/16 15:07:44 erwan_lemonnier Exp $
#
#   test from()
#

package MyTest1;

sub mytest1 { return 1; };
sub mysub1 { return mytest1(); };

1;

package main;

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib "../lib/";

BEGIN {
    eval "use Module::Pluggable"; plan skip_all => "Module::Pluggable required for testing Hook::Filter" if $@;
    eval "use File::Spec"; plan skip_all => "File::Spec required for testing Hook::Filter" if $@;
    plan tests => 8;

    use_ok('Hook::Filter::Hooker','filter_sub');
    use_ok('Hook::Filter::Rule');
    use_ok('Hook::Filter::RulePool','get_rule_pool');
}

my ($rule,$pool);
$pool = get_rule_pool;

sub mytest1 { return 1; };
sub mysub1  { return mytest1(); };

filter_sub('main::mytest1');
filter_sub('MyTest1::mytest1');

$pool->add_rule('from =~ /^MyTest1::mysub1$/');
is(mysub1,undef,                 "main::mysub1 does not match");
is(MyTest1::mysub1,1,            "MyTest1::mysub1 does match");

$pool->flush_rules;
$pool->add_rule('from =~ /^main::mysub1$/');
is(mysub1,1,                     "main::mysub1 does match");
is(MyTest1::mysub1,undef,        "MyTest1::mysub1 does not match");

# a direct call returns ''
$pool->flush_rules;
$pool->add_rule('from =~ /^$/');
is(mytest1,1,                    "direct call => from = ''");


