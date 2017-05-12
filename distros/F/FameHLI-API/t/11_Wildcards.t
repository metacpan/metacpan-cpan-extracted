#=============================================================================
#	File:	11_Wildcards.t
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
		print "1..34\n";
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

my		$class;
my		$dbkey;
my		$freq;
my		$rc;
my		$str;
my		$type;

;#		------------------------------------------------------------
my		$tmpstr;
my		$log = StartTest("11_Wildcards");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmopdb(u)", 
			Cfmopdb($dbkey, "testdb", HUMODE));


;#		------------------------------------------------------------
		printf($log "--> Wildcarding\n");
;#		------------------------------------------------------------

		ShowResults($log, 1,0,"cfmpodb", Cfmpodb($dbkey));

			$rc = Cfminwc($dbkey, "?");
			ShowResults($log, 1,0,"cfminwc", $rc, "?");
			while ($rc != HNOOBJ) {
				$rc = Cfmnxwc($dbkey, $str, $class, $type, $freq); 
				if ($rc == HNOOBJ) {
					ShowResults($log, 0,HNOOBJ, ,"cfmnxwc", $rc,
						"End of list");
				} else {
					ShowResults($log, 1,0,"cfmgnam",
						Cfmgnam($dbkey, $str, $tmpstr),
						"Realname is '$tmpstr'");
					ShowResults($log, 0,0,"cfmnxwc", $rc,
						"'%s' (%s) %s, %s, %s", 
						$str,
						$tmpstr,
						ClassDesc($class),
						TypeDesc($type),
						FreqDesc($freq));
				}
			}

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}

