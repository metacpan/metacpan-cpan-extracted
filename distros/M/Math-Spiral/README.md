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

## METHODS

## new

Usage is

    my $s = new Math::Spiral();

## Next

Returns the next x and y offsets (note that these start at 0,0 and will go negative to circle around this origin)

Usage is

    my($xo,$yo)=$s->Next();
    # Returns a sequnce like (0,0) (1,0) (1,1) (0,1) (-1,1) (-1,0) (-1,-1) (0,-1) (1,-1) (2,-1) ... etc (i.e. the x,y coordinates for a spiral)

## EXAMPLE

    #!/usr/bin/perl -w
      
    use Math::Spiral;

    my $s = new Math::Spiral(); # Optional - for non-square output, add an aspect ration here. e.g. new Math::Spiral(1024/768);

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

### Aspect Ratio feature

        perl -MMath::Spiral -e '$mx=30;@c=("a".."z","0".."9","A".."Z");$s=new Math::Spiral(220/1024); foreach(0..162) { $c=$c[$_%62]; ($xo,$yo)=$s->Next($c); warn "\033[31;1m Overwrite \033[0m ",$chart[$mx/2+$xo][$mx/2+$yo],"(",$xo,",",$yo,")" if(defined $chart[$mx/2+$xo][$mx/2+$yo]); $chart[$mx/2+$xo][$mx/2+$yo]=$c; &prt() if 0; } sub prt{foreach $y (0..$mx){foreach $x(0..$mx){if(defined($chart[$x][$y])){print $chart[$x][$y]} else {print " ";} } print "\n"}} &prt();' 

         Math::Spiral()     Spiral(220/1024)      Spiral(1024/480)                  

         6789ABC                6789AB           mnopqrstuvwxyz0123      
         5MNOPQRSTUVWX          uvwxyz           lGqrstuvwxyz0123H4      
         4LklmnopqrstY          ijklmn           kFpSABCDEFGHIJT4I5      
         3KjGHIJKLMNuZ          CDEFGH           jEoR9uoghijpvKU5J6      
         2JiFuvwxyzOva          BklmnI           iDnQ8tnfabkqwLV6K7      
         1IhEtghij0Pwb          AcdefJ           hCmP7smedclrxMW7L8      
         0HgDsfabk1Qxc          9UVWXK           gBlO6543210zyNX8M9      
         zGfCredcl2Ryd          8ABCDL           fAkjihgfedcbaZY9NA      
         yFeBqponm3Sze          79uvEM          CedcbaZYXWVUTSRQPOB      
         xEdA987654T0f          68qrFN            
         wDcbaZYXWVU1g          57mnGO            
         vCBA98765432h          46ijHP            
         utsrqponmlkji          35efIQ            
                                24abJR            
                                13dcKS            
                                02hgLT            
                                z1lkMU            
                                y0poNV            
                                xztsOW            
                                wyxwPX            
                                vTSRQY            
                                ubaZYZ            
                                tjihga            
                                srqpob            
                                hgfedc            
                                tsrqpo            
                                543210            
                                     C            
                               
                               
        perl -MMath::Spiral -e '$s=new Math::Spiral(); foreach(0..25) { ($xo,$yo)=$s->Next(); $chart[3+$xo][3+$yo]=$_; } foreach $y (0..6){foreach $x(0..6){if(defined($chart[$x][$y])){print chr(97+$chart[$x][$y])} else {print " ";} } print "\n"}'

         uvwxyz
         tghij 
         sfabk 
         redcl 
         qponm 

## EXPORT

None by default.

# AUTHOR

This module was written by Chris Drake `cdrake@cpan.org`

# COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
