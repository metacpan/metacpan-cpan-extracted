#
# $Id: 32async_put.t,v 36.7 2012/09/26 16:15:33 jettisu Exp $
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
use Test::More tests => 25;
BEGIN { 
    our $VERSION = '1.34';
    use_ok('__APITYPE__::MQSeries' => $VERSION); 
}

SKIP: {
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
        skip("Cannot test server API on client host", 24);
    }

    if ($MQSeries::MQ_VERSION < 7) {
        skip("Module not compiled for MQSeries version 7", 24);
    }

    my $qmgr_name = $myconfig{"QUEUEMGR"};
    my $qname = $myconfig{"QUEUE"};
    my ($compcode, $reason);

    print "Connecting to queue manager '$qmgr_name' (MQCONN)\n";
    my $Hconn = MQCONN($qmgr_name,$compcode,$reason);
    if ($compcode != MQCC_OK || $reason != MQRC_NONE ) {
        skip("MQCONN failed: CompCode => $compcode, Reason => $reason", 24);
    }
    ok(1, "MQCONN");

    print "Opening queue manager for inquire\n";
    my $options = MQOO_INQUIRE;
    my $obj_desc = { ObjectType => MQOT_Q_MGR , };
    my $Hobj = MQOPEN($Hconn,$obj_desc,$options,$compcode,$reason);
    if ($compcode != MQCC_OK || $reason != MQRC_NONE) {
        skip("MQOPEN of queue manager failed: CompCode => $compcode, Reason => $reason", 23);
    }
    ok($Hobj, "MQOPEN - queue manager");

    print "Querying queue manager attributes (MQINQ)\n";
    my ($cmd_level) = MQINQ($Hconn,$Hobj,$compcode,$reason,
                            MQIA_COMMAND_LEVEL);
    print("MQINQ returned: CompCode => $compcode, Reason => $reason\n");
    if ($compcode != MQCC_OK || $reason != MQRC_NONE ) {
        skip("MQINQ failed: CompCode => $compcode, Reason => $reason", 22);
    }
    ok(1, "MQINQ");

    if ($cmd_level < 700) {
        skip("Queue Manager not running MQ v7 (CommandLevel => $cmd_level)", 21);
    }

    print "Closing queue manager object handle (MQCLOSE)\n";
    MQCLOSE($Hconn,$Hobj,MQCO_NONE,$compcode,$reason);
    ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQCLOSE - queue manager");

    $options = MQOO_INQUIRE | MQOO_OUTPUT | MQOO_INPUT_AS_Q_DEF;
    $obj_desc = { ObjectType     => MQOT_Q,
                  ObjectName     => $qname,
		  ObjectQMgrName => ""
                };

    print "Opening queue '$qname' (MQOPEN)\n";
    $Hobj = MQOPEN($Hconn,$obj_desc,$options,$compcode,$reason);
    if ($compcode != MQCC_OK || $reason != MQRC_NONE) {
        skip("MQOPEN of queue failed: CompCode => $compcode, Reason => $reason", 20);
    }
    ok($Hobj, "MQOPEN - queue");

    foreach my $counter (1..5) {
        print "Putting message #$counter (async MQPUT)\n";
        my $buffer = "Async message $counter";
        my $msg_desc = {};
        my $put_msg_opts = { Options => MQPMO_ASYNC_RESPONSE, };
        MQPUT($Hconn,$Hobj,$msg_desc,$put_msg_opts,$buffer,$compcode,$reason);
        ok ($compcode == MQCC_OK && $reason == MQRC_NONE,
            "MQPUT - $counter");
    }

    #
    # XXX: Note that MQSTAT() is a new MQI call introduced with
    # version 7 and that this test code was last updated when the value for
    # MQSTS_CURRENT_VERSION was 2.  If you have a different value for
    # this (look in cmqc.h), this test will likely fail.
    #
    print "Getting status info (MQSTAT)\n";
    my $stats = {};
    MQSTAT($Hconn,MQSTAT_TYPE_ASYNC_ERROR,$stats,$compcode,$reason);
    ok ($compcode == MQCC_OK && $reason == MQRC_NONE, "MQSTAT");
    my $expected = { 'ResolvedQMgrName' => '',
                     'PutSuccessCount' => 0,
                     'ObjectQMgrName' => '',
                     'PutFailureCount' => 0,
                     'ObjectName' => '',
                     'Reason' => 0,
                     'Version' => 1,
                     'CompCode' => 0,
                     'PutWarningCount' => 0,
                     'ResolvedObjectName' => '',
                     'ObjectType' => 1,
                     # starting with 7.0.1.0, MQSTS_CURRENT_VERSION == 2
                     'OpenOptions' => '0',
                     'SubOptions' => '0',
                     'ObjectString' => '',
                     'SubName' => '',
                   };
    is_deeply($stats, $expected, "MQSTAT result");

    foreach my $counter (1..5) {
        print "Getting message #$counter (MQGET)\n";
        my $msg_desc = {};
        my $get_msg_opts = {};
        my $msg_len = 1024;
        my $msg_data = MQGET($Hconn,$Hobj,$msg_desc,$get_msg_opts,$msg_len,$compcode,$reason);
        ok($compcode == MQCC_OK && $reason == MQRC_NONE, "MQGET - $counter");
        is($msg_data, "Async message $counter", "MQGET message content - $counter");
    }

    print "Closing queue (MQCLOSE)\n";
    MQCLOSE($Hconn,$Hobj,MQCO_NONE,$compcode,$reason);
    ok ($compcode == MQCC_OK && $reason == MQRC_NONE, "MQCLOSE");

    print "Disconnecting (MQDISC)\n";
    MQDISC($Hconn,$compcode,$reason);
    ok ($compcode == MQCC_OK && $reason == MQRC_NONE, "MQDISC");
}


