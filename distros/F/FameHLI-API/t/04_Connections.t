#=============================================================================
#	File:	04_Connections.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Testing file for FameHLI functions
#	Editor:	vi with tabstops=4
#=============================================================================
#	NOTE:
#		This unit test "Unit Of Work" functions which, well, are not tested
#		here.  Maybe someday...
#=============================================================================
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN {
	$| = 1;
	require("./t/subs.pm");
	if (!$ENV{FAME}) {
		print "1..0 # Skipped: No FAME Environment Variable defined!\n";
		exit;
	} else {
		print "1..5\n";
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
my		$host			=	$vars->{hostname};
my		$pwd			=	$vars->{password};
my		$service		=	$vars->{service};
my		$user			=	$vars->{username};

my		$conn;
my		$rc;

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$log = StartTest("04_Connections");
;# 2
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		print($log "--> Handling Connections\n");
;#		------------------------------------------------------------
		print($log "service is '$service'\n");
		if ($service eq "none") {
			SkipResults($log, 1,0,"cfmopcn", 0, "PWD file not found");
			SkipResults($log, 1,0,"cfmclcn", 0, "PWD file not found");
		} else {
;# 3
			ShowResults($log, 1,0,"cfmopcn", 
				Cfmopcn($conn, $service, $host, $user, $pwd), $conn);
			ShowResults($log, 0,0,"cfmgcid", 999);#checked in Analytical Channel
			ShowResults($log, 0,0,"cfmcmmt", 999);
			ShowResults($log, 0,0,"cfmabrt", 999);
;# 4
			ShowResults($log, 1,0,"cfmclcn", Cfmclcn($conn));
		}
;#		------------------------------------------------------------
;# 5
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}
