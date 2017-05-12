#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


use 5.010;
use strict;
use warnings;
use POSIX ();
use List::Util 'min', 'max';

# uncomment this to run the ### lines
use Smart::Comments;


{
  # vs spectrum
  require Image::Base::Text;
  my $prev = 0;
  my $diff_total = 0;
  my $diff_count = 0;
  my $prev_count = 0;
  my $prev_sq = 0;
  foreach my $r (1 .. 6000) {
    my $count = image_count($r) / 4;
    my $dcount = $count - $prev_count - 1;
    my $xfrac = (1 + sqrt(8*($r+0)**2-1))/4;
    # my $x = (2 + sqrt(8*($r+0)**2-4))/4;
    my $y = int($xfrac+.5);
    my $x = int($xfrac);
    my $extra = (($y-1)**2 + ($y+.5)**2) < $r*$r;
    $extra = ($x==$y); # && (($x^$y^1)&1);
    my $sq = $y + $y-1 + $extra;
    my $dsq = $sq - $prev_sq;
    my $star = ($dsq != $dcount ? "***" : "");
    # printf "%2d dc=%3d dsq=%4.2f  %s\n", $r, $dcount,$dsq, $star;

    $star = (int($sq) != $count ? "***" : "");
    printf "%2d c=%3d sq=%4.2f x=%4.2f,y=$y  %s\n", $r, $count,$sq,$x, $star;

    $prev_count = $count;
    $prev_sq = $sq;
  }
  exit 0;

  sub floor_half {
    my ($n) = @_;
    return int(2*$n)/2;
  }
}

{
  my $r = 5;
  my $w = 2*$r+1;
  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => $w,
                                      -height => $w);
  $image->ellipse (0,0, $w-1,$w-1, 'x');
  my $str = $image->save_string;
  print $str;
  exit 0;
}
{
  # wider ellipse() overlaps, near centre mostly
  my %image_coords;
  my $offset = 100;
  my $i;
  {
    package MyImageCoords;
    require Image::Base;
    use vars '@ISA';
    @ISA = ('Image::Base');
    sub new {
      my $class = shift;
      return bless {@_}, $class;
    }
    sub xy {
      my ($self, $x, $y, $colour) = @_;
      my $key = "$x,$y";
      if ($image_coords{$key}) {
        $image_coords{$key} .= ',';
      }
      $image_coords{$key} .= $i;
    }
  }
  my $width = 500;
  my $height = 494;
  my $image = MyImageCoords->new (-width => $width, -height => $height);
  for ($i = 0; $i < min($width,$height)/2; $i++) {
    $image->ellipse ($i,$i, $width-1-$i,$height-1-$i, $i % 10);
  }
  foreach my $coord (keys %image_coords) {
    if ($image_coords{$coord} =~ /,/) {
      print "$coord  i=$image_coords{$coord}\n";
    }
  }
  exit 0;
}
{
  # wider ellipse()
  require Image::Base::Text;
  my $width = 40;
  my $height = 10;
  my $image = Image::Base::Text->new (-width => $width, -height => $height);
  for (my $i = 0; $i < min($width,$height)/2; $i++) {
    $image->ellipse ($i,$i, $width-1-$i,$height-1-$i, $i % 10);
  }
  $image->save('/dev/stdout');
  exit 0;
}


{
  # average diff step 4*sqrt(2)
  require Image::Base::Text;
  my $prev = 0;
  my $diff_total = 0;
  my $diff_count = 0;
  foreach my $r (1 .. 1000) {
    my $count = image_count($r);
    my $diff = $count - $prev;
 #   printf "%2d %3d  %2d\n", $r, $count, $diff;
    $prev = $count;
    $diff_total += $diff;
    $diff_count++;
  }
  my $avg = $diff_total/$diff_count;
  my $sqavg = $avg*$avg;
  print "diff average $avg squared $sqavg\n";
  exit 0;
}
{
  # vs int(sqrt(2))
  require Image::Base::Text;
  my $prev = 0;
  my $diff_total = 0;
  my $diff_count = 0;
  my $prev_count = 0;
  my $prev_sq = 0;
  foreach my $r (1 .. 300) {
    my $count = image_count($r) / 4;
    my $dcount = $count - $prev_count - 1;
    my $sq = int(sqrt(2) * ($r+3));
    my $dsq = $sq - $prev_sq - 1;
    my $star = ($dsq != $dcount ? "***" : "");
    printf "%2d  %3d %3d  %s\n", $r, $dcount,$dsq, $star;
    $prev_count = $count;
    $prev_sq = $sq;
  }
  exit 0;
}

