#=============================================================================
#	File:	12_Writing.t
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
		print "1..30\n";
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
my		$rc;
my		$str			=	"";

;#		------------------------------------------------------------
;#		------------------------------------------------------------
my		$strname = "teststr";
my		$strnam2 = "testnd1str";
my		$strnam3 = "testnd2str";
my		$numname = "testnum";
my		$precname = "testprec";
my		$datename = "testdate";
my		$boolname = "testbool";

my		$wr_num_test	=	"wr_num_test";
my		$wr_nms_test	=	"wr_nms_test";
my		$wr_nms_testNA	=	"wr_nms_testNA";
my		$wr_nms_testNC	=	"wr_nms_testNC";
my		$wr_nms_testND	=	"wr_nms_testND";
my		$wr_nml_test	=	"wr_nml_test";
my		$wr_boo_test	=	"wr_boo_test";
my		$wr_str_test	=	"wr_str_test";
my		$wr_prc_test	=	"wr_prc_test";
my		$wr_dat_test	=	"wr_dat_test";

my		$text		=	"Test Value";
my		$tmp		=	"";
my		$log = StartTest("12_Writing");
		ShowResults($log, 1,0,"cfmini", Cfmini());

;#		------------------------------------------------------------
my		$rng;
my		$syear	=	1999;
my		$sprd	=	1;
my		$eyear	=	1999;
my		$eprd	=	31;
my		$numobs	=	-1;

		ShowResults($log, 1,0,"cfmsfis",
			Cfmsfis(HBUSNS, $syear, $sprd, $eyear, $eprd, $rng, $numobs),
			"sy:%s, sp:%s, ey:%s, ep:%s, n:%s",
			$syear, $sprd, $eyear, $eprd, $numobs);


		$eyear	=	-1;
		$eprd	=	-1;

		ShowResults($log, 1,0,"cfmsrng",
			Cfmsrng(HBUSNS, $syear, $sprd, $eyear, $eprd, $rng, $numobs),
			"sy:%s, sp:%s, ey:%s, ep:%s, n:%s", 
			$syear, $sprd, $eyear, $eprd, $numobs);

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmopdb(u)", 
			Cfmopdb($dbkey, "testdb", HUMODE));

;#		------------------------------------------------------------
		printf($log "--> Writing Series Data\n");
;#		------------------------------------------------------------
;#		Numeric
;#		--------------------
my		@testdata = NumData();
my		@NAdata = NAData();
my		@NCdata = NCData();
my		@NDdata = NDData();
my		$NDscalar = "ND";
my		$tdref = \@testdata;
my		$NAref = \@NAdata;
my		$NCref = \@NCdata;
my		$NDref = \@NDdata;
my		$NDscalref = \$NDscalar;
my		$ndata;

my		$cnt = $#testdata;

		ShowResults($log, 1,0,"cfmnwob(num)", 
			Cfmnwob($dbkey, $wr_num_test, HSERIE, HBUSNS, HNUMRC),
			$wr_num_test);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_num_test, $rng, $tdref, 0, $NoMissTbl));

;#		--------------------
;#		Boolean
;#		--------------------
		ShowResults($log, 1,0,"cfmnwob(bool)", 
			Cfmnwob($dbkey, $wr_boo_test, HSERIE, HBUSNS, HBOOLN),
			$wr_boo_test);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_boo_test, $rng, $tdref, 0, $NoMissTbl));

;#		--------------------
;#		Precision
;#		--------------------
		ShowResults($log, 1,0,"cfmnwob(prc)", 
			Cfmnwob($dbkey, $wr_prc_test, HSERIE, HBUSNS, HPRECN),
			$wr_prc_test);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_prc_test, $rng, $tdref, 0, $NoMissTbl));

;#		--------------------
;#		Date
;#		--------------------
		@testdata = DateData();
		$tdref = \@testdata;

		ShowResults($log, 1,0,"cfmnwob(date)", 
			Cfmnwob($dbkey, $wr_dat_test, HSERIE, HBUSNS, HBUSNS),
			$wr_dat_test);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_dat_test, $rng, $tdref, 0, $NoMissTbl));

;#		--------------------
;#		String
;#		--------------------
		ShowResults($log, 1,0,"cfmnwob(str)", 
			Cfmnwob($dbkey, $wr_str_test, HSERIE, HBUSNS, HSTRNG));
		ShowResults($log, 1,0,"cfmwsts", Cfmwsts($dbkey, $wr_str_test, 
				$rng, $tdref));

;#		------------------------------------------------------------
		printf($log "--> Writing Scalar Data\n");
;#		------------------------------------------------------------

;#		------------------------------------------------------------
;#		Write a numeric scalar
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmnwob(nms)", 
			Cfmnwob($dbkey, $wr_nms_test, HSCALA, 0, HNUMRC),
			$wr_nms_test);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_nms_test, $rng, $tdref, 0, $NoMissTbl));

		ShowResults($log, 1,0,"cfmnwob(nmsNA)", 
			Cfmnwob($dbkey, $wr_nms_testNA, HSCALA, 0, HNUMRC),
			$wr_nms_testNA);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_nms_testNA, $rng, $NAref, 0, $NoMissTbl));

		ShowResults($log, 1,0,"cfmnwob(nmsNC)", 
			Cfmnwob($dbkey, $wr_nms_testNC, HSCALA, 0, HNUMRC),
			$wr_nms_testNC);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_nms_testNC, $rng, $NCref, 0, $NoMissTbl));

		ShowResults($log, 1,0,"cfmnwob(nmsND)", 
			Cfmnwob($dbkey, $wr_nms_testND, HSCALA, 0, HNUMRC),
			$wr_nms_testND);
		ShowResults($log, 1,0,"cfmwrng", 
			Cfmwrng($dbkey, $wr_nms_testND, $rng, $NDref, 0, $NoMissTbl));

;#		------------------------------------------------------------
;#		Write a string scalar
;#		Note: you can either write a Missing Value by setting ISMISS
;#		(as is normal in CHLI) or by using a reference to 'NA', 'NC'
;#		or 'ND' as is the PerlHLI pseudo-standard.
;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmwstr", 
			Cfmwstr($dbkey, $strname, $rng, $text, 0, length($text)),
			 $strname);

		ShowResults($log, 1,0,"cfmwstr(ND/ref)", 
			Cfmwstr($dbkey, $strnam2, $rng, $NDscalref, 0, length($text)),
			 $strnam2);

		ShowResults($log, 1,0,"cfmwstr(ND/ismiss)", 
			Cfmwstr($dbkey, $strnam3, $rng, $text, HNDVAL, length($text)),
			 $strnam3);

;#		--------------------
;#		Name List
;#		--------------------
;#		------------------------------------------------------------
;#		Fame will put the spaces in if you don't.  I put them in so
;#		I could accurately compare string lengths.
;#		------------------------------------------------------------
		$tmp = "$wr_boo_test"
			.	", $wr_num_test"
			.	", $wr_prc_test"
			.	", $wr_str_test"
			.	", $wr_dat_test";

		ShowResults($log, 1,0,"cfmnwob(nl)", 
			Cfmnwob($dbkey, $wr_nml_test, HSCALA, 0, HNAMEL));
		ShowResults($log, 1,0,"cfmwtnl", 
			Cfmwtnl($dbkey, $wr_nml_test, HNLALL, $tmp));
		ShowResults($log, 0,0,"cfmnlen", 999);	# depricated
		ShowResults($log, 0,0,"cfmwrmt", 999); # not implemented yet

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmcldb", Cfmcldb($dbkey));
		ShowResults($log, 1,0,"cfmfin", Cfmfin());
}

