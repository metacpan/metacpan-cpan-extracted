#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;

my $loop = Linux::Event->new(model => 'reactor');

say "scheduling reactor timer for 0.100 seconds";
$loop->after(0.100, sub ($loop) {
  say "reactor timer fired";
  $loop->stop;
});

$loop->run;
