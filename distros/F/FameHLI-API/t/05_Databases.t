#=============================================================================
#	File:	05_Databases.t
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
		print "1..24\n";
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
;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$vars			=	GetVars();
my		$conn;
my		$dbkey;
my		$dbname			=	$vars->{famedb};
my		$host			=	$vars->{hostname};
my		$scalar			=	$vars->{famestrscalar};
my		$name			=	"\%junk";
my		$pwd			=	$vars->{password};
my		$rc;
my		$rng;
my		$service		=	$vars->{service};
my		$str			=	"Some stuff";
my		$user			=	$vars->{username};

;#		------------------------------------------------------------
my		$log = StartTest("05_Databases");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		printf($log "--> Handling Databases\n");
;#		------------------------------------------------------------
		unlink("testdb.db");
		ShowResults($log, 1,0,"cfmopdb(c)", Cfmopdb($dbkey, "testdb", HCMODE));
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
		ShowResults($log, 1,0,"cfmopdb(u)", Cfmopdb($dbkey, "testdb", HUMODE));

;#		------------------------------------------------------------
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmnwob",
			Cfmnwob($dbkey, $name, HSCALA, HUNDFX, HSTRNG, HBSUND, HOBUND),
			"create '%s'", $name);
		ShowResults($log, 1,0,"cfmwstr", 
			Cfmwstr($dbkey, $name, $rng, $str, HNMVAL, length($str)),
			"write a value");
		ShowResults($log, 1,0,"cfmgtstr",
			Cfmgtstr($dbkey, $name, $rng, $answer),
			$answer);
		ShowResults($log, 0,0,"Check value", $answer eq $str ? HSUCC : -1);

;#		------------------------------------------------------------
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmrsdb", Cfmrsdb($dbkey));
		print($log "Before($dbkey, $name, rng, $answer)\n");
		$rc = Cfmgtstr($dbkey, $name, $rng, $answer),
;#		$rc = HSUCC; # which is not what is expected.
		print($log "After($rc:$name)\n");
;# 11 
		ShowResults($log, 1,0,"cfmgtstr", ($rc == HNOOBJ) ? HSUCC : -1,
			"'%s' is gone now", $name);
;# 12
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));

;#		------------------------------------------------------------
;#		------------------------------------------------------------
		unlink("packdb.db");
;# 13
		ShowResults($log, 1,0,"cfmopdb(c)", Cfmopdb($dbkey, "packdb", HCMODE));
		ShowResults($log, 1,0,"cfmpack", Cfmpack($dbkey));
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
		ShowResults($log, 1,0,"cfmopdb(r)", Cfmopdb($dbkey, "packdb", HRMODE));
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));

;#		------------------------------------------------------------
;#		If there is no service then we cannot open the channel
;#		------------------------------------------------------------
		if ($service eq "none") {
			SkipResults($log, 1,0,"cfmopcn", 0, "PWD file not found");
			SkipResults($log, 1,0,"cfmopdc", 0, "PWD file not found");
			SkipResults($log, 1,0,"cfmgcid", 0, "PWD file not found");
			SkipResults($log, 1,0,"cfmgtstr",0, "PWD file not found");
			SkipResults($log, 1,0,"cfmcldb", 0, "PWD file not found");
			SkipResults($log, 1,0,"cfmclcn", 0, "PWD file not found");

;#		------------------------------------------------------------
;#		Otherwise, let us test what we are given.
;#		------------------------------------------------------------
		} else {
;# 18
			ShowResults($log, 1,0,"cfmopcn", 
				Cfmopcn($conn, $service, $host, $user, $pwd), $conn);
			ShowResults($log, 1,0,"cfmopdc",
				Cfmopdc($dbkey, $dbname, HRMODE, $conn));
			ShowResults($log, 1,0,"cfmgcid", Cfmgcid($dbkey, $conn));
	
			ShowResults($log, 1,0,"cfmgtstr",
				Cfmgtstr($dbkey, $scalar, $rng, $answer),
				"%", $answer);

;# 22
			ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
			ShowResults($log, 1,0,"cfmclcn", Cfmclcn($conn));
		}

;# 24
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}
