#=============================================================================
#	File:	01_Preliminary.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Test for FameHLI::API::EXT
#=============================================================================
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use FameHLI::API::EXT;
$loaded = 1;
print "ok 1\n";
$| = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
require("t/subs.pm");
		$test::num	=	0;
		$test::num	=	1;
my		$err		=	0;
my		$warn		=	0;

{
my		$rc;

my		$log = StartTest("01_Preliminary");
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmini", FameHLI::API::EXT::BootstrapEXT());

		ShowResults($log, 1,0,"ClassDesc(3)", 
			FameHLI::API::EXT::ClassDesc(3) eq "FORMULA" ? 0 : -1,
			FameHLI::API::EXT::ClassDesc(3));

		ShowResults($log, 1,0,"ErrDesc(1)", 
			FameHLI::API::EXT::ErrDesc(1) 
				eq "HLI has already been initialized." ? 0 : -1,
			FameHLI::API::EXT::ErrDesc(1));

		ShowResults($log, 1,0,"FreqDesc(9)", 
			FameHLI::API::EXT::FreqDesc(9) eq "BUSINESS" ? 0 : -1,
			FameHLI::API::EXT::FreqDesc(9));

		ShowResults($log, 1,0,"TypeDesc(3)", 
			FameHLI::API::EXT::TypeDesc(3) eq "BOOLEAN" ? 0 : -1,
			FameHLI::API::EXT::TypeDesc(3));

		ShowResults($log, 1,0,"AccessModeDesc(7)", 
			FameHLI::API::EXT::AccessModeDesc(7) eq "DIRECT WRITE" ? 0 : -1,
			FameHLI::API::EXT::AccessModeDesc(7));

		ShowResults($log, 1,0,"BasisDesc(2)", 
			FameHLI::API::EXT::BasisDesc(2) eq "BUSINESS" ? 0 : -1,
			FameHLI::API::EXT::BasisDesc(2));

		ShowResults($log, 1,0,"ObservedDesc(5)", 
			FameHLI::API::EXT::ObservedDesc(5) eq "ANNUALIZED" ? 0 : -1,
			FameHLI::API::EXT::ObservedDesc(5));

		ShowResults($log, 1,0,"MonthsDesc(5)", 
			FameHLI::API::EXT::MonthsDesc(5) eq "MAY" ? 0 : -1,
			FameHLI::API::EXT::MonthsDesc(5));

		ShowResults($log, 1,0,"WeekdayDesc(4)", 
			FameHLI::API::EXT::WeekdayDesc(4) eq "WEDNESDAY" ? 0 : -1,
			FameHLI::API::EXT::WeekdayDesc(4));

		ShowResults($log, 1,0,"BiWeekdayDesc(11)", 
			FameHLI::API::EXT::BiWeekdayDesc(11) eq "BWEDNESDAY" ? 0 : -1,
			FameHLI::API::EXT::BiWeekdayDesc(11));

		ShowResults($log, 1,0,"FYLabelDesc(2)", 
			FameHLI::API::EXT::FYLabelDesc(2) eq "LAST" ? 0 : -1,
			FameHLI::API::EXT::FYLabelDesc(2));
}
