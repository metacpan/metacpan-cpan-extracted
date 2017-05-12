#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok 'Log::Dispatch::Channels';
my $logger = Log::Dispatch::Channels->new;
isa_ok $logger, 'Log::Dispatch::Channels';

