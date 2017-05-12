#################################################################
#
#   $Id: 11_test_arg.t,v 1.2 2007/05/25 12:52:01 erwan_lemonnier Exp $
#
#   test from()
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

    use_ok('Hook::Filter::Hooker','filter_sub');
    use_ok('Hook::Filter::Rule');
    use_ok('Hook::Filter::RulePool','get_rule_pool');
}

# expect 1 warning

my @warnings = ("invalid Hook::Filter rule .arg.undef..",
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

my ($rule,$pool);
$pool = get_rule_pool;

sub mytest1 { return 1; };
sub mysub1  { return mytest1(@_); };

filter_sub('main::mytest1');

$pool->add_rule('arg(undef)/');
is(mysub1(), 1,  "main::mysub1 called when rule fails");

$pool->flush_rules;
$pool->add_rule('arg(0) eq "bob"');
is(mysub1('bib'), undef,  "main::mysub1 skipped when 1st arg does not match");
is(mysub1('bob'), 1,  "main::mysub1 called when 1st arg does match");

$pool->flush_rules;
$pool->add_rule('defined arg(3) && arg(3) eq "bob"');
is(mysub1(), undef,  "main::mysub1 skipped when 3rd arg does not match");
is(mysub1(0,0,0,'bob'), 1,  "main::mysub1 called when 3rd arg does match");



