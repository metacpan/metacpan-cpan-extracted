#!/usr/bin/perl -w

# display a GcodeXY generated gcode file on a Tk canvas

use Tk;
use Tk::Button;
use strict;
use warnings;

# configurable parameters:
my $xres       = 1920;         # screen resolution
my $yres       = 1080;
my $xsize      = 1840;         # screen size in pt
my $ysize      = 956;
my $m2i        = 1.0;          # mm to inch scale factor - 1 inch = 25 mm
                               # set it to 25.0 for gcode that uses mm
                               # we are using inches internally as default
my $pdcmd1     = "G00 Z 0.2";  # pen down command - may need tweaking - inch version
my $pdcmd2     = "G00 Z 5.0";  # pen down command - may need tweaking - mm version
# end configurable parameters


my $pucmd1     = "G00 Z 0";
my $pucmd2     = "G00 Z 0.0";
my $inchcmd    = "G20";        # inches used
my $mmcmd      = "G21";        # mm used
my $i2p        = 72.0;         # inches to points (for canvas translation), normally 72.0
my $geom       = $xres . 'x' . $yres;  # window size

# opcodes
my $PU         = 1;            # penup line
my $PD         = 2;            # pendown line
my $G00        = 3;            # G00 line
my $G01        = 4;            # G01 line
my $NOOP       = 5;            # ignore this line

# current line
my $op         = "";           # current op
my $xn         = "";           # current x coord
my $yn         = "";           # current y coord

# counters
my $linecount  = 0;            # gcode input line count
my $emitcount  = 0;            # ditto for output

# bounding box
my $maxx       = 0.0;
my $maxy       = 0.0;
my $minx       = 100.0;
my $miny       = 100.0;

my ($x, $y);

# start of main - open files
my $gcin = shift || die "input file missing";
open (my $in  ,  '<', $gcin) or die "cannot open input file  $gcin";

doheader($in);

# now the GUI
my $top = MainWindow->new();
$top->geometry ($geom);
my $lf  = $top->Frame( -width  => 20,   -borderwidth => '1', -relief => 'solid')->pack(-side => 'left');
$lf->Button(-text => "quit", -command => sub{exit})->pack;
my $canvas = $top->Scrolled('Canvas',width => $xres, height => $yres)->pack(-expand => 1, -fill => 'both');
#my @coords = (0, 0);
my @coords = ($xsize, $ysize); # start at the origin

# now the file
while (<$in>) {
      $linecount++;
      chomp;
      ($op, $xn, $yn) = parse($_);  # xn and yn in inches
      # create the lines
      if ($op == $PU) {
            @coords = ();
      }
      if ($op == $G00) {
            push @coords, ($xsize-$yn*$i2p), ($ysize-$xn*$i2p);
      }
      if ($op == $G01) {
            if (scalar @coords > 2) {
                  shift @coords;
                  shift @coords;
            }
            push @coords, ($xsize-$yn*$i2p), ($ysize-$xn*$i2p);
            $canvas->createLine(@coords);
            #printline($_);
      }
}

$top->update();
MainLoop();

exit;

################### end main ################################################

#debugging
sub printcoords {
      print "coords at $linecount " . shift . ": ";
      print join " ", @coords;
      print "\n";
}

sub printline {
      print "canvas line at $linecount " . shift . ": ";
      print "from (" . $coords[0] . "," . $coords[1] . ") to (" . $coords[2] . "," . $coords[3] . ")\n";
      print "\n";
}

# ignore the header, switch to mm if necessary
sub doheader {
my $in = shift;
      # ignore the header, except for the mm/inch part
      while (<$in>) {
            $linecount++;
            #print "header $linecount: $_";
            chomp;
            if ($_ =~ /^G21/) {$m2i = 25.0}  # we are using mm
            last if ($_ eq $pucmd1 || $_ eq $pucmd2); # better make sure it's the last one!
      }
}

# quit with error message and line number
sub quit {
      die shift . " at line $linecount";
}

# parsing of new instruction
sub parse {
my ($ss, $opp, $x, $xcoord, $y, $ycoord);
      $ss = shift;

      # some lines can be ignored
      if ($ss =~ /^\s*$/)  {return ($NOOP, 0,0)} # ignore empty line
      if ($ss =~ /^\s*\(/) {return ($NOOP, 0,0)} # ignore comment line

      # do some standardization, different tools have different gcode formats
      $ss =~ s/X/X /;  # in case there is no space after X or Y or Z
      $ss =~ s/Y/Y /;
      $ss =~ s/Z0/Z 0/;
      $ss =~ s/G0 /G00 /; # G0 equivalent to G00
      $ss =~ s/G1 /G01 /; # G1 equivalent to G01
      $ss =~ s/ \.000/ 0\.000/g; # turns .0 into 0.0

      ($opp, $x, $xcoord, $y, $ycoord) = split(/ +/, $ss);   # split on multiple spaces

      if ($ss eq $pucmd1) {
            return ($PU, "0", "0");
      }
      if ($ss eq $pucmd2) {
            return ($PU, "0", "0");
      }
      if ($ss =~ /G00 Z / || $ss =~ /G01 Z /) {
            return ($PD, "0", "0");
      }
      if ($opp eq "G00") {
            return ($G00, $xcoord/$m2i, $ycoord/$m2i);
      }
      if ($opp eq "G01") {
            return ($G01, $xcoord/$m2i, $ycoord/$m2i);
      }
      quit("parse: unknown instruction \"$ss\"");
}
