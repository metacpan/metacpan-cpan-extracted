#!/usr/bin/perl

use lib "lib";
use Games::Roguelike::Caves;

#my $map = generate_cave(50,20,2,.5,"W",' ');
#outline_walls ($map,"W",' ');
my $map = generate_cave(50,20);
outline_walls ($map);
for (@$map){
    for (@$_){
        print;
    }    
    print "\n"
}


