#=============================================================================
#	File:	14_ConvDates.t
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
		print "1..17\n";
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
my		$rc;

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$log = StartTest("14_ConvDates");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		printf($log "--> Converting Dates\n");
;#		------------------------------------------------------------
;#		This first variable is a little iffy... It should be set 
;#		somewhere where we can make sure that it is valid...
;#		------------------------------------------------------------
		{
my			$date		=	0;
my			$intradate	=	54000;
my			$hour		=	12;
my			$minute		=	30;
my			$second		=	15;

			ShowResults($log, 1,0,"cfmtdat", 
				Cfmtdat(HSEC, $date, $hour, $minute, $second, $intradate),
				$date);

			ShowResults($log, 1,0,"cfmdatt", 
				Cfmdatt(HSEC, $date, $hour, $minute, $second, $intradate),
				"%s, %s:%s:%s", $intradate, $hour, $minute, $second);
		}
;#		------------------------------------------------------------
		{
my			$date = 0;
my			$year = 0;
my			$month = 0;
my			$day = 0;

			ShowResults($log, 1,0,"cfmddat", 
				Cfmddat(HBUSNS, $date, 1999, 9, 1),
				$date);

			ShowResults($log, 1,0,"cfmdatd", 
				Cfmdatd(HBUSNS, $date, $year, $month, $day),
				"%s/%s/%s", $year, $month, $day);

;#		------------------------------------------------------------
my			$xyear = 2001;
my			$xperiod = 42;
			$date = 0;

			ShowResults($log, 1,0,"cfmpdat", 
				Cfmpdat(HBUSNS, $date, $xyear, $xperiod));
			ShowResults($log, 1,0,"cfmdatp", 
				Cfmdatp(HBUSNS, $date, $year, $period));
			ShowResults($log, 1,0,"Check values", 
				($year == $xyear and $period == $xperiod) ? HSUCC : -1,
				"Conversion worked.");
			ShowResults($log, 1,0,"cfmfdat", 
				Cfmfdat(HBUSNS, $date, $xyear, $xperiod, HDEC, HFYLST));
			ShowResults($log, 1,0,"cfmdatf", 
				Cfmdatf(HBUSNS, $date, $year, $period, HDEC, HFYLST));
			ShowResults($log, 1,0,"Check values", 
				($year == $xyear and $period == $xperiod) ? HSUCC : -1,
				"Conversion worked.");
		}
;#		------------------------------------------------------------
;#		------------------------------------------------------------
		{
my			$date = 0;
my			$year = 0;
my			$month = 0;
my			$day = 0;

			ShowResults($log, 1,0,"cfmldat", 
				Cfmldat(HBUSNS, $date, "1sep1999", HDEC, HFYFST, 1999),
				$date);

			ShowResults($log, 1,0,"cfmdatl", 
				Cfmdatl(HBUSNS, $date, $datestr, HDEC, HFYFST),
				$datestr);
		}
;#		------------------------------------------------------------

		{
my			$image = "<YEAR>/<MZ>/<DZ>";

			ShowResults($log, 1,0,"cfmidat", 
				Cfmidat(HBUSNS, $date, "1999/09/01", $image, HDEC, HFYFST),
				$date);

			ShowResults($log, 1,0,"cfmdati", 
				Cfmdati(HBUSNS, $date, $datestr, $image, HDEC, HFYFST), 
				$datestr);
		}

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}

