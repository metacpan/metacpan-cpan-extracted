#!/usr/bin/perl5
#
# request_tempdyn - Sample request script with a temporary dynamic reply queue
#
# Copyright (c) 2009-2012 Morgan Stanley & Co. Incorporated
#
# $Id: request_permdyn.pl,v 33.4 2012/09/26 16:15:22 jettisu Exp $
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
my $model_qname = 'SYSTEM.ADMIN.PERMDYN.MODEL';
my $dynamic_qname = 'PERL.MQSERIES.REPLY.*'; # But see below

my $qmgr = MQSeries::QueueManager::->
  new('QueueManager' => $qmgr_name,
      'AutoConnect'  => 0) ||
  die "Cannot create MQSeries::QueueManager object";
$qmgr->Connect() ||
  die "Cannot connect to queue manager '$qmgr_name'";

my $request_queue = MQSeries::Queue::->
  new('QueueManager' => $qmgr,
      'Queue'        => $request_qname,
      'Mode'         => 'output') ||
  die "Cannot open request queue $qmgr_name/$request_qname";

#
# The dynamic queue name contains the userid.  For real applications,
# you'd use an application instance specific name, whether that's the
# host, the product, the tarde engine, or whatever.
#
my $userid = ($^O =~ /^MSWin/ ? $ENV{USERNAME} : getpwuid($<));
my $reply_qname = $dynamic_qname;
$reply_qname =~ s/\.\*$/.\U$userid/;
print "Have dynamic reply queue name [$reply_qname]\n";

my $reply_queue = MQSeries::Queue::->
  new('QueueManager' => $qmgr,
      'Queue'        => $model_qname,
      'DynamicQName' => $reply_qname,
      'Mode'         => 'input_exclusive',
      'Carp'         => sub {}, # We print error when required
      'AutoOpen'     => 0,
     );
unless ($reply_queue->Open()) {
    if ($reply_queue->Reason() == 2100) {  # Object already exists
        $reply_queue =  MQSeries::Queue::->
          new('QueueManager' => $qmgr,
              'Queue'        => $reply_qname,
              'DynamicQName' => $reply_qname,
              'Mode'         => 'input_exclusive',
             ) ||
          die "Cannot open reply queue $qmgr_name/$request_qname";
    } else {
        die("Unable to put open model queue $qmgr_name/$model_qname -> $dynamic_qname\n" .
            "Reason = " . $reply_queue->Reason() .
            " (" . MQReasonToText($reply_queue->Reason()) . ")\n");
    }
}

#
# Get any messages left on the reply queue (from a previous run)
#
while (1) {
    my $get_message = MQSeries::Message::->new();
    my $result = $reply_queue->Get('Message' => $get_message);
}

my @correl_ids;
foreach my $counter (1..10) {
    #
    # We specify the report option MQRO_PASS_CORREL_ID purely for
    # demonstration purposes.  Normal apps will not specify anything
    # and use MsgId-to-CorrelId.
    #
    my $put_message = MQSeries::Message::->
      new('MsgDesc' => { 'Format'      => MQSeries::MQFMT_STRING,
                         'ReplyToQ'    => $reply_qname,
                         'Persistence' => 1,
                         'Report'      => MQSeries::MQRO_PASS_CORREL_ID,
                       },
          'Data'    => "Request message $counter for pid $$");
    $request_queue->Put('Message'    => $put_message,
                        'PutMsgOpts' => { Options => MQSeries::MQPMO_NEW_CORREL_ID, },
                       ) ||
      die("Unable to put message\n" .
          "Reason = " . $request_queue->Reason() .
          " (" . MQReasonToText($request_queue->Reason()) . ")\n");
    push @correl_ids, $put_message->MsgDesc('CorrelId');
}
print "Put all messages, start getting replies\n";

foreach my $correl_id (@correl_ids) {
    my $get_message = MQSeries::Message::->
      new(MsgDesc => { 'CorrelId' => $correl_id });
    my $result = $reply_queue->Get('Message' => $get_message,
                                   'Wait'    => '30s',
                                  ) ||
      die("Unable to get message\n" .
          "Reason = " . $reply_queue->Reason() .
          " (" . MQReasonToText($reply_queue->Reason()) . ")\n");

    if ($result == -1) {
        print "No message after 30 seconds\n";
        next;
    }

    my $data = $get_message->Data();
    print "Have reply message data [$data]\n";

    #
    # This sleep simulates work; it's not required for MQSeries
    #
    sleep(1);
}
