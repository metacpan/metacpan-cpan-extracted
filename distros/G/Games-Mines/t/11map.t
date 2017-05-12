#! perl

use Test::More tests=>28;
use strict;

my($game,$line,$parent);

use Games::Mines::Play;

#############################

undef $/;

srand 2; # so we always get the same field.

$game = Games::Mines::Play->new(3,3,2);
$game->set_ASCII;
$game->fill_mines;

foreach my $k (keys %{$game->{'map'}}) {
    
    $parent = open(TEST1,"-|");
    
    if($parent) {
	$line=<TEST1>;
	close(TEST1) or warn(" can't close child pid $parent : $!");
	
	is($line,$game->{'map'}->{$k});
    }
    elsif(defined($parent) && not $parent) { # child 
	$game->_map($k);
	exit;
    }
    else {
	die("can't fork test : $!");
    }
}

##############################

undef $/;

SKIP:{
  skip ": only if you have Term::ANSIColor", 14
    unless( $Games::Mines::Play::loaded_ansi_color );
  
  srand 2; # so we always get the same field.
  
  $game = Games::Mines::Play->new(3,3,2);
  $game->fill_mines;
  $game->set_ANSI_Color;
  
  foreach my $k (keys %{$game->{'map'}}) {
    
    $parent = open(TEST1,"-|");
    
    if($parent) {
      $line=<TEST1>;
      close(TEST1) or warn(" can't close child pid $parent : $!");
      
      is($line,$game->{'map'}->{$k});
    }
    elsif(defined($parent) && not $parent) { # child 
      $game->_map($k);
      exit;
    }
    else {
      die("can't fork test : $!");
    }
  }
}




