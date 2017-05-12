#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;

use Test::More tests => 1;

use Hardware::Simulator::MIX;

my $mix = Hardware::Simulator::MIX->new;
$mix->reset();

$mix->write_mem(0, ['+', 0, 0, 0, 2, 5]);
$mix->step();
ok($mix->{message} eq "halts normally");
