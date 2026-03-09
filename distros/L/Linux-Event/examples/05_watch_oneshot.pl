#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";


use Linux::Event;

pipe(my $r, my $w) or die "pipe failed: $!";

my $loop = Linux::Event->new( model => 'reactor', backend => 'epoll' );

my $count = 0;

$loop->watch($r,
  oneshot => 1,
  read => sub ($loop, $fh, $watcher) {
    $count++;
    my $buf = '';
    sysread($fh, $buf, 4096);
    chomp $buf;
    say "watch_oneshot: fired count=$count data='$buf'";
  },
);

$loop->after(0.020, sub ($loop) { syswrite($w, "a\n") });
$loop->after(0.040, sub ($loop) { syswrite($w, "b\n") });

$loop->after(0.080, sub ($loop) {
  say "watch_oneshot: final_count=$count (expected 1)";
  $loop->stop;
});

$loop->run;
say "watch_oneshot: done";
