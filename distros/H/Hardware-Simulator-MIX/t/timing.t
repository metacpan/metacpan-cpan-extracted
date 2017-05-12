#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;

use Test::More tests => 8;

use Hardware::Simulator::MIX;

my $mix = Hardware::Simulator::MIX->new;
$mix->reset();
my $loc = 0;
## NOP takes 1 unit
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 0]);

my $t1 = $mix->get_current_time();
$mix->step();
my $t2 = $mix->get_current_time();
ok($t2 - $t1 == 1);

# ADD takes 2 units
$t1 = $mix->get_current_time();
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 1]);
$mix->step();
$t2 = $mix->get_current_time();
ok($t2 - $t1 == 2);

# MUL takes 10
$t1 = $mix->get_current_time();
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 3]);
$mix->step();
$t2 = $mix->get_current_time();
ok($t2 - $t1 == 10);

# DIV takes 12
$t1 = $mix->get_current_time();
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 4]);
$mix->step();
$t2 = $mix->get_current_time();
ok($t2 - $t1 == 12);


# CMP takes 2

$t1 = $mix->get_current_time();
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 63]);
$mix->step();
$t2 = $mix->get_current_time();
ok($t2 - $t1 == 2);


# Load takes 2
$t1 = $mix->get_current_time();
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 12]);
$mix->step();
$t2 = $mix->get_current_time();
ok($t2 - $t1 == 2);

# Store takes 2
$t1 = $mix->get_current_time();
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 29]);
$mix->step();
$t2 = $mix->get_current_time();
ok($t2 - $t1 == 2);

# shift takes 2
$t1 = $mix->get_current_time();
$mix->write_mem($loc++, ['+', 0, 0, 0, 5, 6]);
$mix->step();
$t2 = $mix->get_current_time();
ok($t2 - $t1 == 2);

