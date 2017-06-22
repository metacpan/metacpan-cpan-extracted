#!/usr/bin/perl
# -*-cperl-*-
#
# client.pl - Queueing client for IPC::Serial
# Copyright (c) 2017 Ashish Gulhati <ipc-serial at hash.neo.tc>
#
# $Id: bin/client.pl v1.006 Sun Jun 11 12:42:55 PDT 2017 $

use warnings;

use Time::HiRes qw(usleep);
use IPC::Serial;
use IPC::Queue::Duplex;

my $queue = new IPC::Queue::Duplex( Dir => '/tmp' );
my $client = new IPC::Serial( Port => '/dev/cua00' );

my $myturn = 1;

while (1) {
  my $action = 0;
  if ($myturn) {
    if (my $job = $queue->get) {             # Send a job from the queue
      print STDERR "client:checkqueue\n";
      unless ($client->sendmsg("$job->{File} $job->{Request}",1)) {
	$queue->addfile($job->{File}, $job->{Request});
      }
      $action = 1;
    }
    else {                                   # No jobs, yield to server
      $client->sendmsg('YOURTURN', 1);
    }
    $myturn = 0;
  }
  elsif (my $msg = $client->getmsg(10, 0, 1)) {
    if ($msg =~ /^(\S+) (.+)$/) {
      chomp $msg;
      print STDERR "client:getmsg:$msg:\n";
      my ($filename, $response) = ($1, $2);
      $filename =~ s/^.+\//$queue->{Dir}\//; $filename =~ s/\.fin/.wrk/;
      my $job = new IPC::Queue::Duplex::Job ( File => $filename );
      $job->finish($response);
      $action = 1;
      $myturn = 1;
    }
    elsif ($msg eq 'YOURTURN') {
      $myturn = 1;
    }
  }
  usleep 100000 unless $action;
}
