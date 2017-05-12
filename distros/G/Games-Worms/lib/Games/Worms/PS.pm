package Games::Worms::PS;

# This module provides a PostScript interface for Worms

use strict;
use Games::Worms::PS::Seg;
use Games::Worms::PS::Board;
use Games::Worms::Node;
use vars qw($Debug $VERSION @ISA);
use vars qw( $MAX_X $MAX_Y $ASPECT $WIDTH_INCHES $HEIGHT_INCHES );

$MAX_X = 10000;
$MAX_Y = 0;
$Debug = 0;
$VERSION = '0.60';

$ASPECT = 1.1;
$WIDTH_INCHES  = 7.5;
$HEIGHT_INCHES = 10;

#--------------------------------------------------------------------------
sub main {
  $| = 1;
  my $CELLS_WIDE = 100;
  my $CELLS_HIGH = 180;

  my $board = Games::Worms::PS::Board->new( tri_base => $MAX_X / $CELLS_WIDE,
					    cells_wide => $CELLS_WIDE,
					    cells_high => $CELLS_HIGH,
					    aspect => $ASPECT,
                                            inner_border => 0,
					   );
  $MAX_Y = $board->{'canvas_height'};

  print ps_init();
  $board->window_init;
  $board->run(@ARGV);

  print ps_end();

  my $c = 1;
  print "%         segs eaten: name\n";
  foreach my $worm (@{$board->{'worms'}}) {

    printf "%%  worm $c\: %8d : $worm->{'name'}\n",
      $worm->segments_eaten;
    ++$c;
  }

  print map("\%  $_ = $board->{$_}\n", sort keys %$board) if $Debug;
  print
    "\% Runtime: ", time - $^T, " seconds\n",
    "\% Generations: ", $board->{'generations'}, "\n", 
    "\cd";
  
  return; # bye bye
}


sub ps_vector {
  my(@vectors) = @_;
  return '' unless @vectors;
   # flip the coord system
  my @out = ( (shift(@vectors) || 0), ($MAX_Y - (shift(@vectors) || 0)), 'm' );
  while(@vectors) {
    push @out, (shift(@vectors) || 0), ($MAX_Y - (shift(@vectors) || 0)), 'l' ;
  }
  push @out, "s\n";
  return(join ' ', @out);
}

#--------------------------------------------------------------------------
sub ps_init {
  my $time = scalar(localtime);
  return <<"EOPSINIT";
%!
%\%Title: Worm Dump
%\%Creator: Games::Worms::PS v$VERSION
%\% by Sean M. Burke, <sburke\@netadventure.net>
%\%StartTime: $time

save /worms_sav exch def

/inch {72 mul} def
/xHome 0 def
/yHome 3071 def
/xLeftMarg 0 def
% Scale factor settings...  orig: 10.24 7.8
/dxWidInch $WIDTH_INCHES  def
/dyHtInch  $HEIGHT_INCHES def

% Now the space-saving aliases
/m /moveto load def    % move-to: args are x, y
/l /lineto load def    % line-to; args are x, y
/rl /rlineto load def  % relative line-to; args are delta-x, delta-y
/s /stroke load def    % stroke -- no args

% scale the coordinate space
% input: size of image area (x, y) in inches
/Scale_coords {72 $MAX_X dxWidInch div div 72 $MAX_Y dyHtInch div div scale} def
  % that's where we hardcode the coord system

% now the different line styles
/Ary_of_DashSolid [] def
/Ary_of_DashDotted [12 24] def
/Ary_of_DashDotDash [12 24 96 24] def
/Ary_of_DashShortDash [24 24] def
/Ary_of_DashLongDash [144 24] def
/Ary_of_Ary_of_Dash 
  [Ary_of_DashSolid Ary_of_DashDotted Ary_of_DashDotDash 
   Ary_of_DashShortDash Ary_of_DashLongDash] def

% input: line style index
/Set_line_style
    {Ary_of_Ary_of_Dash exch get dup length setdash } def

% To snap into landscape mode:
%  90 rotate 0 -8.5 inch translate

0.5 inch 0.5 inch translate   % translation for margins

Scale_coords  % using dxWidInch and dyHtInch

0 Set_line_style
 % tweak as desired

xHome yHome m
% start vectors

EOPSINIT

}

#--------------------------------------------------------------------------

sub ps_end {
  return <<'EOPSEND';
% end vectors
% Byebye now
showpage
grestore
worms_sav restore

EOPSEND
}

#--------------------------------------------------------------------------
1;

__END__

