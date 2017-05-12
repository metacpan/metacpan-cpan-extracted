#!/usr/bin/perl

use strict;

use Decision::ACL;
use Decision::ACL::Rule;
use Decision::ACL::Constants qw(:rule);

use Data::Dumper;

print "1..7\n";

open(RULES, "t/rule_file") || &failed("Cant open rule_file: $!\n");

my $ACL = new Decision::ACL();
&failed("Something is wrong, contact the author.\n") if not defined $ACL;
print "ok 1\n";

my @rules = <RULES>;

foreach (reverse @rules)
{
	next if substr($_,0,1) eq '#' || !$_;

	chomp $_;

	my ($rule_base, $rule_spec) = split(/to/i, $_);

	my ($action, $target);
	my $nowflag = 0;

	if($rule_base =~ /now/i)
	{
		($action, $target) = split(/now/i, $rule_base);
		$nowflag++;
	}
	else
	{
		($action, $target) = split(/ /i, $rule_base);
	}

	
	my ($repository, $spec_base) = split(/on/i, $rule_spec);



	my ($branch, $module) = split(/in/i, $spec_base);

	$module = '' if not defined $module;

	$action = uc $action;
	$action =~ s/ //g;
	$repository =~ s/ //g;
	$module =~ s/ //g if defined $module;
	$target =~ s/ //g;
	$branch =~ s/ //g;
	$repository = uc $repository if $repository =~ /^all$/i;
	$module = uc $module if $module =~ /^all$/i;
	$target = uc $target if $target =~ /^all$/i;
	$branch = uc $branch if $branch =~ /^all$/i;

	my $rule = new Decision::ACL::Rule({
					now => $nowflag, 
					action => $action,
					fields =>
					{
						repository => $repository,	
						branch => $branch, 
						component => $module,
						uid => $target,
					}
				});
	$ACL->PushRule($rule);	
}

my $rules = $ACL->Rules();
if(@$rules)  { print "ok 2\n"; }
else { print "not ok 2\n"; }

#3
my $return_status = $ACL->RunACL({
		branch => 'testbranch', 
		repository => 'testrep',
		component => 'NO/Way.pm',
		uid => '20',
	});
print "not ok 3\n" if $return_status == ACL_RULE_ALLOW;
print "ok 3\n" if $return_status == ACL_RULE_DENY;

#4
$return_status = $ACL->RunACL({
		branch => 'testbranch', 
		repository => 'testrep',
		component => 'YES/Way.pm',
		uid => '20',
	});
print "ok 4\n" if $return_status == ACL_RULE_ALLOW;
print "not ok 4\n" if $return_status == ACL_RULE_DENY;

#5
$return_status = $ACL->RunACL({
		branch => 'testbranch', 
		repository => 'testrep',
		component => 'YES/Way.pm',
		uid => '21',
	});
print "ok 5\n" if $return_status == ACL_RULE_ALLOW;
print "not ok 5\n" if $return_status == ACL_RULE_DENY;

#6
$return_status = $ACL->RunACL({
		branch => 'testbranch', 
		repository => 'testrep',
		component => 'NO/Way.pm',
		uid => '21',
	});
print "ok 6\n" if $return_status == ACL_RULE_DENY;
print "not ok 6\n" if $return_status == ACL_RULE_ALLOW;

#7
$return_status = $ACL->RunACL({
		branch => 'hell', 
		repository => 'letmein',
		component => 'DEVIL/Inside.pm',
		uid => '666',
	});
print "ok 7\n" if $return_status == ACL_RULE_DENY;
print "not ok 7\n" if $return_status == ACL_RULE_ALLOW;


sub failed
{
	my $message = shift;
	print STDERR $message;
	print "not ok 1\n";
}
