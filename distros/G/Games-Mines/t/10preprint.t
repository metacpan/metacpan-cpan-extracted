#! perl

use Test::More tests=>4;
use strict;

my($game,$line,$parent);

use Games::Mines::Play;

#############################

undef $/;

$parent = open(TEST1,"-|");

if($parent) {
    $line=<TEST1>;
    close(TEST1) or warn(" can't close child pid $parent : $!");
    
    is($line,"  012\n +---+\n");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(3,3,2);
    $game->fill_mines;
    
    $game->_start_field;
    exit;
}
else {
    die("can't fork test : $!");
}

##############################

undef $/;

$parent = open(TEST2,"-|");

if($parent) {
    $line=<TEST2>;
    close(TEST2) or warn(" can't close child pid $parent : $!");

    is($line," +---+\n");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(3,3,2);
    $game->fill_mines;
    
    $game->_end_field;
    exit;
}
else {
    die("can't fork test : $!");
}

##############################

undef $/;

$parent = open(TEST3,"-|");

if($parent) {
    $line=<TEST3>;
    close(TEST3) or warn(" can't close child pid $parent : $!");
    
    is($line,"057|");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(234,132,202);
    $game->fill_mines;
    
    $game->_start_line(57);
    exit;
}
else {
    die("can't fork test : $!");
}



##############################

undef $/;

$parent = open(TEST3,"-|");

if($parent) {
    $line=<TEST3>;
    close(TEST3) or warn(" can't close child pid $parent : $!");
    
    is($line,"|\n");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(3,3,2);
    $game->fill_mines;
    
    $game->_end_line;
    exit;
}
else {
    die("can't fork test : $!");
}




##################


