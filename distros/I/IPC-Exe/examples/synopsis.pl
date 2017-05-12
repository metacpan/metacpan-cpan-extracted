#!/usr/bin/perl

use warnings;
use strict;

use lib "../lib";

use Data::Dumper;
use IPC::Exe qw(exe bg);
                                                                                         
my @pids = &{
       exe qw( ls  /tmp  a.txt ), \"2>#",
    bg exe qw( sort -r ),
       exe sub { print "[", shift, "] 2nd cmd: @_\n"; print "three> $_" while <STDIN> },
    bg exe 'sort',
       exe "cat", "-n",
       exe sub { print "six> $_" while <STDIN>; print "[", shift, "] 5th cmd: @_\n" },
};

# two PIDs returned: 'ls' & background job
print Dumper(\@pids);

