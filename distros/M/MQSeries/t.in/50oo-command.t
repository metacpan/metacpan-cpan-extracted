#
# $Id: 50oo-command.t,v 36.7 2012/09/26 16:15:34 jettisu Exp $
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
use Test::More tests => 32;
BEGIN {
    our $VERSION = '1.34';
    use_ok('__APITYPE__::MQSeries' => $VERSION);
    use_ok('MQSeries::QueueManager' => $VERSION);
    use_ok('MQSeries::Command' => $VERSION);
}

SKIP: {
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
        skip("Cannot test server API on client host", 29);
    }

    #
    # We'll only test MQSeries::Command if we run as user 'mqm'
    #
    my $username = ($^O =~ /^MSWin/ ? $ENV{USERNAME} : getpwuid($<));
    unless (lc $username eq 'mqm') {
        skip("Not testing MQSeries::Command unless running as user 'mqm', not '$username'", 29);
    }

    my $QMgrName = $myconfig{"QUEUEMGR"};

    #
    # Create QueueManager object and connect
    #
    my $qmgr_obj = MQSeries::QueueManager->
      new('QueueManager' => $QMgrName,
          'AutoConnect'  => 0);
    unless ($qmgr_obj->Connect()) {
        skip("MQSeries::QueueManager Connect failed (Reason=" .
             $qmgr_obj->Reason() . ")", 28);
    }
    ok($qmgr_obj, "MQSeries::QueueManager - Connect");

    #
    # Inquire the platform.  Skip the tests if we're not on Unix.
    #
    my $rc = $qmgr_obj->Open();
    unless ($rc) {
	skip("Could not open queue manager", 27);
    }
    ok($rc, "MQSeries::QueueManager - Open");
    my %qmgr_attr = $qmgr_obj->Inquire('Platform');
    ok((keys %qmgr_attr), "MQSeries::QueueManager - Inquire");
    $rc = $qmgr_obj->Close();
    ok($rc, "MQSeries::QueueManager - Close");

    unless ($qmgr_attr{Platform} eq 'UNIX') {
	skip("Not testing MQSeries::Command on non-Unix platform $qmgr_attr{Platform}", 24);
    }

    #
    # Start with inquire commands for all object types
    #
    my $cmd = MQSeries::Command::->new('QueueManager' => $qmgr_obj,
                                       'Type'         => 'PCF');
    unless (defined $cmd) {
        skip("MQSeries::Command constructor failed", 24);
    }
    ok($cmd, "MQSeries::Command constructor");

    #
    # Use 'InquireQueueManager' to get queue manager information.  We
    # retain this, as we need the command level later to test MQ v6
    # and MQ v7 specific commands.
    #
    my $qmgr_info = $cmd->InquireQueueManager();
    ok($qmgr_info, "InquireQueueManager - All");

    #
    # Starting with MQ v6, you can ask for groups of attributes
    # other than 'All'.  Starting with MQ v7, the group 'pub/sub
    # attributes' was added.
    #
    foreach my $group (qw(ClusterAttrs
                          DistributedQueueingAttrs
                          EventAttrs
                          SystemAttrs
                          PubSubAttrs)) {
      SKIP: {
            if ($qmgr_info->{CommandLevel} < 600) {
                skip("InquireQueueManager - $group not supported for MQ < v6", 1);
            }
            if ($group eq 'PubSubAttrs' && $qmgr_info->{CommandLevel} < 700) {
                skip("InquireQueueManager - $group not supported for MQ < v7", 1);
            }
            my $group_info = $cmd->InquireQueueManager(QMgrAttrs => [ $group ]);
            ok($group_info, "InquireQueueManager - $group");
        }
    }

  SKIP: {
        #
        # Use the 'InquireQueueManagerStatus' command
        #
        if ($qmgr_info->{CommandLevel} >= 600) {
            my $qmgr_status = $cmd->InquireQueueManagerStatus();
            ok($qmgr_status, "InquireQueueManagerStatus");
        } else {
            skip("InquireQueueManagerStatus not supported on MQ < v6", 1);
        }
    }

    #
    # Test Inquire XXX Names and Inquire XXX for all object types
    #
    foreach my $type (qw(Queue Channel Process
                         AuthInfo Namelist
                         Subscription Topic)) {
      SKIP: {
            if ($qmgr_info->{CommandLevel} < 600 &&
                ($type eq 'AuthInfo' || $type eq 'Namelist')) {
                skip("Inquire $type Names - not supported for MQ < v6", 2);
            }
            if ($qmgr_info->{CommandLevel} < 700 &&
                ($type eq 'Subscription' || $type eq 'Topic')) {
                skip("Inquire $type Names - not supported for MQ < v7", 2);
            }

            if ($type ne 'Subscription') {  # No Inquire Subscription Names
                my $method = 'Inquire' . $type . 'Names';
                my @names = $cmd->$method();
                ok(@names, "Inquire $type Names");
            }
            else {
                my @names = ({});
                ok(@names, "Inquire $type Names (not supported)");
            }

            my $method = 'Inquire' . $type;
            my @objects = $cmd->$method();
            ok(@objects, "Inquire $type");
        }
    }

    #
    # Test Inquire XXX Status for supported object types
    #
    foreach my $type (qw(Channel Subscription Topic)) {
      SKIP: {
            if ($qmgr_info->{CommandLevel} < 700 &&
                ($type eq 'Subscription' || $type eq 'Topic')) {
                skip("Inquire $type Status - not supported for MQ < v7", 1);
            }
            my $method = 'Inquire' . $type . 'Status';
            my @status = $cmd->$method();

            #
            # If we're using the Server API, and no client channels
            # are in use, InquireChannelStatus can return nothing.
            #
            if (@status == 0 && $type eq 'Channel' &&
                "__APITYPE__" eq "MQServer") {
                @status = ( {} );  # Fake it to make test succeed
            }

            ok(@status, "Inquire $type Status");
        }
    }
}
