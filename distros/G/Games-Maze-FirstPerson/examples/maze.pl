#!/usr/bin/perl

use strict;
use warnings;
use Term::ReadKey;
use lib '../lib';
use Games::Maze::FirstPerson;

my $maze = Games::Maze::FirstPerson->new(dimensions => [3,3]);

print <<"END_CONTROLS";
q = quit

w = move north
a = move west
s = move south
d = move east

END_CONTROLS

ReadMode 'cbreak';

my %move_for = (
    w => 'go_north',
    a => 'go_west',
    s => 'go_south',
    d => 'go_east'
);

while ( ! $maze->has_won ) {
    print $maze->surroundings;
    my $key = lc ReadKey(0);
    if ( 'q' eq $key ) {
        print "OK.  Quitting\n";
        exit;
    }
    if ( my $action = $move_for{$key} ) {
        unless ( $maze->$action ) {
            print "You can't go that direction\n\n";
        }
        else {
            print "\n";
        }
    }
    else {
        print "I don't understand\n\n";
    }
}

print "Congratulations!  You found the exit!\n";
print $maze->to_ascii;
