#
# $Id: 20convert.t,v 33.9 2012/09/26 16:15:32 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

BEGIN {
    require "../util/parse_config";
}

BEGIN {
    $| = 1;
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
	print "1..0\n";
	exit 0;
    } else {
	print "1..6\n";
    }
}

END {print "not ok 1\n" unless $loaded;}
use __APITYPE__::MQSeries 1.34;
$loaded = 1;
print "ok 1\n";

#
# These values will be replaced by those specified in the CONFIG file.
#
$QMgrName 	= $myconfig{"QUEUEMGR"};
$QName 		= $myconfig{"QUEUE"};

$Hconn 		= MQHC_UNUSABLE_HCONN;
$CompCode 	= 0;
$Reason 	= 0;

$Hconn = MQCONN($QMgrName, $CompCode, $Reason);
if ( $CompCode != MQCC_OK || $Reason != MQRC_NONE ) {
    print "MQCONN failed: CompCode => $CompCode, Reason => $Reason\n";
    print "not ok 2\n";
    exit 0;
} else {
    print "ok 2\n";
}

#
# Do a MQPUT1 of a message in ebcdic:
#
$ebcdic = "\xE3\x88\x89\xA2\x40\x94\xA2\x87\x40\x89\xA2\x40\x89\x95\x40\xC5\xC2\xC3\xC4\xC9\xC3";
$ascii  = "This msg is in EBCDIC";
$ObjDesc = {
	    ObjectName       	=> $QName,
	    ObjectQMgrName	=> "",
	   };
$MsgDesc = {
	    Format		=> MQFMT_STRING,
	    CodedCharSetId	=> 500,
	   };
$PutMsgOpts = {};
MQPUT1($Hconn, $ObjDesc, $MsgDesc, $PutMsgOpts, $ebcdic, $CompCode, $Reason);
if ( $CompCode != MQCC_OK || $Reason != MQRC_NONE ) {
    print "MQPUT1 failed: CompCode => $CompCode, Reason => $Reason\n";
    print "not ok 3\n";
} else {
    print "ok 3\n";
}

$Hobj = MQOPEN($Hconn, $ObjDesc, MQOO_INPUT_SHARED, $CompCode, $Reason);
if ( $CompCode != MQCC_OK || $Reason != MQRC_NONE ) {
    print "MQOPEN failed: CompCode => $CompCode, Reason => $Reason\n";
    print "not ok 4\n";
} else {
    print "ok 4\n";
}

$MsgDesc = { CodedCharSetId => 819 };
$GetMsgOpts = { Options => MQGMO_NO_WAIT | MQGMO_CONVERT };
$length = 1000;
$msg = MQGET($Hconn, $Hobj, $MsgDesc, $GetMsgOpts, $length, $CompCode, $Reason);
if ( $CompCode != MQCC_OK || $Reason != MQRC_NONE ) {
    print "MQGET failed: CompCode => $CompCode, Reason => $Reason\n";
    print "not ok 5\n";
    $msg = "";			# defeats -w

} else {
    print "ok 5\n";
}

#
# This is the *key* test -- did the conversion work correctly.
#
if ( $msg ne $ascii ) {
    print "Message conversion failed.\n";
    print "Should be: '$ascii'\n";
    print "Is:        '$msg'\n";
    print "not ok 6\n";
} else {
    print "ok 6\n";
}



