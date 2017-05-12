#!/usr/bin/perl
#
# server - Sample server script for request/reply examples
#
# Copyright (c) 2009-2012 Morgan Stanley & Co. Incorporated
#
# $Id: server.pl,v 33.4 2012/09/26 16:15:23 jettisu Exp $
#

use strict;
use warnings;

use MQSeries qw(:functions);
use MQSeries::QueueManager;
use MQSeries::Queue;
use MQSeries::Message;

#
# Hardcoded config
#
my $qmgr_name = 'SOME.QMGR';
my $request_qname = 'PERL.MQSERIES.REQUEST';
my $error_qname = 'PERL.MQSERIES.ERROR';
my $max_backout_count = 10;

#
# Connect to the queue manager, open the request and errors queues,
# then we can get going
#
my $qmgr = MQSeries::QueueManager::->
  new('QueueManager' => $qmgr_name,
      'AutoConnect'  => 0) ||
  die "Cannot create MQSeries::QueueManager object";
$qmgr->Connect() ||
  die "Cannot connect to queue manager '$qmgr_name'";

my $request_queue = MQSeries::Queue::->
  new('QueueManager' => $qmgr,
      'Queue'        => $request_qname,
      'AutoOpen'     => 0,
      'Mode'         => 'input') ||
  die "Cannot create MQSeries::Queue object\n";
$request_queue->Open() ||
  die "Cannot open queue $qmgr_name/$request_qname for input";

my $error_queue = MQSeries::Queue::->
  new('QueueManager' => $qmgr,
      'Queue'        => $error_qname,
      'AutoOpen'     => 0,
      'Mode'         => 'output') ||
  die "Cannot create MQSeries::Queue object\n";
$request_queue->Open() ||
  die "Cannot open queue $qmgr_name/$error_qname for output";

#
# Shut down cleanly (after a message has been handled and
# comitted) when SIGQUIT is sent.
#
my $quit_received = 0;
$SIG{QUIT} = sub {
    #print STDERR "XXX:Process $$ received SIGQUIT at " .
    #  localtime(time) . "\n";
    $quit_received = 1;
};

