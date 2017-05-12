Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Processes.t - List all processes, then try to launch MacPerl
#

use Mac::Processes;
use Mac::MoreFiles '%Application';

printf "%-30s %-8s %4s %-8s\n", "Process Name", "PSN", "PID", "App Spec";

while (($psn, $pi) = each %Process) {
	# check with PSN
	print "** vv **  this is us\n" if SameProcess(GetCurrentProcess(), $pi->processNumber);

	printf "%-30s %08X % 4d %s %s\n", 
		$pi->processName, $pi->processNumber,
		GetProcessPID($pi->processNumber),
		$pi->processAppSpec,
		$pi->processSignature;

	# check with PID
	print "** ^^ **  this is us\n" if $$ == GetProcessPID($pi->processNumber);
}

exit;
my $app = $Application{McPL};
if (-e $app) {
	$Launch = new LaunchParam(
		launchControlFlags => launchContinue+launchNoFileFlags+launchDontSwitch,
		launchAppSpec      => $app
	);

	LaunchApplication($Launch) || die $^E+0;

	printf "Launched %X flags %X\n", $Launch->launchProcessSN, $Launch->launchControlFlags;
}
