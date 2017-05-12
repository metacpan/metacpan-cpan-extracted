#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..20\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

foreach my $chain (qw/foo REJECT MASQ REDIRECT/) {
	$table->create_chain($chain) || print "# $!\nnot ";
	print "ok ", $testiter++, "\n";
}

my @targets = (qw/DROP REJECT ACCEPT/);
foreach my $target (@targets) {
	$table->append_entry("foo", {jump => $target}) || print "# $!\nnot ";
	print "ok ", $testiter++, "\n";
}

%chains = ();
foreach(qw/INPUT FORWARD OUTPUT MASQ REDIRECT REJECT foo/) {
	$chains{$_} = 1;
}

foreach my $chain ($table->list_chains()) {
	unless (exists $chains{$chain})	{
		print "# $!\nnot ";
	} else {
		delete $chains{$chain};
		unless ($table->builtin($chain)) {
			my $refcnt = $table->get_references($chain);
			if ($chain eq "REJECT") {
				print "# $!\nnot " unless $refcnt == 1;
			} else {
				print "# $!\nnot " unless $refcnt == 0;
			}
		}
	}
	print "ok ", $testiter++, "\n";
}

unless (scalar(keys(%chains)) == 0) {
	print "# $!\nnot ";
}
print "ok ", $testiter++, "\n";

my @rules = $table->list_rules("foo");
if (scalar(@rules) != 3) {
	print "# $!\nnot ";
}
print "ok ", $testiter++, "\n";

foreach my $rule (@rules) {
	my @keylist = keys(%$rule);
	my $target = shift(@targets);
	if(scalar(@keylist) != 3 || $$rule{'jump'} ne $target) {
		print "# $!\nnot ";
	}
	print "ok ", $testiter++, "\n";
}

foreach my $chain ($table->list_chains()) {
	$table->flush_entries($chain);
}

foreach my $chain ($table->list_chains()) {
	unless ($table->builtin($chain)) {
		$table->delete_chain($chain);
	}
}

exit(0);
# vim: ts=4
