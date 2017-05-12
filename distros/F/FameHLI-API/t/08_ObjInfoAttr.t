#=============================================================================
#	File:	08_ObjInfoAttr.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer
#	Date:	2001/03/23
#	Use:	Testing file for FameHLI functions
#	Editor:	vi with tabstops=4
#=============================================================================
#	NOTE:	This is the only script where I did not import ':all' of the
#			functions.  this way you can see how to call them in the
#			fully qualified syntax.  If you are writing a module that
#			you want to share with others, you should use this syntax.
#			If you are writing a script that few will see then you can
#			consider importing everything.
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
	} else {
		print "1..56\n";
	}
}
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";
$| = 1;

######################### End of black magic.

use		FameHLI::API;
use		FameHLI::API::EXT;
use		FameHLI::API::HLI ':all';

		$test::num	=	0;
		$test::num	=	1;
my		$err		=	0;
my		$warn		=	0;

{
my		$vars			=	GetVars();
my		$cbkey;
my		$dbkey;
my		$rbkey;
my		$rc;
my		$str			=	"";
my		$work;
my		$TestWriteCount	=	31;

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
my		$year;
my		$month;

;#		------------------------------------------------------------
my		$wr_str_test = "wr_str_test";
my		$firstname = "testobj";
my		$secondname = "testobj2";
my		$thirdname = "finalobj";
my		$aliases = "{alias1,alias2}";
my		$len;
my		$image = "<YEAR>/<MZ>/<DZ>";

;#		------------------------------------------------------------
my		$log = StartTest("08_ObjInfoAttr");
		ShowResults($log, 1,0,"cfmini", FameHLI::API::Cfmini());

;#		------------------------------------------------------------
		ShowResults($log, 1,0,"cfmopdb(u)", 
			FameHLI::API::Cfmopdb($dbkey, "testdb", HUMODE));

;#		------------------------------------------------------------
		printf($log "--> Handling Data Objects Information and Attributes\n");
;#		------------------------------------------------------------
my			$doclen;
my			$deslen;

			ShowResults($log, 1,0,"cfmosiz", FameHLI::API::Cfmosiz($dbkey,
				$thirdname, $class, $type, $freq, $fyear, $fprd,
				$lyear, $lprd),
				"%s, %s, %s, %s, %s, %s, %s",
				FameHLI::API::EXT::ClassDesc($class),
				FameHLI::API::EXT::TypeDesc($type),
				FameHLI::API::EXT::FreqDesc($freq),
				$fyear, $fprd, $lyear, $lprd);

			ShowResults($log, 1,0,"cfmgdat", FameHLI::API::Cfmgdat($dbkey,
					$thirdname, HDAILY, $cdate, $mdate),
				"%s [%s], %s [%s]",
				FameHLI::API::EXT::FormatDate($cdate, HDAILY), $cdate,
				FameHLI::API::EXT::FormatDate($mdate, HDAILY), $mdate);

			ShowResults($log, 1,0,"cfmwhat",
				FameHLI::API::Cfmwhat($dbkey, $thirdname,
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
				FameHLI::API::EXT::ClassDesc($class),
				FameHLI::API::EXT::TypeDesc($type),
				FameHLI::API::EXT::FreqDesc($freq),
				FameHLI::API::EXT::BasisDesc($basis),
				FameHLI::API::EXT::ObservedDesc($observ),
				$lyear, $fprd, $lyear, $lprd,
				$cyear, $cmonth, $cday, $myear, $mmonth, $mday,
				$desc, $doc);

			$newdesc = "A new description string";
			$newdoc = "A new documentation string";

			ShowResults($log, 0,0,"cfmncnt", 999);	# depricated
			ShowResults($log, 0,0,"cfmdlen", 999);	# depricated

			ShowResults($log, 1,0,"cfmsdes", 
				FameHLI::API::Cfmsdes($dbkey, $thirdname, $newdesc));
			ShowResults($log, 1,0,"cfmsdoc",
				FameHLI::API::Cfmsdoc($dbkey, $thirdname, $newdoc));

			ShowResults($log, 1,0,"cfmsbas",
				FameHLI::API::Cfmsbas($dbkey, $thirdname, HBSBUS));
			ShowResults($log, 1,0,"cfmsobs",
				FameHLI::API::Cfmsobs($dbkey, $thirdname, HOBSUM));

;#		------------------------------------------------------------
;#		We need to set up the "User Defined Attributes".
;#		------------------------------------------------------------
			ShowResults($log, 1,0,"cfmnwob(UDA-B)", 
				FameHLI::API::Cfmnwob($dbkey, "BOOLEAN_ATTRIBUTE_NAMES",
					HSCALA, 0, HNAMEL));
			ShowResults($log, 1,0,"cfmwtnl",
				FameHLI::API::Cfmwtnl($dbkey, "BOOLEAN_ATTRIBUTE_NAMES",
					HNLALL, "B_TEST"));


			ShowResults($log, 1,0,"cfmnwob(UDA-D)", 
				FameHLI::API::Cfmnwob($dbkey, "DATE_ATTRIBUTE_NAMES",
					HSCALA, 0, HNAMEL));
			ShowResults($log, 1,0,"cfmwtnl",
				FameHLI::API::Cfmwtnl($dbkey, "DATE_ATTRIBUTE_NAMES",
					HNLALL, "D_TEST"));

			ShowResults($log, 1,0,"cfmnwob(UDA-L)", 
				FameHLI::API::Cfmnwob($dbkey, "NAMELIST_ATTRIBUTE_NAMES",
					HSCALA, 0, HNAMEL));
			ShowResults($log, 1,0,"cfmwtnl",
				FameHLI::API::Cfmwtnl($dbkey, "NAMELIST_ATTRIBUTE_NAMES",
					HNLALL, "L_TEST"));

			ShowResults($log, 1,0,"cfmnwob(UDA-N)", 
				FameHLI::API::Cfmnwob($dbkey, "NUMERIC_ATTRIBUTE_NAMES",
					HSCALA, 0, HNAMEL));
			ShowResults($log, 1,0,"cfmwtnl",
				FameHLI::API::Cfmwtnl($dbkey, "NUMERIC_ATTRIBUTE_NAMES",
					HNLALL, "N_TEST"));

			ShowResults($log, 1,0,"cfmnwob(UDA-P)", 
				FameHLI::API::Cfmnwob($dbkey, "PRECISION_ATTRIBUTE_NAMES",
					HSCALA, 0, HNAMEL));
			ShowResults($log, 1,0,"cfmwtnl",
				FameHLI::API::Cfmwtnl($dbkey, "PRECISION_ATTRIBUTE_NAMES",
					HNLALL, "P_TEST"));

			ShowResults($log, 1,0,"cfmnwob(UDA-S)", 
				FameHLI::API::Cfmnwob($dbkey, "STRING_ATTRIBUTE_NAMES",
					HSCALA, 0, HNAMEL));
			ShowResults($log, 1,0,"cfmwtnl",
				FameHLI::API::Cfmwtnl($dbkey, "STRING_ATTRIBUTE_NAMES",
					HNLALL, "S_TEST"));

;#		------------------------------------------------------------
;#		Next we can set an object with an attribute.
;#		------------------------------------------------------------

			ShowResults($log, 0,0,"cfmlatt", 999);	# depricated

my			$inlen = 0;
			ShowResults($log, 1,0,"cfmsatt(Boolean)", 
				FameHLI::API::Cfmsatt($dbkey, $thirdname, HBOOLN, 
						"B_TEST", HYES),
				"Setting to '%d'", HYES);
			ShowResults($log, 1,0,"cfmgtatt(Boolean)", 
				FameHLI::API::Cfmgtatt($dbkey, $thirdname, HBOOLN, 
						"B_TEST", $val),
				"Attribute is %f", $val);

			$inlen = 0;
			ShowResults($log, 1,0,"cfmsatt(Date)", 
				FameHLI::API::Cfmsatt($dbkey, $thirdname, HBUSNS, "D_TEST", $$),
				"Setting to '$$'");
			$freq = HDATE;
			ShowResults($log, 1,0,"cfmgtatt(Date)", 
				FameHLI::API::Cfmgtatt($dbkey, $thirdname, $freq, 
						"D_TEST", $val),
				"Attribute is %d (%d)", $val, $freq);

			$inlen = 0;
			ShowResults($log, 1,0,"cfmsatt(NameList)", 
				FameHLI::API::Cfmsatt($dbkey, $thirdname, HNAMEL, 
					"L_TEST", "A,Name"),
				"Setting to 'A,Name'");
			ShowResults($log, 1,0,"cfmgtatt(NameList)", 
				FameHLI::API::Cfmgtatt($dbkey, $thirdname, HNAMEL, 
					"L_TEST", $val),
				"Attribute is %s", $val);

			$inlen = 0;
			ShowResults($log, 1,0,"cfmsatt(Numeric)", 
				FameHLI::API::Cfmsatt($dbkey, $thirdname, HNUMRC, "N_TEST", $$),
				"Setting to '$$'");
			ShowResults($log, 1,0,"cfmgtatt(Numeric)", 
				FameHLI::API::Cfmgtatt($dbkey, $thirdname, HNUMRC, 
						"N_TEST", $val),
				"Attribute is %f", $val);

			$inlen = 0;
			ShowResults($log, 1,0,"cfmsatt(Precision)", 
				FameHLI::API::Cfmsatt($dbkey, $thirdname, HPRECN, "P_TEST", $$),
				"Setting to '$$'");
			ShowResults($log, 1,0,"cfmgtatt(Precision)", 
				FameHLI::API::Cfmgtatt($dbkey, $thirdname, HPRECN, 
						"P_TEST", $val),
				"Attribute is %f", $val);

			$inlen = 0;
			ShowResults($log, 1,0,"cfmsatt(String)", 
				FameHLI::API::Cfmsatt($dbkey, $thirdname, HSTRNG, "S_TEST", 
					"A String"),
				"Setting to 'A String'");
			ShowResults($log, 1,0,"cfmgtatt", 
				FameHLI::API::Cfmgtatt($dbkey, $thirdname, HSTRNG, 
					"S_TEST", $val),
				"Attribute is %s", $val);

;#		------------------------------------------------------------
;#		Let us see what we have done...
;#		------------------------------------------------------------
			ShowResults($log, 1,0,"cfmwhat",
				FameHLI::API::Cfmwhat($dbkey, $thirdname,
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
				FameHLI::API::EXT::ClassDesc($class),
				FameHLI::API::EXT::TypeDesc($type),
				FameHLI::API::EXT::FreqDesc($freq),
				FameHLI::API::EXT::BasisDesc($basis),
				FameHLI::API::EXT::ObservedDesc($observ),
				$lyear, $fprd, $lyear, $lprd,
				$cyear, $cmonth, $cday, $myear, $mmonth, $mday,
				$desc, $doc);

;#		------------------------------------------------------------
			print("then... ($thirdname, $aliases)\n");
			$inlen = 0;

			ShowResults($log, 0,0,"cfmlali", 999);	# depricated

			ShowResults($log, 1,0,"cfmsali", 
				FameHLI::API::Cfmsali($dbkey, $thirdname, $aliases),
				"Set '%s' with alias string '%s'", $thirdname, $aliases);
			ShowResults($log, 1,0,"cfmgtali", 
				FameHLI::API::Cfmgtali($dbkey, $thirdname, $str),
				"Alias for '$thirdname' is now '%s'", $str);

			ShowResults($log, 1,0,"cfmgnam", 
				FameHLI::API::Cfmgnam($dbkey, "alias1", $str),
				"Realname of 'alias1' is '%s'", $str);
			ShowResults($log, 0,HNOOBJ,"cfmgnam(err)", 
				FameHLI::API::Cfmgnam($dbkey, "albakirky", $str),
				"Realname of 'albakirky' is '%s'", $str);

			ShowResults($log, 1,0,"cfmgnam", 
				FameHLI::API::Cfmgnam($dbkey, "alias1", $str),
				"Realname of 'alias1' is '%s'", $str);

			ShowResults($log, 0,0,"cfmlsts", 999);	# depricated
			ShowResults($log, 0,0,"cfmnlen", 999);	# depricated

;#		------------------------------------------------------------
my			$testvar = "STRLEN_TEST";
my			$testlen;

			ShowResults($log, 1,0,"cfmnwob(STRLEN)", 
				FameHLI::API::Cfmnwob($dbkey, $testvar,HSERIE,HCASEX, HSTRNG));
			ShowResults($log, 1,0,"cfmgsln", 
				FameHLI::API::Cfmgsln($dbkey, $testvar, $testlen),
				"Length of '$testvar' is $testlen.");
			$testlen = 42;
			ShowResults($log, 1,0,"cfmssln", 
				FameHLI::API::Cfmssln($dbkey, $testvar, $testlen));
			ShowResults($log, 1,0,"cfmgsln", 
				FameHLI::API::Cfmgsln($dbkey, $testvar, $testlen),
				"Length of '$testvar' is $testlen.");

;#		------------------------------------------------------------
			ShowResults($log, 1,0,"cfmgtaso", 
				FameHLI::API::Cfmgtaso($dbkey, $thirdname, $assoc),
				"for $thirdname: <$assoc>");
			ShowResults($log, 1,1,"cfmgtaso(chk str)", 
				$assoc eq "{}", "'$assoc' eq '{}'");
			ShowResults($log, 1,0,"cfmlaso", 
				FameHLI::API::Cfmlaso($dbkey, $thirdname, $len),
				"'%s' is %d long.", $assoc, $len);
			ShowResults($log, 1,1,"cfmgtaso(chk len)", 
				(length($assoc) == $len),
				"'%d' eq '%d'", length($assoc), $len);

			ShowResults($log, 1,0,"cfmsaso", 
				FameHLI::API::Cfmsaso($dbkey, $thirdname, "N_TEST"));
			ShowResults($log, 1,0,"cfmgtaso", 
				FameHLI::API::Cfmgtaso($dbkey, $thirdname, $assoc),
				"for $thirdname: <$assoc>");
			ShowResults($log, 1,1,"cfmgtaso(chk str)", 
				$assoc eq "{N_TEST}", "'$assoc' eq '{N_TEST}'");
			ShowResults($log, 1,0,"cfmlaso", 
				FameHLI::API::Cfmlaso($dbkey, $thirdname, $len),
				"'%s' is %d long.", $assoc, $len);
			ShowResults($log, 1,1,"cfmgtaso(chk len)", 
				(length($assoc) == $len),
				"'%d' eq '%d'", length($assoc), $len);

;#		------------------------------------------------------------

			ShowResults($log, 1,0,"cfmwhat",
				FameHLI::API::Cfmwhat($dbkey, $thirdname,
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
				FameHLI::API::EXT::ClassDesc($class),
				FameHLI::API::EXT::TypeDesc($type),
				FameHLI::API::EXT::BasisDesc($basis),
				FameHLI::API::EXT::FreqDesc($freq),
				FameHLI::API::EXT::ObservedDesc($observ),
				$lyear, $fprd, $lyear, $lprd,
				$cyear, $cmonth, $cday, 
				$myear, $mmonth, $mday,
				$desc, $doc);


		ShowResults($log, 1,0,"cfmcldb", FameHLI::API::Cfmcldb($dbkey));
		ShowResults($log, 1,0,"cfmfin", FameHLI::API::Cfmfin());
}
