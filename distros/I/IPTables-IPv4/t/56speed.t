#!/usr/bin/perl

use IPTables::IPv4;
use Time::HiRes qw(gettimeofday);

BEGIN { $| = 1; print "1..7\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

my ($num_rules, $num_chains) = (5000, 1000);

# if libiptc was built with debugging features, this will disable some sanity
# checking
$ENV{'IPTC_NO_CHECK'} = 1;

($start, $start_usec) = gettimeofday();

for (my $i = 0; $i < $num_rules; $i++) {
	$table->append_entry("INPUT", {});
}

($end, $end_usec) = gettimeofday();
$start += $start_usec / 1000000.0;
$end += $end_usec / 1000000.0;

printf("# average rule insert time was \%.5f seconds\n", ($end - $start) / $num_rules);
printf("# finished insert loop in \%.3f seconds\n", $end - $start);

if (($end - $start) / $num_rules > 0.1) {
	print "# avg rule insert time was over 0.1 sec!\nnot ";
}
print "ok ", $testiter++, "\n";

($start, $start_usec) = gettimeofday();

@rules = $table->list_rules("INPUT");

($end, $end_usec) = gettimeofday();
$start += $start_usec / 1000000.0;
$end += $end_usec / 1000000.0;

printf("# finished rule list in \%.3f seconds\n", $end - $start);
if ($end - $start > 1.0) {
	print "# list time was over 1.0 sec!\nnot ";
}
print "ok ", $testiter++, "\n";

$table->flush_entries("INPUT");

($start, $start_usec) = gettimeofday();

for (my $i = 0; $i < $num_chains; $i++) {
	$table->create_chain("chain-$i");
}

($end, $end_usec) = gettimeofday();
$start += $start_usec / 1000000.0;
$end += $end_usec / 1000000.0;

printf("# average chain create time was \%.5f seconds\n", ($end - $start) / $num_chains);
printf("# finished create loop in \%.3f seconds\n", $end - $start);

if (($end - $start) / $num_chains > 0.1) {
	print "# avg chain create time was over 0.1 sec!\nnot ";
}
print "ok ", $testiter++, "\n";

($start, $start_usec) = gettimeofday();

@chains = $table->list_chains();

($end, $end_usec) = gettimeofday();
$start += $start_usec / 1000000.0;
$end += $end_usec / 1000000.0;

printf("# finished chain list in \%.3f seconds\n", $end - $start);
if ($end - $start > 1.0) {
	print "# list time was over 1.0 sec!\nnot ";
}
print "ok ", $testiter++, "\n";

($start, $start_usec) = gettimeofday();

foreach my $chain ($table->list_chains()) {
	$table->flush_entries($chain);
}

($end, $end_usec) = gettimeofday();
$start += $start_usec / 1000000.0;
$end += $end_usec / 1000000.0;

printf("# average flush time was \%.5f seconds\n", ($end - $start) / $num_chains);
printf("# finished chain flush in \%.3f seconds\n", $end - $start);
if ((($end - $start) / $num_chains) > 0.01) {
	print "# average flush time was over 0.01 sec!\nnot ";
}
print "ok ", $testiter++, "\n";

($start, $start_usec) = gettimeofday();

foreach my $chain ($table->list_chains()) {
	unless ($table->builtin($chain)) {
		$table->delete_chain($chain);
	}
}

($end, $end_usec) = gettimeofday();
$start += $start_usec / 1000000.0;
$end += $end_usec / 1000000.0;

printf("# average delete time was \%.5f seconds\n", ($end - $start) / $num_chains);
printf("# finished chain delete in \%.3f seconds\n", $end - $start);
if ((($end - $start) / $num_chains) > 0.01) {
	print "# average delete time was over 0.01 sec!\nnot ";
}
print "ok ", $testiter++, "\n";

exit(0);
# vim: ts=4
