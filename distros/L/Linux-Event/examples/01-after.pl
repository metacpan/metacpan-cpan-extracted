#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;

my $loop = Linux::Event->new;

say "scheduling readiness timer for 0.100 seconds";
$loop->after(0.100, sub ($loop) {
  say "readiness timer fired";
  $loop->stop;
});

$loop->run;