{
  # vs int(sqrt(2))
  my $prev = 0;
  my $diff_total = 0;
  my $diff_count = 0;
  foreach my $r (1 .. 500) {
    my $count = image_count($r);
    my $sq = 4*int(sqrt(2) * ($r+1));
    my $star = ($sq != $count ? "***" : "");
    printf "%2d  %3d %3d  %s\n", $r, $count,$sq, $star;
  }
  exit 0;
}




my $width = 79;
my $height = 23;

my @rows;
my @x;
my @y;
foreach my $r (0 .. 39) {
  my $rr = $r * $r;
  # E(x,y) = x^2*r^2 + y^2*r^2 - r^2*r^2
  #
  # Initially,
  #     d1 = E(x-1/2,y+1)
  #        = (x-1/2)^2*r^2 + (y+1)^2*r^2 - r^2*r^2
  # which for x=r,y=0 is
  #        = r^2 - r^2*r + r^2/4
  #        = (r + 5/4) * r^2
  #
  my $x = $r;
  my $y = 0;
  my $d = ($x-.5)**2 * $rr + ($y+1)**2 * $rr - $rr*$rr;
  my $count = 0;
  while ($x >= $y) {
    ### at: "$x,$y"
    ### assert: $d == ($x-.5)**2 * $rr + ($y+1)**2 * $rr - $rr*$rr

    push @x, $x;
    push @y, $y;
    $rows[$y]->[$x] = ($r%10);
    $count++;

    if( $d < 0 ) {
      $d += $rr * (2*$y + 3);
      ++$y;
    }
    else {
      $d += $rr * (2*$y - 2*$x + 5);
      ++$y;
      --$x;
    }
  }
  my $c = int (2*3.14159*$r/8 + .5);
  printf "%2d %2d %2d  %s\n", $r, $count, $c, ($count!=$c ? "**" : "");
}

foreach my $row (reverse @rows) {
  if ($row) {
    foreach my $char (@$row) {
      print ' ', $char // ' ';
    }
  }
  print "\n";
}


{
  require Math::PlanePath::PixelRings;
  my $path = Math::PlanePath::PixelRings->new (wider => 0,
                                               # step => 0,
                                              );
  ### range: $path->rect_to_n_range (0,0, 0,0)
  exit 0;
}

{
  # search OEIS
  require Image::Base::Text;
  my @count4;
  my @count;
  my @diffs4;
  my @diffs;
  my @diffs0;
  my $prev_count = 0;
  foreach my $r (1 .. 50) {
    my $count = image_count($r);
    push @count4, $count;
    push @count, $count/4;
    my $diff = $count - $prev_count;
    push @diffs4, $diff;
    push @diffs, $diff/4;
    push @diffs0, $diff/4 - 1;
    $prev_count = $count;
  }
  print "count4: ", join(',', @count4), "\n";
  print "count:  ", join(',', @count), "\n";
  print "diffs4: ", join(',', @diffs4), "\n";
  print "diffs:  ", join(',', @diffs), "\n";
  print "diffs0: ", join(',', @diffs0), "\n";
  exit 0;
}

sub image_count {
  my ($r) = @_;
  my $w = 2*$r+1;
  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => $w,
                                      -height => $w);
  $image->ellipse (0,0, $w-1,$w-1, 'x');
  my $str = $image->save_string;
  my $count = ($str =~ tr/x/x/);
  return $count;
}

