#
# $Id: 30basic.t,v 33.11 2012/09/26 16:15:32 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

use strict;
use warnings;

our %myconfig;
our $systemdir;
BEGIN {
    require "../util/parse_config";
}

use Data::Dumper;
use Test::More tests => 18;
BEGIN { 
    our $VERSION = '1.34';
    use_ok('__APITYPE__::MQSeries' => $VERSION); 
}

SKIP: {
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
        skip("Cannot test server API on client host", 17);
    }

    my $QMgrName = $myconfig{"QUEUEMGR"};
    my $QName = $myconfig{"QUEUE"};

    my $CompCode;
    my $Reason;

    print "Connecting to queue manager '$QMgrName' (MQCONN)\n";
    my $Hconn = MQCONN($QMgrName,$CompCode,$Reason);
    if ( $CompCode != MQCC_OK || $Reason != MQRC_NONE ) {
        skip("MQCONN failed: CompCode => $CompCode, Reason => $Reason", 17);
    }
    ok($Hconn, "MQCONN");

    my $Options = MQOO_INQUIRE | MQOO_OUTPUT | MQOO_INPUT_AS_Q_DEF | MQOO_SET;
    my $ObjDesc = {
                   ObjectType           => MQOT_Q,
                   ObjectName           => $QName,
                   ObjectQMgrName       => ""
                  };

    print "Opening queue '$QName' (MQOPEN)\n";
    my $Hobj = MQOPEN($Hconn,$ObjDesc,$Options,$CompCode,$Reason);
    if ( $CompCode != MQCC_OK || $Reason != MQRC_NONE ) {
        skip("MQOPEN failed: CompCode => $CompCode, Reason => $Reason", 16);
    }
    ok($Hobj, "MQOPEN");

    print "Querying several queue attributes (MQINQ)\n";
    my ($MaxMsgLength, $QueueName, $CreationDate, $CreationTime, $MaxQDepth) =
      MQINQ($Hconn,$Hobj,$CompCode,$Reason,
            MQIA_MAX_MSG_LENGTH,
            MQCA_Q_NAME,
            MQCA_CREATION_DATE,
            MQCA_CREATION_TIME,
            MQIA_MAX_Q_DEPTH);
    print("MQINQ returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQINQ");

    print "Putting message (MQPUT)\n";
    my $tempMsg = "Now is the time for all good men to come to the aid of their country.";
    my $MsgDesc = {};
    my $PutMsgOpts = {};
    MQPUT($Hconn,$Hobj,$MsgDesc,$PutMsgOpts,$tempMsg,$CompCode,$Reason);
    print("MQPUT returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQPUT");

    print "Getting message using buffer size 10, failure expected (MQGET)\n";
    $MsgDesc = {};
    my $GetMsgOpts = {};
    my $tempLen = 10;
    $tempMsg = MQGET($Hconn,$Hobj,$MsgDesc,$GetMsgOpts,$tempLen,$CompCode,$Reason);
    print("MQGET returned: CompCode => $CompCode, Reason => $Reason\n");
    ok ($Reason == MQRC_TRUNCATED_MSG_FAILED && $tempMsg eq "Now is the",
        "MQGET should have failed, due to truncation");

    print "Getting message using buffer size 80 (MQGET)\n";
    $MsgDesc = {};
    $GetMsgOpts = {};
    $tempLen = 80;
    $tempMsg = MQGET($Hconn,$Hobj,$MsgDesc,$GetMsgOpts,$tempLen,$CompCode,$Reason);
    print("MQGET returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQGET");

    print "Inhibiting Get and setting Trigger Data (MQSET)\n";
    MQSET($Hconn,$Hobj,$CompCode,$Reason,MQIA_INHIBIT_GET,MQQA_GET_INHIBITED,MQCA_TRIGGER_DATA,"bogusdata");
    print("MQSET returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQSET");

    print "Inquiring Inhibit Get and Trigger Data (MQINQ)\n";
    my ($inhibitGet,$trigData) = MQINQ($Hconn,$Hobj,$CompCode,$Reason,MQIA_INHIBIT_GET,MQCA_TRIGGER_DATA);
    print("MQINQ returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQINQ");
    like ($trigData, qr/^bogusdata\s*$/, "MQINQ - trigger data");

    print "Uninhibiting Get and clearing Trigger Data (MQSET)\n";
    MQSET($Hconn,$Hobj,$CompCode,$Reason,MQIA_INHIBIT_GET,MQQA_GET_ALLOWED,MQCA_TRIGGER_DATA,"");
    print("MQSET returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQSET");

    print "Inquiring Inhibit Get and Trigger Data (MQINQ)\n";
    ($inhibitGet,$trigData) = MQINQ($Hconn,$Hobj,$CompCode,$Reason,MQIA_INHIBIT_GET,MQCA_TRIGGER_DATA);
    print("MQINQ returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQINQ");

    print "Closing queue (MQCLOSE)\n";
    MQCLOSE($Hconn,$Hobj,MQCO_NONE,$CompCode,$Reason);
    print("MQCLOSE returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQCLOSE");

    print "Putting message to queue (MQPUT1)\n";
    $ObjDesc = {
                ObjectType      => MQOT_Q,
                ObjectName      => $QName,
                ObjectQMgrName  => "",
               };
    $MsgDesc = {};
    $PutMsgOpts = {};
    $tempMsg = "This msg was put with PERLMQ's MQPUT1 function.";
    MQPUT1($Hconn,$ObjDesc,$MsgDesc,$PutMsgOpts,$tempMsg,$CompCode,$Reason);
    print("MQPUT1 returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQPUT1");

    print "Opening queue (MQOPEN)\n";
    $ObjDesc = {
                ObjectType     => MQOT_Q,
                ObjectName     => $QName,
                ObjectQMgrName => ""
               };
    $Hobj = MQOPEN($Hconn,$ObjDesc,MQOO_INPUT_AS_Q_DEF,$CompCode,$Reason);
    print("MQOPEN returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQOPEN");

    print "Getting message (MQGET)\n";
    $MsgDesc = {};
    $GetMsgOpts = {};
    $tempLen = 80;
    $tempMsg = MQGET($Hconn,$Hobj,$MsgDesc,$GetMsgOpts,$tempLen,$CompCode,$Reason);
    print("MQGET returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQGET");

    print "Closing queue (MQCLOSE)\n";
    MQCLOSE($Hconn,$Hobj,MQCO_NONE,$CompCode,$Reason);
    print("MQCLOSE returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQCLOSE");

    print "Disconnecting (MQDISC)\n";
    MQDISC($Hconn,$CompCode,$Reason);
    print("MQDISC returned: CompCode => $CompCode, Reason => $Reason\n");
    ok( $CompCode == MQCC_OK && $Reason == MQRC_NONE, "MQDISC");
}
