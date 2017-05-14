#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

use_ok('LEGO::NXT');

my $nxt = eval{ LEGO::NXT->new() };
isa_ok( $nxt, 'LEGO::NXT' );

