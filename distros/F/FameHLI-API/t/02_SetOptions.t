#=============================================================================
#	File:	02_SetOptions.t
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
		print "1..4\n";
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
		$| = 1;

{
my		$log = StartTest("02_SetOptions");
		ShowResults($log, 1,0,"cfmini", Cfmini());
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmsopt", Cfmsopt("Item Alias", "on"));
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}
