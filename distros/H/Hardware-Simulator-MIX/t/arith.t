#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;

use lib "./lib";

use Test::More tests => 10;
use Hardware::Simulator::MIX;

my $mix = Hardware::Simulator::MIX->new;
$mix->reset();

### CODE
my $loc = 0;

$mix->write_mem($loc++, ['+', 31, 16, 0, 005, 1]); #ADD 2000(0:5)
$mix->write_mem($loc++, ['+', 31, 17, 0, 005, 1]); #ADD 2001(0:5)
$mix->write_mem($loc++, ['+', 31, 16, 0, 005, 2]); #SUB 2000(0:5)
$mix->write_mem($loc++, ['+', 31, 16, 0, 005, 1]); #ADD 2000(0:5)
$mix->write_mem($loc++, ['+', 31, 16, 0, 005, 3]); #MUL 2000(0:5)
$mix->write_mem($loc++, ['+', 31, 16, 0, 005, 4]); #DIV 2000(0:5)
$mix->write_mem($loc++, ['+', 31, 16, 0, 045, 3]); #MUL 2000(0:5)

$mix->write_mem(2000, ['+', 1, 2, 3, 4, 5]);
$mix->write_mem(2001, ['-', 1, 2, 3, 4, 5]);

### TEST 

$mix->set_reg('rA',   ['+', 6, 7, 8, 9, 0]);
$mix->step();
is_deeply($mix->{rA}, ['+', 7, 9, 11, 13, 5]);

$mix->set_reg('rA',   ['+', 6, 7, 8, 9, 0]);
$mix->step();
is_deeply($mix->{rA}, ['+', 5, 5, 5, 4, 59]);

$mix->step();
is_deeply($mix->{rA}, ['+', 4, 3, 2, 0, 54]);

$mix->set_reg('rA',   ['+', 63, 7, 8, 9, 0]);
$mix->step();
ok($mix->{ov_flag}==1);

$mix->set_reg('rA',   ['+', 1, 2, 3, 4, 5]);
$mix->write_mem(2000, ['-', 0, 0, 0, 0, 5]);
$mix->step();
is_deeply($mix->{rA}, ['-', 0, 0, 0, 0, 0]);
is_deeply($mix->{rX}, ['-', 5, 10, 15, 20, 25]);
$mix->step();
is_deeply($mix->{rA}, ['+', 1, 2, 3, 4, 5]);      # 7
is_deeply($mix->{rX}, ['-', 0, 0, 0, 0, 0]);      # 8

$mix->write_mem(2000, ['-', 0, 0, 0, 1, 0]);   
$mix->step();
is_deeply($mix->{rA}, ['+', 0, 0, 0, 0, 1]);      # 9
is_deeply($mix->{rX}, ['+', 2, 3, 4, 5, 0]);      # 10


