#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";


use Linux::Event;

pipe(my $r, my $w) or die "pipe failed: $!";

my $loop = Linux::Event->new( model => 'reactor', backend => 'epoll' );

$loop->watch($r,
  read => sub ($loop, $fh, $watcher) {
    say "watch_replace: OLD handler (should not print)";
    $loop->stop;
  },
);

# Replace watcher for same fd:
$loop->watch($r,
  read => sub ($loop, $fh, $watcher) {
    my $buf = '';
    sysread($fh, $buf, 4096);
    chomp $buf;
    say "watch_replace: NEW handler read='$buf'";
    $watcher->cancel;
    $loop->stop;
  },
);

$loop->after(0.020, sub ($loop) { syswrite($w, "x\n") });

$loop->run;
say "watch_replace: done";
