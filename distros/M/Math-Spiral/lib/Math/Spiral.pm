package Math::Spiral;

use strict;
use warnings;

# perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Math/Spiral.pm  > README.md

=head1 NAME

Math::Spiral - Perl extension to return an endless stream of X, Y offset coordinates which represent a spiral shape


=head1 SYNOPSIS


    #!/usr/bin/perl -w
      
    use Math::Spiral;

    my $s = new Math::Spiral();
    my($xo,$yo)=$s->Next();


    # perl -MMath::Spiral -e '$s=new Math::Spiral(); foreach(0..9) { ($xo,$yo)=$s->Next(); $chart[2+$xo][2+$yo]=$_; } foreach $y (0..4){foreach $x(0..4){if(defined($chart[$x][$y])){print $chart[$x][$y]} else {print " ";} } print "\n"}'


=head1 DESCRIPTION

This module outputs an infinite sequence of coordinate offsets, which you can use to plot things in a spiral shape.
The numbers return "clockwise"; negate one if you want to go anti-clockwise instead.

It is useful for charting things where you need to concentrate something around the center of the chart.


=head2 METHODS

=head2 new

Usage is

    my $s = new Math::Spiral();


=head2 Next

Returns the next x and y offsets (note that these start at 0,0 and will go negative to circle around this origin)

Usage is

    my($xo,$yo)=$s->Next();
    # Returns a sequence like (0,0) (1,0) (1,1) (0,1) (-1,1) (-1,0) (-1,-1) (0,-1) (1,-1) (2,-1) ... etc (i.e. the x,y coordinates for a spiral)


=head2 EXAMPLE

    #!/usr/bin/perl -w
      
    use Math::Spiral;

    my $s = new Math::Spiral(); # Optional - for non-square output, add an aspect ration here. e.g. new Math::Spiral(1024/768);

    foreach(0..9) {
      ($xo,$yo)=$s->Next();	# Returns a sequence like (0,0) (1,0) (1,1) (0,1) (-1,1) (-1,0) (-1,-1) (0,-1) (1,-1) (2,-1) ... etc
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

=head3 Prints

 6789
 501 
 432 

=head3 Aspect Ratio feature

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

=head2 EXPORT

None by default.

=cut

require Exporter;

our @ISA = qw(Exporter);
our($VERSION)='1.02';
our($UntarError) = '';

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


sub new {
  my $class = shift;
  my $this={};
  $this->{aspect} = shift; $this->{aspect}=1 unless($this->{aspect});

  foreach(qw(xmin x y xdir ydir xmax ymin ymax forcex forcey skipy skipx)){ $this->{$_}=0; }
  $this->{ydir} = -1; # Initial case, so first result is (0,0)
  $this->{y} = 1; # Initial case, so first result is (0,0)

  bless $this,$class;
  return $this;
} # new


sub Next {
  my $this = shift;

  $this->{x}+=$this->{xdir};
  $this->{y}+=$this->{ydir};

  my($nx,$ny);

  if(     ($this->{x}>=$this->{xmax})&&($this->{xdir})) { # Hit max-right, and going sideways; change direction to down
    $this->{xdir}=0; $this->{ydir}=1;	# Change direction
    $this->{ymax}++; 			# Go one more than last time
    my $aspect=($this->{xmax}-$this->{xmin})/($this->{ymax}-$this->{ymin});
    if($this->{aspect}>1 && $this->{ymin} && $aspect<$this->{aspect}) { # skip first row
      $this->{forcey} ^=1; # clear if it was set, otherwise, set it.
      $this->{ymax}--; $this->{skipy}++;
    }
    if($this->{skipx}) { $this->{skipx}--; $ny=$this->{ymax}-1; }

  } elsif(($this->{y}<=$this->{ymin})&&($this->{ydir})) { # Hit max top, and going vertically; change direction to right
    $this->{xdir}=1; $this->{ydir}=0;
    $this->{xmax}++;
    if($this->{forcex}) {
      $this->{forcex} ^=1; # clear if it was set, otherwise, set it.
      $this->{xmax}--; $this->{skipx}=1;
    }
    if($this->{skipy}) { $this->{skipy}--; $nx=$this->{xmax}-1; }
    
  } elsif(($this->{x}<=$this->{xmin})&&($this->{xdir})) { # Hit max-left, and going sideways; change direction to up
    $this->{xdir}=0; $this->{ydir}=-1;
    $this->{ymin}--;
    if($this->{forcey}) {
      $this->{forcey} ^=1; # clear if it was set, otherwise, set it.
      $this->{ymin}++; $this->{skipy}++;
    }
    if($this->{skipx}) { $this->{skipx}--; $ny=$this->{ymin}+1; }

  } elsif(($this->{y}>=$this->{ymax})&&($this->{ydir})) { # Hit max bottom, and going vertically; change direction to left
    $this->{xdir}=-1; $this->{ydir}=0; 
    $this->{xmin}--;
    my $aspect=$this->{ymax} ? ($this->{xmax}-$this->{xmin})/($this->{ymax}-$this->{ymin}) : 0;
    if( $this->{aspect}<1 && $aspect>$this->{aspect} ) {
      $this->{forcex} ^=1; # clear if it was set, otherwise, set it.
      $this->{xmin}++; $this->{skipx}=1;
    }
    if($this->{skipy}) { $this->{skipy}--; $nx=$this->{xmin}+1; }

  }

  my @ret=($this->{x},$this->{y});
  $this->{x}=$nx if(defined($nx));
  $this->{y}=$ny if(defined($ny));
  return @ret;
} # Next

1;

__END__

=head1 AUTHOR

This module was written by Chris Drake F<cdrake@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

# perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Math/Spiral.pm  > README.md
