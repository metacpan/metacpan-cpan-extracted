#=============================================================================
#	File:	10_MissVals.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Testing file for FameHLI functions
#	Editor:	vi with tabstops=4
#=============================================================================
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN {
	$| = 1;
	require("./t/subs.pm");
	if (!$ENV{FAME}) {
		print "1..0 # Skipped: No FAME Environment Variable defined!\n";
		exit;
	} else {
		print "1..12\n";
	}
}
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";
$| = 1;

######################### End of black magic.

use		FameHLI::API ':all';
use		FameHLI::API::HLI ':all';

		$test::num	=	0;
		$test::num	=	1;
my		$err		=	0;
my		$warn		=	0;

{
my		$vars			=	GetVars();

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$log = StartTest("10_MissVals");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		printf($log "--> Handling Missing Values\n");
;#		------------------------------------------------------------
my		$nmiss;
my		$pmiss;
my		$bmiss;
my		$miss;

		ShowResults($log, 0,HBCNTX,"cfmsnm", Cfmsnm(1, 1, 1, $miss));
		ShowResults($log, 0,HBCNTX,"cfmspm", Cfmspm(2, 2, 2, $miss));
		ShowResults($log, 0,HBCNTX,"cfmsbm", Cfmsbm(3, 3, 3, $miss));
		ShowResults($log, 0,HBCNTX,"cfmsdm", Cfmsdm(4, 4, 4, $miss));

		ShowResults($log, 0,HBCNTX,"cfmisnm", Cfmisnm(0, $miss));
		ShowResults($log, 0,HBCNTX,"cfmispm", Cfmispm(0, $miss));
		ShowResults($log, 0,HBCNTX,"cfmisbm", Cfmisbm(0, $miss));
		ShowResults($log, 0,HBCNTX,"cfmisdm", Cfmisdm(0, $miss));
		ShowResults($log, 0,HBCNTX,"cfmissm", Cfmissm(0, $miss));

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}
