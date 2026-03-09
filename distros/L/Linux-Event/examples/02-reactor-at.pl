#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;

my $loop = Linux::Event->new(model => 'reactor');
$loop->clock->tick;
my $deadline = $loop->clock->now_s + 0.150;

say "scheduling absolute monotonic deadline";
$loop->at($deadline, sub ($loop) {
  say "absolute deadline reached";
  $loop->stop;
});

$loop->run;
