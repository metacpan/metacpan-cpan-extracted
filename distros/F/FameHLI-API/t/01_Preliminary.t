#=============================================================================
#	File:	01_Preliminary.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Create Makefile for FameHLI stuff
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
		print "1..6\n";
	}
}
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";
$| = 1;

######################### End of black magic.

use		FameHLI::API ':all';
use		FameHLI::API::EXT ':all';
use		FameHLI::API::HLI ':all';

		$test::num	=	0;
		$test::num	=	1;
my		$err		=	0;
my		$warn		=	0;

{
my		$rc;

;#		------------------------------------------------------------
my		$log = StartTest("01_Preliminary");
		printf("--> Dental Floss\n");
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"FreqDesc(18)", 0, FreqDesc(18));
		ShowResults($log, 1,0,"TypeDesc(1)", 0, TypeDesc(1));

;#		------------------------------------------------------------
		printf($log "--> Using the HLI\n");
;#		------------------------------------------------------------
;#		Since cfmini is automagically called, we cannot test for
;#		failing to initialize...  so sad...
;#		------------------------------------------------------------
my		$ver;

;#		ShowResults($log, 1,HNINIT,"cfmver", Cfmver($ver), "Failed properly");
		ShowResults($log, 1,0,"cfmini", Cfmini());
		ShowResults($log, 1,0,"cfmver", Cfmver($ver), "%4.4f", $ver);

		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}
