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
  loop => $loop,
  fh   => $a,
  on_read => sub ($s, $bytes, $data) { print "A got: $bytes" },
);

my $sb = Linux::Event::Stream->new(
  loop => $loop,
  fh   => $b,
  on_read => sub ($s, $bytes, $data) { $s->write($bytes) }, # echo
);

$sa->write("hello from A\n");
$loop->run;