my $sync_flag = 0;
my $outcome;
while (1) {
    $sync_flag = 0;
    undef $outcome;
    my $request_msg = MQSeries::Message::->new();
    my $status = $request_queue->
      Get('Message'       => $request_msg,
          'GetMsgOpts' =>
          {
           'WaitInterval' => 5000,  # 5 seconds
           'Options'      => (MQSeries::MQGMO_WAIT |
                              MQSeries::MQGMO_SYNCPOINT_IF_PERSISTENT |
                              MQSeries::MQGMO_CONVERT |
                              MQSeries::MQGMO_FAIL_IF_QUIESCING),
          },
         );
    unless ($status) {  # Error
        my $rc = $request_queue->Reason();
        die "Error on 'Get' from queue $qmgr_name/$request_qname:\n" .
          "\tReason: $rc (" . MQReasonToText($rc). ")\n";
    }
    next if ($status < 0);      # No message available

    $sync_flag = ($request_msg->MsgDesc('Persistence') ? 1 : 0);

    #
    # Handle messages backed out too often (poison messages)
    #
    if ($request_msg->MsgDesc('BackoutCount') > 10) {
        warn localtime() . ": Message on request queue $qmgr_name/$request_qname has BackountCount " . $request_msg->MsgDesc('BackoutCount') . " - moving to Error Queue $qmgr_name/$error_qname\n";
        $outcome = 'Error';
    } else {
        #
        # We invoke a message callback to do the actual work
        #
        my ($reply_data, $reply_msg_flags);
        ($outcome, $reply_data, $reply_msg_flags) =
          message_callback($request_msg->Data(),
                           { %{ $request_msg->MsgDesc() } });
        die "Invalid outcome '$outcome'"
          unless ($outcome =~ m!^(Commit|Backout|Error)$!);
        $reply_msg_flags ||= {};

        if ($outcome eq 'Commit' && defined $reply_data) {
            #
            # Build up the reply message headers.  We assume the
            # MQRO_COPY_MSG_ID_TO_CORRELID protocol, but allow the
            # message id / correl id to be passed back if requested.
            #
            my $msgdesc = { Format      => MQSeries::MQFMT_NONE,
                            MessageType => MQSeries::MQMT_REPLY,
                            CorrelId    => $request_msg->MsgDesc('MsgId'),
                            Persistence => $request_msg->MsgDesc('Persistence'),
                            Expiry      => $request_msg->MsgDesc('Expiry'),
                            Priority    => $request_msg->MsgDesc('Priority'),
                          };
            if ($request_msg->MsgDesc('Report') & MQSeries::MQRO_PASS_MSG_ID) {
                $msgdesc->{MsgId} = $request_msg->MsgDesc('MsgId');
            }
            if ($request_msg->MsgDesc('Report') & MQSeries::MQRO_PASS_CORREL_ID) {
                $msgdesc->{CorrelId} = $request_msg->MsgDesc('CorrelId');
            }
            while (my ($key, $value) = each %$reply_msg_flags) {  # From callback
                $msgdesc->{$key} = $value;
            }
            my $reply_msg = MQSeries::Message::->
              new('MsgDesc' => $msgdesc,
                  'Data'    => $reply_data,
                 );

            $status = $qmgr->
              Put1(Message      => $reply_msg,
                   QueueManager => $request_msg->MsgDesc('ReplyToQMgr'),
                   Queue        => $request_msg->MsgDesc('ReplyToQ'),
                   Sync         => $sync_flag,
                  );
            unless ($status) {
                my $rc = $qmgr->Reason();
                my $dest_qname = $request_msg->MsgDesc('ReplyToQMgr') . '/' .  $request_msg->MsgDesc('ReplyToQ');
            my $errmsg = "Cannot perform Put1 on queue manager $qmgr_name and reply queue $dest_qname\n" .
              "\tReason: $rc (" . MQReasonToText($rc) . ")\n";
                if ($rc == MQSeries::MQRC_UNKNOWN_OBJECT_NAME ||
                    $rc == MQSeries::MQRC_NOT_AUTHORIZED) {
                    #
                    # If the reply-to qmgr/queue is an invalid object
                    # name or does not grant permission, that is a
                    # client-side bug and should not cause the server
                    # to die.
                    #
                    $errmsg .= "(Ignoring error and continuing)\n";
                    warn $errmsg;
                } else {
                    die $errmsg;
                }
            }
        }                       # End if: commit & have reply data
    }                           # End if: poison message / callback

    #
    # The 'Error' outcome can be from a poison message or from the callback
    #
    if ($outcome eq 'Error') {
        print "Moving message to error queue\n";
        $status = $error_queue->Put('Message' => $request_msg,
                                    'Sync'    => $sync_flag,
                                   );
        unless ($status) {
            my $rc = $error_queue->Reason();
            die "Cannot put message on error queue $qmgr_name/$error_qname\n" .
              "\tReason: $rc (" . MQReasonToText($rc) . ")\n";
        }
    }
} continue {
    #
    # We want to commit/backout if the request message was read under
    # syncpoint
    #
    if ($sync_flag) {
        my $method = ($outcome eq 'Backout' ? 'Backout' : 'Commit');
        my $status = $qmgr->$method();
        unless ($status) {
            my $rc = $qmgr->Reason();
            die "Cannot $method on queue manager $qmgr_name\n" .
              "\tReason: $rc (" . MQReasonToText($rc) . ")\n";
        }
    }

    #
    # Exit outer loop if SIGQUIT received
    #
    last if ($quit_received);
}

exit(0);


# ------------------------------------------------------------------------

#
# The message call back routine.  In a real server, this does real
# work - read/write files, do database work, print a check, perform a
# trade, whatever.  We do little more than echo the request message.
#
# The callback receives:
# - Data: message data
# - MsgDesc: message descriptor
# It returns:
# - Commit/Backout/Error
# - Reply Data (no reply is sent if udef)
# - Reply MsgDesc fields (optional, hash reference)
#
sub message_callback {
    my ($data, $msg_desc) = @_;

    return ('Commit', "Reply data for '$data'");
}
