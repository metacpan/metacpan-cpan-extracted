#################################################################
#
#   $Id: 03_test_hook_filter_rule.t,v 1.3 2007/05/16 14:09:09 erwan_lemonnier Exp $
#
#   test hook filter rules
#

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib "../lib/";

BEGIN {
    eval "use Module::Pluggable"; plan skip_all => "Module::Pluggable required for testing Hook::Filter" if $@;
    eval "use File::Spec"; plan skip_all => "File::Spec required for testing Hook::Filter" if $@;
    plan tests => 32;

    use_ok('Hook::Filter::Rule');
}

eval { Hook::Filter::Rule->new([1,2])};
ok(($@ =~ /new expects one string/i),"new with array ref");

eval { new Hook::Filter::Rule({a=>1})};
ok(($@ =~ /new expects one string/i),"new with hash ref");

eval { Hook::Filter::Rule->new("1","1 && 1")};
ok(($@ =~ /new expects one string/i),"new with 2 args");

eval { new Hook::Filter::Rule()};
ok(($@ =~ /new expects one string/i),"new with 0 args");

eval { Hook::Filter::Rule->new("1"); };
ok(!$@,"new with correct arg");

my %rules = (
	     # rule, result
	     "1;" => 1,
	     "0;" => 0,
	     "1"  => 1,
	     "1 && 1" => 1,
	     "0 || (1 && 1)" => 1,
	     "print 'tjohoo\n'; 0;" => 0,
	     );

while (my($rule,$result) = each %rules) {
    my $r = Hook::Filter::Rule->new($rule);
    my $res;
    eval { $res = $r->eval(); };
    ok(!$@,"eval [$rule] did not fail");
    is($res,$result,"results matched [$res]");
    is($r->rule,$rule,"rule() returns right");
}

# test warning upon invalid rule
my $r = Hook::Filter::Rule->new("if {;");

eval { $r->source([1,2])};
ok(($@ =~ /source expects one string/i),"source with array ref");

eval { $r->source({a=>1})};
ok(($@ =~ /source expects one string/i),"source with hash ref");

eval { $r->source("1","1 && 1")};
ok(($@ =~ /source expects one string/i),"source with 2 args");

eval { $r->source()};
ok(($@ =~ /source expects one string/i),"source with 0 args");

eval { $r->source("my_file"); };
ok(!$@,"source with correct arg");

# test warning when rule does not compile
my $warn = "";

local $SIG{__WARN__} = sub {
    $warn = shift;
};

my $res = $r->eval();
ok($warn =~ /^WARNING: invalid Hook::Filter rule.*from file.*my_file/i,"test warning received when rule invalid");
is($res,1,"test invalid rule is considered as true");

# now that warning text has optional info about source
$r->{SOURCE} = undef;
$r->eval();
ok($warn =~ /^WARNING: invalid Hook::Filter rule/i
   && $warn !~ /^WARNING: invalid Hook::Filter rule.*from file/i,
   "test warning has no file info when source undefined");
