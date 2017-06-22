#!/usr/bin/perl
# -*-cperl-*-
#
# server.pl - Queueing server for IPC::Serial
# Copyright (c) 2017 Ashish Gulhati <ipc-serial at hash.neo.tc>
#
# $Id: bin/server.pl v1.006 Sun Jun 11 12:42:55 PDT 2017 $

use warnings;

use Time::HiRes qw(usleep);
use IPC::Serial;
use IPC::Queue::Duplex;

my $queue = new IPC::Queue::Duplex ( Dir => '/tmp/server' );
my $server = new IPC::Serial (Port => '/dev/cua00');

my $myturn = 0;

while (1) {
  my $action = 0;
  if ($myturn) {
    if (my $job = $queue->getresponse) {       # Send a response back
      print STDERR "server:checkqueue\n";
      unless ($server->sendmsg("$job->{File} $job->{Response}",1)) {
	$queue->addfile($job->{File}, $job->{Response});
      }
      $action = 1;
    }
    else {                                     # No responses waiting, yield to client
      $server->sendmsg('YOURTURN', 1);
    }
    $myturn = 0;
  }
  elsif (my $msg = $server->getmsg(10, 0, 1)) {
    if ($msg =~ /^(\S+) (.+)$/) {
      chomp $msg;
      print STDERR "server:getmsg:$msg:\n";
      my ($filename, $request) = ($1, $2);
      $filename =~ s/^.+\//$queue->{Dir}\//; $filename =~ s/\.wrk/.job/;
      my $job = $queue->addfile($filename, $request);
      $action = 1;
      $myturn = 1;
    }
    elsif ($msg eq 'YOURTURN') {
      $myturn = 1;
    }
  }
  usleep 100000 unless $action;
}
