package Games::Lineofsight;

use 5.008;
use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(get_barriers analyze_map lineofsight) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '1.0';

use Math::Complex;

# returns map where the non-visible squares are replaced with $hidden_str
# $map          == reference to $map[$width][$height]
# $man_x,$man_y == location of the viewer
# $barrier_str  == the square in the map that identifies the barrier; for example "X"
# $hidden_str   == string that replaces non-visible squares
sub lineofsight{
   my($map,$man_x,$man_y,$barrier_str,$hidden_str)=@_;
   my($width)=scalar(@{@$map[0]});
   my($height)=scalar(@$map);

   # read the barriers
   my %barrier=get_barriers($width,$height,\@$map,$barrier_str);

   # recreate the map and replace the squares behind the barriers with $hidden_str
   my @map2=analyze_map($width,$height,\@$map,\%barrier,$man_x,$man_y,$hidden_str);

   return(@map2);
}

# returns barrier coordinates in a hash needed for analyze_map() -subroutine
# $width        == width of the map
# $height       == height of the map
# $map          == reference to $map[$width][$height]
# $barrier_str  == the square in the map that identifies the barrier; for example "X"
sub get_barriers{
   my($width,$height,$map,$barrier_str)=@_;
   my($i,$j)=undef;
   my %barrier=();
   for($i=0;$i < $height;$i++){
      for($j=0;$j < $width;$j++){
         $barrier{"$i,$j"}=1 if($$map[$i][$j] =~ /$barrier_str/);
      }
   }
   return %barrier;
}

# returns map where the non-visible squares are replaced with $hidden_str
# $width        == width of the map
# $height       == height of the map
# $map          == reference to $map[$width][$height]
# $barrier      == reference to barrier hash. Hash can be generated using the get_barriers() -subroutine.
# $man_x,$man_y == location of the viewer
# $hidden_str   == string that replaces non-visible squares
sub analyze_map{
   my($width,$height,$map,$barrier,$man_x,$man_y,$hidden_str)=@_;
   my($e,$i,$j,$hidden,$xx,$yy)=undef;
   my @map2=();
   for($i=0;$i < $height;$i++){
      for($j=0;$j < $width;$j++){

         # set the square visible
         $hidden=0;

         # browse all barriers
         foreach $e(keys %$barrier){

            # get the barrier x- and y- coordinate
            ($yy,$xx)=split ",",$e;

            # declare the location as hidden if it's behind this barrier
            if(($xx != $j || $yy != $i) && los($man_x,$man_y,$xx,$yy,$j,$i) < .5){
                $hidden=1;
                last;
            }
         }

         # set the location as hidden or normal to the output-map
         $map2[$i][$j]=($hidden ? $hidden_str : $$map[$i][$j]);

      }
   }
   return(@map2);
}

# checks if the viewer sees the chosen location because of a barrier
# returns <.5 if the viewer don't see the chosen location because of a barrier
# x1,y1 == location of the viewer
# x2,y2 == location of the barrier
# x3,y3 == location of the chosen position
sub los{
    my($x1,$y1,$x2,$y2,$x3,$y3)=@_;

    # line from the man to the barrier
    my $dx1=$x2-$x1;
    my $dy1=$y2-$y1;
    my $length1=sqrt($dx1*$dx1+$dy1*$dy1);
    return 10 unless($length1); # return if barrier and man overlap

    # line from the man to the chosen position
    my $dx2=$x3-$x1;
    my $dy2=$y3-$y1;
    my $length2=sqrt($dx2*$dx2+$dy2*$dy2);

    # return if the man and the chosen position overlap or
    # if the chosen position is nearer the man than the barrier
    return 10 if($length2 <= $length1 || !$length2); 

    # cut the line to the barrier to the same length than the line to the
    # chosen position
    my $lengthdivisor=$length2/$length1;
    $dx2/=$lengthdivisor;
    $dy2/=$lengthdivisor;

    # return the distance of the lines's heads
    my $ddx=$dx1-$dx2;
    my $ddy=$dy1-$dy2;
    return sqrt($ddx*$ddx+$ddy*$ddy);
}

1;

__END__

=head1 NAME

Games::Lineofsight

=head1 DESCRIPTION

Many games (Ultima, Nethack) use two-dimensional maps that consists of the squares of the same size in a grid. Line-of-sight means that some of the squares may represent the items that block the vision of the player from seeing squares behind them. With this module you can add that behaviour to your games.

