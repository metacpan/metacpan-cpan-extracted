# NAME

Math::Spiral - Perl extension to return an endless stream of X, Y offset coordinates which represent a spiral shape

# SYNOPSIS

    #!/usr/bin/perl -w
      
    use Math::Spiral;

    my $s = new Math::Spiral();
    my($xo,$yo)=$s->Next();


    # perl -MMath::Spiral -e '$s=new Math::Spiral(); foreach(0..9) { ($xo,$yo)=$s->Next(); $chart[2+$xo][2+$yo]=$_; } foreach $y (0..4){foreach $x(0..4){if(defined($chart[$x][$y])){print $chart[$x][$y]} else {print " ";} } print "\n"}'

# DESCRIPTION

This module outputs an infinte sequence of coordinate offsets, which you can use to plot things in a spiral shape.
The numbers return "clockwise"; negate one if you want to go anti-clockwise instead.

It is useful for charting things where you need to concentrate something around the center of the chart.

## EXAMPLE

    #!/usr/bin/perl -w
      
    use Math::Spiral;

    my $s = new Math::Spiral();

    foreach(0..9) {
      ($xo,$yo)=$s->Next();     # Returns a sequnce like (0,0) (1,0) (1,1) (0,1) (-1,1) (-1,0) (-1,-1) (0,-1) (1,-1) (2,-1) ... etc
      $chart[2+$xo][2+$yo]=$_;
    }

    foreach $y (0..4) {
      foreach $x(0..4) {
        if(defined($chart[$x][$y])) { 
          print $chart[$x][$y] 
        } else {
          print " ";
        }
      }
      print "\n"
    }

### Prints

    6789
    501 
    432 

## EXPORT

None by default.

## Notes

## new

Usage is

    my $s = new Math::Spiral();

## Next

Returns the next x and y offsets (note that these start at 0,0 and will go negative to circle around this origin)

Usage is

    my($xo,$yo)=$s->Next();
    # Returns a sequnce like (0,0) (1,0) (1,1) (0,1) (-1,1) (-1,0) (-1,-1) (0,-1) (1,-1) (2,-1) ... etc (i.e. the x,y coordinates for a spiral)

# AUTHOR

This module was written by Chris Drake `cdrake@cpan.org`

# COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
