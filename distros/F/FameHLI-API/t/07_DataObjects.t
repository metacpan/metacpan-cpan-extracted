#=============================================================================
#	File:	07_DataObjects.t
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
		print "1..13\n";
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
my		$dbkey;
my		$rbkey;
my		$rc;

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$strname = "teststr";
my		$strnam2 = "testnd1str";
my		$strnam3 = "testnd2str";
my		$numname = "testnum";
my		$precname = "testprec";
my		$datename = "testdate";
my		$boolname = "testbool";

my		$log = StartTest("07_DataObjects");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmopdb(u)", Cfmopdb($dbkey, "testdb", HUMODE));

;#		------------------------------------------------------------
		printf($log "--> Handling Data Objects\n");
;#		------------------------------------------------------------
my		$firstname	=	"testobj";
my		$secondname	=	"testobj2";
my		$thirdname	=	"finalobj";
my		$aliases	=	"{alias1,alias2}";
my		$len;
my		$image		=	"<YEAR>/<MZ>/<DZ>";

		ShowResults($log, 1,0,"cfmnwob(n)", 
			Cfmnwob($dbkey, $firstname, HSERIE, HBUSNS, HNUMRC,
								HBSDAY, HOBEND),
			$firstname);
		ShowResults($log, 1,0,"cfmalob(s)", 
			Cfmalob($dbkey, $strname, HSCALA, HUNDFX, HSTRNG, HBSUND, HOBUND,
					0, 0, 0),
			$strname);
		ShowResults($log, 1,0,"cfmalob(s)", 
			Cfmalob($dbkey, $strnam2, HSCALA, HUNDFX, HSTRNG, HBSUND, HOBUND,
					0, 0, 0),
			$strnam2);
		ShowResults($log, 1,0,"cfmalob(s)", 
			Cfmalob($dbkey, $strnam3, HSCALA, HUNDFX, HSTRNG, HBSUND, HOBUND,
					0, 0, 0),
			$strnam3);

		ShowResults($log, 1,0,"cfmcpob", 
			Cfmcpob($dbkey, $dbkey, $firstname, $secondname),
			"$firstname -> $secondname");
		ShowResults($log, 1,0,"cfmdlob",
			Cfmdlob($dbkey, $firstname), $firstname);
		ShowResults($log, 1,0,"cfmrnob",
			Cfmrnob($dbkey, $secondname, $thirdname),
			"$secondname to $thirdname");

;#		------------------------------------------------------------
;#		Unit of work stuff.  I don't know how to test this...
;#		------------------------------------------------------------
		ShowResults($log, 0,0,"cfmasrt", 999);

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmpodb", Cfmpodb($dbkey));
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}
