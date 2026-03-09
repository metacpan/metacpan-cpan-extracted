#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;
use POSIX ();

my $loop = Linux::Event->new( model => 'reactor', backend => 'epoll' );

my $sub = $loop->signal('USR1', sub ($loop, $sig, $count, $data) {
  print "got signal=$sig count=$count\n";
  $loop->stop;
});

# Schedule a signal to ourselves shortly after starting the loop.
$loop->after(0.05, sub ($loop) {
  kill POSIX::SIGUSR1(), $$;
});

$loop->run;

print "done\n";
