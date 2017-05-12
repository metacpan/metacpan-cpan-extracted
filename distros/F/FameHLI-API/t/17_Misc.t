#=============================================================================
#	File:	17_Misc.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Testing file for FameHLI functions
#	Mod:	2005/03/15 daveo: Added interactive tests
#	Editor:	vi with tabstops=4
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
	} elsif (InteractiveFame()) {
		print "1..20\n";
    } else {
        print "1..0 # Skipped: Interactive Fame failed\n";
        exit;
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
my		$datstr			=	$vars->{spindate};
my		$db				=	$vars->{spindex};
my		$dbkey;
my		$work;
my		$host			=	$vars->{hostname};
my		$pwd			=	$vars->{password};
my		$service		=	$vars->{service};
my		$user			=	$vars->{username};

;#		------------------------------------------------------------
;#		Start things off by opening the log and initialzing Fame.
;#		You have to call cfmopwk or cfmferr will crash... sigh.
;#		------------------------------------------------------------
my		$log = StartTest("17_Misc");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
		printf($log "--> Getting FAME Errors\n");
;#		------------------------------------------------------------
;#		First, let us load up the return codes...
;#		------------------------------------------------------------
		$r1 = Cfmfame("signal error: \"Hi Mom.\"");
		ShowResults($log, 1,HFAMER,"cfmfame", $r1, "Failed properly");

;#		------------------------------------------------------------
;#		Now we need to get the error code.  Note that the work
;#		database needs to be open before we call Cfmferr on Linux
;#		platform.  This seems to make no difference on Solaris or
;#		Windows. On those platforms we can skip Cfmopwk. Go figure.
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmopwk", Cfmopwk($work));
		$r3 = Cfmferr($msg);

;#		------------------------------------------------------------
;#		Print out the messages and, whazzup? No error length!
;#		------------------------------------------------------------
		ShowResults($log, 1,HSUCC,"cfmferr", $r3, $msg);

;#		------------------------------------------------------------
;#		Now, open some stuff so we can use remeval...
;#		------------------------------------------------------------
		if ($host eq "none") {
			SkipResults($log, 1,0, "cfmopcn", 0, "PWD file not found");
			SkipResults($log, 1,0, "cfmoprc", 0, "PWD file not found");
			SkipResults($log, 1,0, "cfmopdb", 0, "PWD file not found");
			SkipResults($log, 1,0, "cfmrmev", 0, "PWD file not found");
			SkipResults($log, 1,0, "cfmferr", 0, "PWD file not found");
			SkipResults($log, 1,0, "cfmcldb", 0, "PWD file not found");
			SkipResults($log, 1,0, "cfmcldb", 0, "PWD file not found");
		} else {
			ShowResults($log, 1,HSUCC,"cfmopcn", 
				Cfmopcn($conn, $service, $host, $user, $pwd), $conn);
			ShowResults($log, 1,HSUCC,"cfmoprc", 
				Cfmoprc($dbkey, $conn), $dbkey);
			ShowResults($log, 1,HSUCC,"cfmopdb", 
				Cfmopdb($wdbkey, "testdb", HUMODE));

;#		------------------------------------------------------------
;#		Load up a new batch of return codes...
;#		------------------------------------------------------------
			$r1 = Cfmrmev($dbkey, "fred is here", "", $wdbkey, "fred");
			$r3 = Cfmferr($msg);

;#		------------------------------------------------------------
;#		Print out the messages and voila! we have an error length!
;#		------------------------------------------------------------
			ShowResults($log, 1,HFAMER,"cfmrmev", $r1, "Failed properly");
			ShowResults($log, 1,HSUCC,"cfmferr", $r3, $msg);

;#		------------------------------------------------------------
;#		Now, let us clean up after ourselves.
;#		------------------------------------------------------------
			ShowResults($log, 1,0,"cfmcldb", Cfmcldb($wdbkey));
			ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
		}

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$date;

		print($log "DB:'$db'\nDate:$datstr\n");

		if ($db ne "none") {
			ShowResults($log, 1,HSUCC,"Cfmopdb",
				Cfmopdb($dbkey, $db, HRMODE));

my			($syear, $sprd, $eyear, $eprd, $numobs) = (-1, -1, -1, -1, 1);
my			$divisor;
my			$nada;
my			$range;

			ShowResults($log, 1,HSUCC,"Cfmidat",
				Cfmidat(HBUSNS, $date, $datstr, "<YEAR><MZ><DZ>",
							HDEC, HFYFST, 2000), "%s (%d)", $datstr, $date);

			ShowResults($log, 1,HSUCC,"Cfmdatp",
				Cfmdatp(HBUSNS, $date, $syear, $sprd),
					"%d (%d:%d)", $date, $syear, $sprd);

			ShowResults($log, 1,HSUCC,"Cfmsrng",
				Cfmsrng(HBUSNS, $syear, $sprd,
								$eyear, $eprd, $range, $numobs));

			ShowResults($log, 1,HSUCC,"Cfmrrng",
				Cfmrrng($dbkey, "SP500.DIVISOR", $range,
						$divisor, HNTMIS, $nada),
						"Divisor is %3.3f", $divisor->[0]);

			ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
		} else {
			print($log "Start -- Skipping SPINDEX test\n");
			for (my $i=0; $i<6; $i++) {
				SkipResults($log, 1,0,"spindex", 0, "No SPINDEX db");
			}
			print($log "End ---- Skipping SPINDEX test\n");
		}

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($work));
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}

