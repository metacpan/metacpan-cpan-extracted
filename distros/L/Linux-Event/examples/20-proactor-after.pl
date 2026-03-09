#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new(model => 'proactor', backend => 'uring');

$loop->after(0.100,
  on_complete => sub ($op, $result, $data) {
    say "proactor timer expired";
    $loop->stop;
  },
);

$loop->run;
