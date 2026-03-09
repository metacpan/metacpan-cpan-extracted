#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;
use POSIX qw(SIGUSR1);

my $loop = Linux::Event->new(model => 'reactor');

$loop->signal('USR1', sub ($loop, $sig, $count, $data) {
  say "received signal $sig count=$count";
  $loop->stop;
});

$loop->after(0.050, sub ($loop) {
  kill SIGUSR1(), $$;
});

$loop->run;
