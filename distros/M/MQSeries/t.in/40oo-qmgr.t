#
# $Id: 40oo-qmgr.t,v 33.10 2012/09/26 16:15:33 jettisu Exp $
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
use Test::More tests => 14;
BEGIN {
    our $VERSION = '1.34';
    use_ok('__APITYPE__::MQSeries' => $VERSION);
    use_ok('MQSeries::QueueManager' => $VERSION);
}

SKIP: {
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
        skip("Cannot test server API on client host", 12);
    }

    my $QMgrName = $myconfig{"QUEUEMGR"};

    #
    # First test the most basic instantiation.
    #
    # NOTE: This is in a block to allow for automatic destruction
    #
    {
        my $qmgr = MQSeries::QueueManager->new(QueueManager => $QMgrName);
        ok (ref $qmgr && $qmgr->isa("MQSeries::QueueManager"),
            "MQSeries::QueueManager - constructor");
    }

    #
    # Test the AutoConnect mechanism
    #
    {
        my $qmgr = MQSeries::QueueManager->new(QueueManager => $QMgrName,
                                               AutoConnect  => 0);
        ok (ref $qmgr && $qmgr->isa("MQSeries::QueueManager"),
            "MQSeries::QueueManager - constructor - AutoConnect=0");

        my $rc = $qmgr->Connect();
        unless ($rc) {
            print("MQSeries::QueueManager->Connect() failed.\n" .
                  "CompCode => " . $qmgr->CompCode() . "\n" .
                  "Reason   => " . $qmgr->Reason() . "\n");
        }
        ok($rc, "MQSeries::QueueManager - Connect");

        $rc = $qmgr->Disconnect();
        unless ($rc) {
            print("MQSeries::QueueManager->DisConnect() failed.\n" .
                  "CompCode => " . $qmgr->CompCode() . "\n" .
                  "Reason   => " . $qmgr->Reason() . "\n");
        }
        ok($rc, "MQSeries::QueueManager - Disconnect");
    }

    #
    # Test Open/Inquire/Close
    #
    {
        my $qmgr = MQSeries::QueueManager->new(QueueManager => $QMgrName);
        ok (ref $qmgr && $qmgr->isa("MQSeries::QueueManager"),
            "MQSeries::QueueManager - constructor");

        my $rc = $qmgr->Open();
        unless ($rc) {
            print("MQSeries::QueueManager->Open() failed.\n" .
                  "CompCode => " . $qmgr->CompCode() . "\n" .
                  "Reason   => " . $qmgr->Reason() . "\n");
        }
        ok($rc, "MQSeries::QueueManager - Open");

        my %qmgr_attr = $qmgr->Inquire(qw(Platform
                                          CodedCharSetId
                                          CommandLevel
                                          DeadLetterQName));
        is (scalar(keys %qmgr_attr), 4, "MQSeries::QueueManager - Inquire");

        like($qmgr_attr{Platform}, qr/^\w+$/,
             "MQSeries::QueueManager - Inquire - Platform");
        like($qmgr_attr{CodedCharSetId}, qr/^\d+$/,
             "MQSeries::QueueManager - Inquire - CodedCharSetId");
        like($qmgr_attr{CommandLevel}, qr/^\d+$/,
             "MQSeries::QueueManager - Inquire - CommandLevel");
        like($qmgr_attr{DeadLetterQName}, qr/^[\w\.\s]+$/,
             "MQSeries::QueueManager - Inquire - DeadLetterQName");

        $rc = $qmgr->Close();
        unless ($rc) {
            print("MQSeries::QueueManager->Close() failed.\n" .
                  "CompCode => " . $qmgr->CompCode() . "\n" .
                  "Reason   => " . $qmgr->Reason() . "\n");
        }
        ok($rc, "MQSeries::QueueManager - Close");
    }
}
