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
    
    is($line,"  012\n +---+\n0| 1F|\n1|12.|\n2|...|\n +---+\n");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(3,3,2);
    $game->fill_mines;
    
    $game->step(0,0);
    $game->flag(0,2);
    
    $game->print_out("field");
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

    is($line,"  012\n +---+\n0| 1f|\n1|12*|\n2|*21|\n +---+\n");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(3,3,2);
    $game->fill_mines;
    
    $game->step(0,0);
    $game->flag(0,2);
    
    $game->print_out("check");
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
    
    is($line,"  012\n +---+\n0| 11|\n1|12*|\n2|*21|\n +---+\n");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(3,3,2);
    $game->fill_mines;
    
    $game->step(0,0);
    $game->flag(0,2);
    
    $game->print_out("solution");
    exit;
}
else {
    die("can't fork test : $!");
}


##############################

undef $/;

$parent = open(TEST4,"-|");

if($parent) {
    $line=<TEST4>;
    close(TEST4) or warn(" can't close child pid $parent : $!");
    
    is($line,"mines: 1 of 2\n");
}
elsif(defined($parent) && not $parent) { # child 
    srand 2; # so we always get the same field.
    
    $game = Games::Mines::Play->new(3,3,2);
    $game->fill_mines;
    
    $game->step(0,0);
    $game->flag(0,2);
    
    $game->print_status_line;
    exit;
}
else {
    die("can't fork test : $!");
}


##################
