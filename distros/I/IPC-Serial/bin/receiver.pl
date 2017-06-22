#!/usr/bin/perl
# -*-cperl-*-
#
# receiver.pl - Queue message receiver for IPC::Serial
# Copyright (c) 2017 Ashish Gulhati <ipc-serial at hash.neo.tc>
#
# $Id$

use warnings;

use Time::HiRes qw(usleep);
use IPC::Serial;
use IPC::Queue::Duplex;

my $queue = new IPC::Queue::Duplex ( Dir => '/tmp/server' );
my $receiver = new IPC::Serial (Port => '/dev/cua00');

if (my $msg = $receiver->getmsg(10, 0, 1)) {
  if ($msg =~ /^(\S+) (.+)$/) {
    chomp $msg;
    print STDERR "receiver:getmsg:$msg:\n";
    my ($filename, $request) = ($1, $2);
    $filename =~ s/^.+\//$queue->{Dir}\//; $filename =~ s/\.wrk/.job/;
    my $job = $queue->addfile($filename, $request);
  }
}
else {
  usleep 100000;
}
