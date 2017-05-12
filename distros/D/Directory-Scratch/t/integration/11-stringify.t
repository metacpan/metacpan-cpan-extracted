#!/usr/bin/perl
# 11-stringify.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 1;
use Directory::Scratch;

my $tmp = Directory::Scratch->new;
is($tmp->base, "$tmp", 'tmp stringifies to its base');
