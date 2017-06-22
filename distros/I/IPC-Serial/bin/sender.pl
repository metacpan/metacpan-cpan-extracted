#!/usr/bin/perl
# -*-cperl-*-
#
# sender.pl - Queue message sender for IPC::Serial
# Copyright (c) 2017 Ashish Gulhati <ipc-serial at hash.neo.tc>
#
# $Id$

use warnings;

use Time::HiRes qw(usleep);
use IPC::Serial;
use IPC::Queue::Duplex;

my $queue = new IPC::Queue::Duplex( Dir => '/tmp' );
my $sender = new IPC::Serial( Port => '/dev/cua00' );

my $myturn = 1;

while (1) {
  if (my $job = $queue->get) {             # Send a job from the queue
    print STDERR "sender:getqueue\n";
    unless ($sender->sendmsg("$job->{File} $job->{Request}",1)) {
      $queue->addfile($job->{File}, $job->{Request});
    }
  }
  else {
    usleep 100000;
  }
}
