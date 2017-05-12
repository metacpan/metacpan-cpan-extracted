#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use_ok 'JLogger::Transport::AnyEvent';

my $transport = new_ok 'JLogger::Transport::AnyEvent',
  [ host => 'localhost',
    port   => 5520,
    secret => 'secret',
  ];
