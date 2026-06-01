#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Test2::V0;
use Linux::Event;

my $loop = Linux::Event->new;

my $ran = 0;

$loop->after(0, sub ($loop) {
  $ran++;
  $loop->stop;
});

$loop->run;

is($ran, 1, 'after(0) fires promptly');

done_testing;
