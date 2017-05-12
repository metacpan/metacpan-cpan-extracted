#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;

use lib "./lib";

use Test::More tests => 42;
use Hardware::Simulator::MIX;

my $mix = Hardware::Simulator::MIX->new;
$mix->reset();

### CODE
my $loc = 0;
$mix->write_mem($loc++, ['+', 46, 56, 0,  5, 8]); #LDA 3000(0:5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  5, 8]); #LDA 3001(0:5)
$mix->write_mem($loc++, ['+', 46, 56, 0, 37, 8]); #LDA 3000(4,5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  3, 8]); #LDA 3001(0,3)
$mix->write_mem($loc++, ['+', 46, 57, 0, 10, 8]); #LDA 3001(1,2)
$mix->write_mem($loc++, ['+', 46, 57, 0,  0, 8]); #LDA 3001(0,0)
$mix->write_mem($loc++, ['+', 46, 57, 0,  9, 8]); #LDA 3001(1,1)

$mix->write_mem($loc++, ['+', 46, 56, 0,  5, 15]); #LDX 3000(0:5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  5, 15]); #LDX 3001(0:5)
$mix->write_mem($loc++, ['+', 46, 56, 0, 37, 15]); #LDX 3000(4,5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  3, 15]); #LDX 3001(0,3)
$mix->write_mem($loc++, ['+', 46, 57, 0, 10, 15]); #LDX 3001(1,2)
$mix->write_mem($loc++, ['+', 46, 57, 0,  0, 15]); #LDX 3001(0,0)
$mix->write_mem($loc++, ['+', 46, 57, 0,  9, 15]); #LDX 3001(1,1)

$mix->write_mem($loc++, ['+', 46, 57, 0,  5,  9]); #LD1 3001(0:5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 13, 10]); #LD2 3001(1:5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 37, 11]); #LD3 3001(4,5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 45, 12]); #LD4 3001(5,5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 28, 13]); #LD5 3001(3,4)
$mix->write_mem($loc++, ['+', 46, 57, 0, 11, 14]); #LD6 3001(1,3)
$mix->write_mem($loc++, ['+', 46, 57, 0,  0,  9]); #LD1 3001(0:0)

$mix->write_mem($loc++, ['+', 46, 56, 0,  5, 16]); #LDAN 3000(0:5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  5, 16]); #LDAN 3001(0:5)
$mix->write_mem($loc++, ['+', 46, 56, 0, 37, 16]); #LDAN 3000(4,5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  3, 16]); #LDAN 3001(0,3)
$mix->write_mem($loc++, ['+', 46, 57, 0, 10, 16]); #LDAN 3001(1,2)
$mix->write_mem($loc++, ['+', 46, 57, 0,  0, 16]); #LDAN 3001(0,0)
$mix->write_mem($loc++, ['+', 46, 57, 0,  9, 16]); #LDAN 3001(1,1)

$mix->write_mem($loc++, ['+', 46, 56, 0,  5, 23]); #LDXN 3000(0:5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  5, 23]); #LDXN 3001(0:5)
$mix->write_mem($loc++, ['+', 46, 56, 0, 37, 23]); #LDXN 3000(4,5)
$mix->write_mem($loc++, ['+', 46, 57, 0,  3, 23]); #LDXN 3001(0,3)
$mix->write_mem($loc++, ['+', 46, 57, 0, 10, 23]); #LDXN 3001(1,2)
$mix->write_mem($loc++, ['+', 46, 57, 0,  0, 23]); #LDXN 3001(0,0)
$mix->write_mem($loc++, ['+', 46, 57, 0,  9, 23]); #LDXN 3001(1,1)

$mix->write_mem($loc++, ['+', 46, 57, 0,  5, 17]); #LD1N 3001(0:5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 13, 18]); #LD2N 3001(1:5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 37, 19]); #LD3N 3001(4,5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 45, 20]); #LD4N 3001(5,5)
$mix->write_mem($loc++, ['+', 46, 57, 0, 28, 21]); #LD5N 3001(3,4)
$mix->write_mem($loc++, ['+', 46, 57, 0, 11, 22]); #LD6N 3001(1,3)
$mix->write_mem($loc++, ['+', 46, 57, 0,  0, 17]); #LD1N 3001(0:0)

$mix->write_mem($loc++, ['+',  0,  0, 0,  2, 5]);

### DATA
$loc = 3000;
$mix->write_mem($loc++, ['+',  1,  2,  3,  4,  5]);
$mix->write_mem($loc++, ['-', 10, 20, 30, 40, 50]);

