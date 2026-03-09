#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;

pipe(my $r, my $w) or die "pipe failed: $!";


my $loop = Linux::Event->new(model => 'reactor');

my $loop = Linux::Event->new( model => 'reactor', backend => 'epoll' );


$loop->watch(
  $r,
  read => sub ($loop, $fh, $watcher) {
    my $buf = '';
    my $n = sysread($fh, $buf, 4096);
    die "sysread failed: $!" if !defined $n;

    if ($n == 0) {
      $watcher->cancel;
      $loop->stop;
      return;
    }

    chomp $buf;
    say "read from pipe: $buf";
    $watcher->cancel;
    $loop->stop;
  },
);

$loop->after(0.050, sub ($loop) {
  syswrite($w, "hello from reactor
") or die "syswrite failed: $!";
});

$loop->run;
