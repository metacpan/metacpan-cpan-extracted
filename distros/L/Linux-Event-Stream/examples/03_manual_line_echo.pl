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
  data => { buf => '' },

  on_read => sub ($s, $bytes, $st) {
    $st->{buf} .= $bytes;

    while (1) {
      my $i = index($st->{buf}, "\n");
      last if $i < 0;

      my $line = substr($st->{buf}, 0, $i + 1, '');
      chomp $line;

      print "A got line: $line\n";
      $s->close_after_drain if $line eq 'quit';
    }
  },
);

my $sb = Linux::Event::Stream->new(
  loop => $loop,
  fh   => $b,
  on_read => sub ($s, $bytes, $data) {
    $s->write($bytes); # echo bytes back
  },
);

$sa->write("hello from A\n");
$sa->write("quit\n");

$loop->run;
