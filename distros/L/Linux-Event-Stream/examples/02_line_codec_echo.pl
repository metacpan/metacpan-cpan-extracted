#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event;
use Linux::Event::Stream;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";

my $loop = Linux::Event->new;

my $sa = Linux::Event::Stream->new(
  loop       => $loop,
  fh         => $a,
  codec      => 'line',
  on_message => sub ($s, $line, $data) {
    print "A got line: $line\n";
    $s->close_after_drain if $line eq 'quit';
  },
);

my $sb = Linux::Event::Stream->new(
  loop       => $loop,
  fh         => $b,
  codec      => 'line',
  on_message => sub ($s, $line, $data) {
    $s->write_message($line); # echo
  },
);

$sa->write_message("hello from A");
$sa->write_message("quit");

$loop->run;
