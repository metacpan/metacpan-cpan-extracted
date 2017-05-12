#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok 'JLogger::Storage';

my $storage = new_ok 'JLogger::Storage';

can_ok $storage, 'init', 'save';
