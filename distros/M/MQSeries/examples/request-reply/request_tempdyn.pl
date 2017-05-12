#!/usr/bin/perl5
#
# request_tempdyn - Sample request script with a temporary dynamic reply queue
#
# Copyright (c) 2009-2012 Morgan Stanley & Co. Incorporated
#
# $Id: request_tempdyn.pl,v 33.4 2012/09/26 16:15:23 jettisu Exp $
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
my $model_qname = 'SYSTEM.ADMIN.TEMPDYN.MODEL';
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

my $reply_queue =  MQSeries::Queue::->
  new('QueueManager' => $qmgr,
      'Queue'        => $model_qname,
      'DynamicQName' => $dynamic_qname,
      'Mode'         => 'input_exclusive') ||
  die "Cannot open model queue $qmgr_name/$model_qname";
my $reply_qname = $reply_queue->ObjDesc('ObjectName');
print "Have dynamic reply queue name [$reply_qname]\n";

foreach my $counter (1..10) {
    my $put_message = MQSeries::Message::->
      new('MsgDesc' => { 'Format'      => MQSeries::MQFMT_STRING,
                         'ReplyToQ'    => $reply_qname,
                         'Expiry'      => '30s',
                         'Persistence' => 0,
                       },
          'Data'    => "Request message $counter for pid $$");
    $request_queue->Put('Message' => $put_message) ||
      die("Unable to put message\n" .
          "Reason = " . $request_queue->Reason() .
          " (" . MQReasonToText($request_queue->Reason()) . ")\n");

    #
    # Private reply queue: no need to get by correl id
    #
    my $get_message = MQSeries::Message::->new();
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
