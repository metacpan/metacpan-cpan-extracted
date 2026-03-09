#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";


use Linux::Event;

my $loop = Linux::Event->new( model => 'reactor', backend => 'epoll' );

say "timer_after: scheduling in 0.050s";

$loop->after(0.050, sub ($loop) {
  say "timer_after: fired";
  $loop->stop;
});

$loop->run;
say "timer_after: done";
