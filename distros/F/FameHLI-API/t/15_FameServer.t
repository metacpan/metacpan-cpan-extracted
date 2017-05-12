#=============================================================================
#	File:	15_FameServer.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Testing file for FameHLI functions
#	Mod:	2005/03/15 daveo: Added interactive tests
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
my		$vars			=	GetVars();
my		$rc;
my		$work;

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$class;
my		$type;
my		$freq;
my		$eyear;
my		$eprd;
my		$fyear;
my		$fprd;
my		$lyear;
my		$lprd;
my		$syear;
my		$sprd;
my		$cdate;
my		$mdate;
my		$basis;
my		$observ;
my		$cyear;
my		$cmonth;
my		$cday;
my		$myear;
my		$mmonth;
my		$mday;

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$log = StartTest("15_FameServer");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		printf($log "--> Using the FAME/Server\n");
;#		------------------------------------------------------------
		if (InteractiveFame()) {
			ShowResults($log, 1,0,"cfmopwk", Cfmopwk($work));
			ShowResults($log, 1,0,"cfmfame", Cfmfame("fred = today"));
			ShowResults($log, 1,0,"cfmwhat",
				Cfmwhat($work, "fred",
					$class, $type, $freq, $basis, $observ,
					$fyear, $fprd, $lyear, $lprd,
					$cyear, $cmonth, $cday,
					$myear, $mmonth, $mday,
					$desc, $doc),
				"%s, %s, %s, %s, %s,\n"
					. "\t\t%s, %s, %s, %s,\n"
					. "\t\t%s/%s/%s,\n"
					. "\t\t%s/%s/%s,\n"
					. "\t\t%s, %s",
				ClassDesc($class),
				TypeDesc($type),
				FreqDesc($freq),
				BasisDesc($basis),
				ObservedDesc($observ),
				$lyear, $fprd, $lyear, $lprd,
				$cyear, $cmonth, $cday, $myear, $mmonth, $mday,
				$desc, $doc);
		} else {
			SkipResults($log, 1,0,"cfmopwk", 0, "Interactive Fame failed");
			SkipResults($log, 1,0,"cfmfame", 0, "Interactive Fame failed");
			SkipResults($log, 1,0,"cfmwhat", 0, "Interactive Fame failed");
		}

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}

