package Games::Roguelike::Caves;

#use 5.008000;
use strict;
use warnings;

#require Exporter;

use base 'Exporter';

our @EXPORT = qw(
	generate_cave
	outline_walls
);

our $VERSION = '0.01';

#use cellular automata to carve out a decent cave
#initially contain 45% walls at random
#a tile becomes or remains a wall if the 3x3 region centered on it contains at least 5 walls.
#use 1 to represent wall, 0 is space
sub generate_cave{
    my ($w, $h, $iterations, $percentWalls, $wall, $floor) = @_;
    die 'dimensions?' unless ($w and $h);
    $iterations ||= 12;
    $percentWalls ||= .45;
    $percentWalls /= 100 if $percentWalls>1; # in case it's .45 or something
    $wall = ' ' unless defined $wall;
    $floor = '.' unless defined $floor;
    
    my @terrain = ();
    my @nextStep = ();
    for my $x (0..$w-1){
        for my $y (0..$h-1){
            $terrain[$y][$x] = rand()<$percentWalls ? 1 : 0;
        }
    }
    for (1..$iterations){
        for my $x (0..$w-1){
            for my $y (0..$h-1){
                if ( !$x or !$y or $x==$w-1 or $y==$h-1){
                    #we're at edge: be wall.
                    $nextStep[$y][$x] = 1;
                    next;
                }
                my $c=0;
                #count walls in 3x3 square
                $c += $terrain[$y-1][$x-1];
                $c += $terrain[$y-1][$x];
                $c += $terrain[$y-1][$x+1];
                $c += $terrain[$y]  [$x-1];
                $c += $terrain[$y]  [$x];
                $c += $terrain[$y]  [$x+1];
                $c += $terrain[$y+1][$x-1];
                $c += $terrain[$y+1][$x];
                $c += $terrain[$y+1][$x+1];
                $nextStep[$y][$x] = $c>4 ? 1 : 0;
            }
        }
        #swap arrays using typeglobs
        #(*terrain,*nextStep) = (*nextStep,*terrain)
       my @tmp = @terrain;
       @terrain = @nextStep;
       @nextStep = @tmp;
    }
    #translate to cave wall or floor
    for my $x (0..$w-1){
        for my $y (0..$h-1){
            $terrain[$y][$x] = $terrain[$y][$x] ? $wall : $floor;
            #print STDOUT $terrain[$y][$x];
        }
        #print STDOUT "\n";
    }
    return \@terrain;
}

sub outline_walls{
    my ($terrain, $wall, $floor) = @_;
    my $h = $#$terrain + 1;
    die 'empty map' unless $h;
    my $w = $#{$terrain->[0]} + 1;
    die 'empty row' unless $w;
    $floor = '.' unless defined $floor;
    $wall = ' ' unless defined $wall;
    
    no warnings; #yeah. sometimes this checks tiles outide of $terrain.
    for my $x (0..$w-1){
        for my $y (0..$h-1){
            next if $terrain->[$y][$x] eq $floor; #is floor
            my ($v,$h)=(0,0); #vert/horiz weighting
            $v++ if $terrain->[$y][$x-1] eq $floor;
            $v++ if $terrain->[$y][$x+1] eq $floor;
            $h++ if $terrain->[$y-1][$x] eq $floor;
            $h++ if $terrain->[$y+1][$x] eq $floor;
            if ($h>$v){
                $terrain->[$y][$x] = '-';
            }
            elsif ($v>$h){
                $terrain->[$y][$x] = '|';
            }
            elsif($v){ #maybe a corner. either will do
                $terrain->[$y][$x] = '-'
            }
            else{   #might border nothing
               if ($terrain->[$y-1][$x-1] eq $floor or
                   $terrain->[$y-1][$x+1] eq $floor or
                   $terrain->[$y+1][$x-1] eq $floor or
                   $terrain->[$y+1][$x+1] eq $floor)
                 {
                  $terrain->[$y][$x] = '|';
                 }
            } #else it stays as ' '
        }
    }
    delete $terrain->[$h]; #this last row autovivified
}

1;
__END__

=head1 NAME

Games::Roguelike::Caves - generation of cave levels using cellular automata

=head1 SYNOPSIS

  use Games::Roguelike::Caves;

  my $map = generate_cave(50,20);
  outline_walls ($map);
  for (@$map){
    for (@$_){
        print;
    }    
    print "\n"
  }

=head1 DESCRIPTION

This module provides generation of cave levels using cellular automata.
In other words...
 * Each tile is initialized as a wall or a floor.
 * Each square's terrain is then reevaluated based upon the number of wall tiles near it.
 * The previous step is repeated a few times.

outline_walls is included. This replaces walls that border floors with - or |.
It could potentially be useful for other level generators, although it is somewhat simple.

=head2 EXPORT

 generate_cave
 outline_walls

=head1 AUTHOR

Zach M, zpmorgan@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Zach M

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
