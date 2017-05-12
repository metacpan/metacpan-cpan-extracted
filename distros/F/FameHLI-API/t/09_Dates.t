#=============================================================================
#	File:	09_Dates.t
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
		print "1..29\n";
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

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$log = StartTest("09_Dates");
		ShowResults($log, 1,0,"cfmini", Cfmini());
		ShowResults($log, 1,0,"cfmini", FameHLI::API::EXT::BootstrapEXT(),
			"Bootstrap EXT");

;#		------------------------------------------------------------
		printf($log "--> Handling Dates\n");
;#		------------------------------------------------------------
my		$date;

		ShowResults($log, 1,0,"cfmfdiv", Cfmfdiv(HANDEC, HQTDEC, $answer),
			"Survey said: %s", ($answer == HYES) ? "Yes" : "No");

		ShowResults($log, 1,0,"Check values", 
			($answer == HYES) ? HSUCC : -1, "Freqs are divisible");
		ShowResults($log, 1,0,"cfmtody", 
			Cfmtody(HBUSNS, $date), FormatDate($date, HBUSNS));

my		$freq2	=	0;
my		$base	=	HSEC;
my		$nunits	=	10;
		$year	=	0;
		$month	=	0;

		ShowResults($log, 1,0,"cfmpind", 
			Cfmpind(HHOUR, $count), "Check Next value too");
		ShowResults($log, 1,0,"Check result", $count == 24 ? HSUCC : -1,
			"%d Hours per day", $count);

		ShowResults($log, 1,0,"cfmpinm", Cfmpinm(HDAILY, 2000, HFEB, $count),
			"Check 2000/02");
		ShowResults($log, 1,0,"Check result", $count == 29 ? HSUCC : -1,
			"%d Days in Feb 2000", $count);

		ShowResults($log, 1,0,"cfmpinm", Cfmpinm(HDAILY, 2001, HFEB, $count),
			"Check 2001/02");
		ShowResults($log, 1,0,"Check result", $count == 28 ? HSUCC : -1,
			"%d Days in Feb 2001", $count);

		ShowResults($log, 0,0,"cfmpiny", Cfmpiny(HDAILY, 2000, $count),
			"Check 2000 (%d)", $count);
		ShowResults($log, 1,0,"Check result", $count == 366 ? HSUCC : -1,
			"%d Days in 2000", $count);

		ShowResults($log, 0,0,"cfmpiny", Cfmpiny(HDAILY, 2001, $count),
			"Check 2001 (%d)", $count);
		ShowResults($log, 1,0,"Check result", $count == 365 ? HSUCC : -1,
			"%d Days in 2001", $count);

my		$testdate = 39089;
my		$test = 6;
		ShowResults($log, 0,0,"cfmwkdy", 
			Cfmwkdy(HBUSNS, $testdate, $wkdy), 
			"Checking '%s' (%d)", FormatDate($testdate, HBUSNS), $wkdy);
		ShowResults($log, 1,0,"Check result", $wkdy == $test ? HSUCC : -1,
			"%d FameDate is weekday %d", $testdate, $wkdy);

		$test = 13;
		ShowResults($log, 0,0,"cfmbwdy", 
			Cfmbwdy(HBUSNS, $testdate, $bwdy), 
			"Checking '%s' (%d)", FormatDate($testdate, HBUSNS), $bwdy);
		ShowResults($log, 1,0,"Check result", $bwdy == $test ? HSUCC : -1,
			"%d FameDate is weekday %d", $testdate, $bwdy);

		ShowResults($log, 1,0,"cfmislp", Cfmislp(2001, $isit), "Check 2001");
		ShowResults($log, 1,0,"Check result", ($isit == HNO) ? HSUCC : -1, 
			"2001 isn't a leap year");

		ShowResults($log, 1,0,"cfmislp", Cfmislp(2004, $isit), "Check 2004");
		ShowResults($log, 1,0,"Check result", ($isit == HYES) ? HSUCC : -1,
			"2004 is a leap year");
		$test = 54723;
		ShowResults($log, 0,0,"cfmchfr", 
			Cfmchfr(HBUSNS, $testdate, HEND, HDAILY, $newdate, HBEFOR),
			"%s (%d) to %s (%d)",
			FormatDate($testdate, HBUSNS), $testdate,
			FormatDate($newdate, HDAILY), $newdate);
		ShowResults($log, 1,0,"Check result", $newdate == $test ? HSUCC : -1,
			"<freq b>%d FameDate is <freq d>%d FameDate", $testdate, $newdate);

		ShowResults($log, 1,0,"cfmpfrq", 
			Cfmpfrq($freq2, $base, $nunits, $year, $month),
				"%s '%s'", $freq2, FreqDesc($freq2));

		ShowResults($log, 1,0,"cfmufrq", 
			Cfmufrq($freq2, $base, $nunits, $year, $month),
			"%s, %s, %s, %s", FreqDesc($base),
			$nunits, $year, $month);

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}

