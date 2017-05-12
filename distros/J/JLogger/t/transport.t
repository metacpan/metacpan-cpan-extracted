#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok 'JLogger::Transport';

my $transport = new_ok 'JLogger::Transport',
  [host => 'localhost', port => '5520', secret => 'secret'];

can_ok $transport, qw/domain host port secret on_message connect disconnect/;
