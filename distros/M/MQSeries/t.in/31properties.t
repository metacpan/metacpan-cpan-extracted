#
# $Id: 31properties.t,v 33.11 2012/09/26 16:15:33 jettisu Exp $
#
# (c) 2009-2012 Morgan Stanley & Co. Incorporated
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
use Test::More tests => 22;
BEGIN { 
    our $VERSION = '1.34';
    use_ok('__APITYPE__::MQSeries' => $VERSION); 
}

SKIP: {
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
        skip("Cannot test server API on client host", 21);
    }

    if ($MQSeries::MQ_VERSION < 7) {
        skip("Module not compiled for MQSeries version 7", 21);
    }

    my $qmgr_name = $myconfig{"QUEUEMGR"};
    my $qname = $myconfig{"QUEUE"};
    my ($compcode, $reason);

    print "Connecting to queue manager '$qmgr_name' (MQCONN)\n";
    my $Hconn = MQCONN($qmgr_name,$compcode,$reason);
    if ($compcode != MQCC_OK || $reason != MQRC_NONE ) {
        skip("MQCONN failed: CompCode => $compcode, Reason => $reason", 21);
    }
    ok(1, "MQCONN");

    print "Opening queue manager for inquire\n";
    my $options = MQOO_INQUIRE;
    my $obj_desc = { ObjectType => MQOT_Q_MGR , };
    my $Hobj = MQOPEN($Hconn,$obj_desc,$options,$compcode,$reason);
    if ($compcode != MQCC_OK || $reason != MQRC_NONE) {
        skip("MQOPEN of queue manager failed: CompCode => $compcode, Reason => $reason", 20);
    }
    ok($Hobj, "MQOPEN - queue manager");

    print "Querying queue manager attributes (MQINQ)\n";
    my ($cmd_level) = MQINQ($Hconn,$Hobj,$compcode,$reason,
                            MQIA_COMMAND_LEVEL);
    if ($compcode != MQCC_OK || $reason != MQRC_NONE ) {
        skip("MQINQ failed: CompCode => $compcode, Reason => $reason", 19);
    }
    ok(1, "MQINQ");

    if ($cmd_level < 700) {
        skip("Queue Manager not running MQ v7 (CommandLevel => $cmd_level)", 18);
    }

    print "Closing queue manager object handle (MQCLOSE)\n";
    MQCLOSE($Hconn,$Hobj,MQCO_NONE,$compcode,$reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQCLOSE - queue manager");

    $options = MQOO_OUTPUT | MQOO_INPUT_AS_Q_DEF;
    $obj_desc = { ObjectType     => MQOT_Q,
                  ObjectName     => $qname,
                  ObjectQMgrName => ""
                };

    print "Create message handle object (MQCRTMH)\n";
    my $Hmsg = MQCRTMH($Hconn, {}, $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQCRTMH");
    if ($compcode != MQCC_OK || $reason != MQRC_NONE) {
        skip("MQCRTMH failed: CompCode => $compcode, Reason => $reason", 16);
    }

    print "Set message property (MQSETMP - string)\n";
    MQSETMP($Hconn, $Hmsg, {},
            "perl.MQSeries.test.string", {}, MQTYPE_STRING,
            "Valuable", $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQSETMP - string");

    print "Set message property (MQSETMP - float)\n";
    MQSETMP($Hconn, $Hmsg, {},
            "perl.MQSeries.test.float", {}, MQTYPE_FLOAT32,
            3.14165, $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQSETMP - float");

    print "Set message property (MQSETMP - int)\n";
    MQSETMP($Hconn, $Hmsg, {},
            "perl.MQSeries.test.int", {}, MQTYPE_INT16,
            42, $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQSETMP - int");

    print "Inquire message property (MQINQMP - float)\n";
    my $type = MQTYPE_FLOAT32;
    my $len = 400;
    my $inq_opts =  { Options => MQIMPO_CONVERT_TYPE, };
    my $prop_desc = {};
    my $prop = MQINQMP($Hconn, $Hmsg, $inq_opts,
                       "perl.MQSeries.test.float", $prop_desc, $type, $len,
                       $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQINQMP - float");
    ok(abs($prop - 3.14165) < 0.01, "MQINQMP - float value okay ($prop)");

    print "Delete float property\n";
    MQDLTMP($Hconn, $Hmsg, {}, "perl.MQSeries.test.float", $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQDLTMP - float");

    print "Opening queue '$qname' (MQOPEN)\n";
    $Hobj = MQOPEN($Hconn,$obj_desc,$options,$compcode,$reason);
    if ($compcode != MQCC_OK || $reason != MQRC_NONE) {
        skip("MQOPEN of queue failed: CompCode => $compcode, Reason => $reason", 10);
    }
    ok($Hobj, "MQOPEN - queue");

    print "Putting message with properties (MQPUT)\n";
    my $buffer = "Sample message data";
    my $msg_desc = {};
    my $put_msg_opts =  { Version           => MQPMO_VERSION_3,
                          OriginalMsgHandle => $Hmsg,
                        };
    MQPUT($Hconn,$Hobj,$msg_desc,$put_msg_opts,$buffer,$compcode,$reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQPUT");

    print "Create message handle object (MQCRTMH #2)\n";
    my $Hmsg2 = MQCRTMH($Hconn, {}, $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQCRTMH #2");
    if ($compcode != MQCC_OK || $reason != MQRC_NONE) {
        skip("MQCRTMH failed: CompCode => $compcode, Reason => $reason", 7);
    }

    print "Getting message (MQGET)\n";
    $msg_desc = {};
    my $get_msg_opts = { Version   => MQGMO_VERSION_4,
                         MsgHandle => $Hmsg2,
                       };
    $len = 1024;
    my $msg_read = MQGET($Hconn, $Hobj, $msg_desc, $get_msg_opts, $len,
                         $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQGET");

    print "Inquire message property (MQINQMP - int)\n";
    $type = MQTYPE_INT32;
    $len = 4;
    $inq_opts =  { Options => MQIMPO_CONVERT_TYPE, };
    $prop_desc = {};
    $prop = MQINQMP($Hconn, $Hmsg2, $inq_opts,
                    "perl.MQSeries.test.int", $prop_desc, $type, $len,
                    $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQINQMP - int");
    is($prop, 42, "MQINQMP - int value okay ($prop)");

    print "Delete message handle (MQDLTMH)\n";
    MQDLTMH($Hconn, $Hmsg, {}, $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQDLTMH");

    print "Delete message handle (MQDLTMH #2)\n";
    MQDLTMH($Hconn, $Hmsg2, {}, $compcode, $reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQDLTMH #2");

    print "Closing queue (MQCLOSE)\n";
    MQCLOSE($Hconn,$Hobj,MQCO_NONE,$compcode,$reason);
    ok ($compcode == MQCC_OK && $reason == MQRC_NONE, "MQCLOSE");

    print "Disconnecting (MQDISC)\n";
    MQDISC($Hconn,$compcode,$reason);
    ok ($compcode == MQCC_OK && $reason == MQRC_NONE, "MQDISC");
}


