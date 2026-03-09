#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";


use Linux::Event;

pipe(my $r, my $w) or die "pipe failed: $!";

my $loop = Linux::Event->new( model => 'reactor', backend => 'epoll' );

say "unwatch_safe: unwatch on never-watched handle returns " . ($loop->unwatch($r) ? 1 : 0);

my $watcher = $loop->watch($r,
  read => sub ($loop, $fh, $watcher) {
    say "unwatch_safe: should not fire";
  },
);

say "unwatch_safe: unwatch on watched handle returns " . ($loop->unwatch($r) ? 1 : 0);
say "unwatch_safe: unwatch again returns " . ($loop->unwatch($r) ? 1 : 0);

$watcher->cancel; # also safe
say "unwatch_safe: watcher->cancel called";

$loop->after(0.030, sub ($loop) { $loop->stop });
$loop->run;
say "unwatch_safe: done";