### TEST LDA
$mix->step();
is_deeply($mix->{rA}, ['+', 1, 2, 3, 4, 5]);
$mix->step();
is_deeply($mix->{rA}, ['-', 10, 20, 30, 40, 50]);
$mix->step();
is_deeply($mix->{rA}, ['+', 0, 0, 0, 4, 5]);
$mix->step();
is_deeply($mix->{rA}, ['-', 0, 0, 10, 20, 30]);
$mix->step();
is_deeply($mix->{rA}, ['+', 0, 0, 0, 10, 20]);
$mix->step();
is_deeply($mix->{rA}, ['-', 0, 0, 0, 0, 0]);
$mix->step();
is_deeply($mix->{rA}, ['+', 0, 0, 0, 0, 10]);

### TEST LDX
$mix->step();
is_deeply($mix->{rX}, ['+', 1, 2, 3, 4, 5]);
$mix->step();
is_deeply($mix->{rX}, ['-', 10, 20, 30, 40, 50]);
$mix->step();
is_deeply($mix->{rX}, ['+', 0, 0, 0, 4, 5]);
$mix->step();
is_deeply($mix->{rX}, ['-', 0, 0, 10, 20, 30]);
$mix->step();
is_deeply($mix->{rX}, ['+', 0, 0, 0, 10, 20]);
$mix->step();
is_deeply($mix->{rX}, ['-', 0, 0, 0, 0, 0]);
$mix->step();
is_deeply($mix->{rX}, ['+', 0, 0, 0, 0, 10]);

### TEST LDi
$mix->step();
is_deeply($mix->{rI1}, ['-', 0, 0, 0, 40, 50]);
$mix->step();
is_deeply($mix->{rI2}, ['+', 0, 0, 0, 40, 50]);
$mix->step();
is_deeply($mix->{rI3}, ['+', 0, 0, 0, 40, 50]);
$mix->step();
is_deeply($mix->{rI4}, ['+', 0, 0, 0,  0, 50]);
$mix->step();
is_deeply($mix->{rI5}, ['+', 0, 0, 0, 30, 40]);
$mix->step();
is_deeply($mix->{rI6}, ['+', 0, 0, 0, 20, 30]);
$mix->step();
is_deeply($mix->{rI1}, ['-', 0, 0, 0, 0, 0]);

### TEST LDAN
$mix->step();
is_deeply($mix->{rA}, ['-', 1, 2, 3, 4, 5]);
$mix->step();
is_deeply($mix->{rA}, ['+', 10, 20, 30, 40, 50]);
$mix->step();
is_deeply($mix->{rA}, ['-', 0, 0, 0, 4, 5]);
$mix->step();
is_deeply($mix->{rA}, ['+', 0, 0, 10, 20, 30]);
$mix->step();
is_deeply($mix->{rA}, ['-', 0, 0, 0, 10, 20]);
$mix->step();
is_deeply($mix->{rA}, ['+', 0, 0, 0, 0, 0]);
$mix->step();
is_deeply($mix->{rA}, ['-', 0, 0, 0, 0, 10]);

### TEST LDX
$mix->step();
is_deeply($mix->{rX}, ['-', 1, 2, 3, 4, 5]);
$mix->step();
is_deeply($mix->{rX}, ['+', 10, 20, 30, 40, 50]);
$mix->step();
is_deeply($mix->{rX}, ['-', 0, 0, 0, 4, 5]);
$mix->step();
is_deeply($mix->{rX}, ['+', 0, 0, 10, 20, 30]);
$mix->step();
is_deeply($mix->{rX}, ['-', 0, 0, 0, 10, 20]);
$mix->step();
is_deeply($mix->{rX}, ['+', 0, 0, 0, 0, 0]);
$mix->step();
is_deeply($mix->{rX}, ['-', 0, 0, 0, 0, 10]);

### TEST LDi
$mix->step();
is_deeply($mix->{rI1}, ['+', 0, 0, 0, 40, 50]);
$mix->step();
is_deeply($mix->{rI2}, ['-', 0, 0, 0, 40, 50]);
$mix->step();
is_deeply($mix->{rI3}, ['-', 0, 0, 0, 40, 50]);
$mix->step();
is_deeply($mix->{rI4}, ['-', 0, 0, 0,  0, 50]);
$mix->step();
is_deeply($mix->{rI5}, ['-', 0, 0, 0, 30, 40]);
$mix->step();
is_deeply($mix->{rI6}, ['-', 0, 0, 0, 20, 30]);
$mix->step();
is_deeply($mix->{rI1}, ['+', 0, 0, 0, 0, 0]);