=head1 SYNOPSIS

   use Games::Lineofsight qw(lineofsight);

   # The map has to be a two-dimensional array. Each member (or "cell") of the array represents one
   # square in the map. In this example each cell contains only one character but you can put strings
   # to the cells also - practical with the graphical games.

   my @map=(
      [split //,"..:..::........."], # this is the map
      [split //,".......:..X....:"], # . and : represents the ground
      [split //,"...X.....:...:.."], # X is the barrier for the sight
      [split //,".:...:....:....."],
      [split //,"..X....:..X....."],
      [split //,"..X..:........:."],
   );

   my($width)=scalar(@{@map[0]}); # the width of the map
   my($height)=scalar(@map);      # the height of the map
   my($barrier_str)="X";          # string that represents the barrier
   my($hidden_str)="*";           # string that represents a cell behind a barrier
   my($man_str)="@";           # string that represents the viewer 
   my($man_x,$man_y)=(7,3);       # view point coordinates - the player is here

   # recreate the map with line-of-sight

   @map=lineofsight(\@map,$man_x,$man_y,$barrier_str,$hidden_str);

   # draw the map

   for(my $i=0;$i < $height;$i++){
      for(my $j=0;$j < $width;$j++){
         print $man_x == $j && $man_y == $i ? $man_str : $map[$i][$j];
      }
      print "\n";
   }

=head2 or

   # The lineofsight() calls get_barriers() and analyze_map() each time it's called. If the viewer
   # moves around the map a lot, it's much faster to read in the barriers once and call only 
   # analyze_map() each time before drawing it.

   use Games::Lineofsight qw(get_barriers analyze_map);

   # The map has to be a two-dimensional array. Each member (or "cell") of the array represents one
   # square in the map. In this example each cell contains only one character but you can put strings
   # to the cells also - practical with the graphical games.

   my @map=(
      [split //,"..:..::........."], # this is the map
      [split //,".......:..X....:"], # . and : represents the ground
      [split //,"...X.....:...:.."], # X is the barrier for the sight
      [split //,".:...:....:....."],
      [split //,"..X....:..X....."],
      [split //,"..X..:........:."],
   );

   my($width)=scalar(@{@map[0]}); # the width of the map
   my($height)=scalar(@map);      # the height of the map
   my($barrier_str)="X";          # string that represents the barrier
   my($hidden_str)="*";           # string that represents a cell behind a barrier
   my($man_str)="@";           # string that represents the viewer
   my($man_x,$man_y)=(7,3);       # view point coordinates - the player is here

   # get_barriers() returns a hash with the information about barriers in the map. In this example we 
   # declare the "X"-character as a barrier. As well you can declare it to be a string in the graphical
   # games; for example "barrier.jpg".

   my %barrier=get_barriers($width,$height,\@map,$barrier_str);

   # analyze_map() returns an array containing the original map looked from the view point. The cells
   # behind the barriers are replaced with given strings. The barriers should be told to the subroutine
   # calling first get_barriers()-subroutine as we already did.

   my @map2=analyze_map($width,$height,\@map,\%barrier,$man_x,$man_y,$hidden_str);

   #draw the map with the lineofsight

   print "\nOriginal map:\n"; 

   draw($width,$height,$man_x,$man_y,\@map2,$man_str);

   # move the viewer two squares right
   
   $man_x+=2;
   
   # refresh the map
   
   my @map2=analyze_map($width,$height,\@map,\%barrier,$man_x,$man_y,$hidden_str);

   #draw the map again

   print "\nViewer has moved:\n"; 

   draw($width,$height,$man_x,$man_y,\@map2,$man_str);
   
   sub draw{
      my($width,$height,$man_x,$man_y,$map,$man_str)=@_;
      for(my $i=0;$i < $height;$i++){
         for(my $j=0;$j < $width;$j++){
            print $man_x == $j && $man_y == $i ? $man_str : $$map[$i][$j];
         }
         print "\n";
      }

   }

=head1 KNOWN BUGS

None.

=head1 AUTHOR

Ville Jungman

<ville_jungman@hotmail.com, ville.jungman@frakkipalvelunam.fi>

=head1 COPYRIGHT

Copyright 2004 Ville Jungman

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
