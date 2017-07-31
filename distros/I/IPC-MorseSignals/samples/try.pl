#!/usr/bin/env perl

use strict;
use warnings;

use POSIX qw<pause EXIT_SUCCESS EXIT_FAILURE>;

use lib qw<blib/lib>;

use IPC::MorseSignals::Emitter;
use IPC::MorseSignals::Receiver;

my $pid = fork;
if (!defined $pid) {
 die "fork() failed : $!";
} elsif ($pid == 0) {
 local %SIG;
 my $rcv = IPC::MorseSignals::Receiver->new(\%SIG, done => sub {
  print STDERR "I, the child, recieved this : $_[1]\n";
  exit EXIT_SUCCESS;
 });
 print STDERR "I'm $$ (the child), and I'm waiting for data...\n";
 pause while 1;
 exit EXIT_FAILURE;
}

print STDERR "I'm $$ (the parent), and I'm gonna send a message to my child $pid.\n";

my $snd = IPC::MorseSignals::Emitter->new(speed => 1000);
$snd->post("This message was sent with IPC::MorseSignals");
$snd->send($pid);
waitpid $pid, 0;
