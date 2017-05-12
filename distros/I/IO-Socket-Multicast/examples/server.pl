#!/usr/bin/perl

use strict;
use lib '../blib/lib','../blib/arch';
use IO::Socket::Multicast;

use constant DESTINATION => '226.1.1.2:2000';

my $sock = IO::Socket::Multicast->new(ReuseAddr=>1);

while (1) {
  my $message = localtime;
  $message .= "\n" . `who`;
  $sock->mcast_send($message,DESTINATION) || die "Couldn't send: $!";
} continue {
  sleep 5;
}
