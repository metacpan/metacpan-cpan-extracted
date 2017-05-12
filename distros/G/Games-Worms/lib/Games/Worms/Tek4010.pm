# Time-stamp: "1999-03-03 19:54:20 MST" -*-Perl-*-
package Games::Worms::Tek4010;

use strict;
use Games::Worms::Tek4010::Seg;
use Games::Worms::Tek4010::Board;
use Games::Worms::Node;
use vars qw($Debug $VERSION @ISA);
use vars qw( $Start_tek $End_tek  $Pen_up $Pen_down );

# This module provides a Tektronics interface for Worms

$Debug = 0;
$VERSION = '0.60';

$Start_tek = "\x1b\cl";
$Pen_up    = "\x1F";
$Pen_down  = "\x1D";
$End_tek   = "\e[?38l";

#--------------------------------------------------------------------------
sub main {
  $| = 1;
  print $Start_tek;
  my $board = Games::Worms::Tek4010::Board->new(
						tri_base => 15,
						cells_wide => 66,
						cells_high => 70,
						aspect => 1.41,
					       );

  #good params:
  # tri_base => 15, cells_wide => 66, cells_high => 70, aspect => 1.41,


  $board->window_init;
  print tek_vector(1023,0,  1023, 780,  0,780, 0,0, 1023,0, ); # box
  $board->run(@ARGV);

  sleep 2;
  print $End_tek;

  print STDERR "Done.\n";

  my $c = 1;
  foreach my $worm (@{$board->{'worms'}}) {
    printf STDERR "worm $c\: %7d : $worm->{'name'}\n",
      $worm->segments_eaten;
    ++$c;
  }

  print STDERR map("$_ = $board->{$_}\n", sort keys %$board) if $Debug;
  return; # bye bye
}

#--------------------------------------------------------------------------
sub tek_vector {
  my(@vectors) = @_;
  my @out = ($Pen_down);
  while(@vectors) {
    push @out, &coord_XY(
			shift(@vectors) || 0,
			shift(@vectors) || 0,
		       );
  }
  push @out, $Pen_up;
  return @out;
}

#--------------------------------------------------------------------------
sub coord_XY {
  my($cx, $cy) = (int($_[0]), int($_[1]));

  return '' unless
    $cx >= 0 && $cx <= 1023 &&
    $cy >= 0 && $cy <= 780;

  $cy = 780 - $cy;
  # flip the thing so that 0,0 is the NW corner, not the SW corner, as
  #  Tek40xx systems could have it

  return pack("cccc",
            ($cy >> 5) + 32, ($cy & 31) + 96,
            ($cx >> 5) + 32, ($cx & 31) + 64 );
  # doesn't bother with any of that whole coord underspecification thing

}

# FS   1/12  1ch   ^\      Enter point plotting mode
# GS   1/13  1dh   ^]      Enter line drawing mode
# RS   1/14  1eh   ^^      Enter incremental line drawing mode
# US   1/15  1fh   ^_      Enter Tek text mode (leave line/point drawing)
#--------------------------------------------------------------------------
1;

__END__

