#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use_ok 'JLogger';

my $logger = new_ok 'JLogger',
  [host => '127.0.0.1', port => 5526, secret => 'secret'];
