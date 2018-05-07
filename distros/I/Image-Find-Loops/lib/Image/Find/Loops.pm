#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Image::Find::Loops - Find loops in an image.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
# Estimate thickness of loop
package Image::Find::Loops;
our $VERSION = "20180506";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use utf8;

sub indent{4}                                                                   # Print indentation amount

#1 Methods                                                                      # Find loops in an image.

sub new($)                                                                      #S Find loops in an image represented as a string.
 {my ($string) = @_;                                                            # String of blanks; non blanks; new lines defining the image
  my @lines = split /\n/, $string;
  my $count;                                                                    # Number of active pixels
  my %image;                                                                    # {x}{y} of active pixels
  my $x;                                                                        # Image dimension in x

  for   my $j(0..$#lines)                                                       # Load active pixels
   {my $line = $lines[$j];
    $x = length($line) if !defined($x) or length($line) > $x;                   # Longest line
    for my $i(0..length($line)-1)                                               # Parse each line
     {$image{$i}{$j} = 0, $count++ if substr($line, $i, 1) ne q( );             # Areas not in drawn loops
     }
   }

  my $d = bless{image=>\%image, x=>$x, y=>scalar(@lines), count=>$count,        # Create image of loops
                bounds=>{}, partitions=>{}, partitionLoop=>{}};

  $d->partitionImage(1);                                                        # Partition the image ignoring stray pixels
  $d->fillPartition(1);                                                         # Fill the interior of each parition
  $d->removeInteriorOfPartition($_) for 1..$d->numberOfLoops;                   # Remove the interior of each partition except  at the edges to leave the exterior loop
  $d->findLongestLoop($_)           for 1..$d->numberOfLoops;                   # Find the longest path in the exterior edge - this must be the loop described by the partition
  $d->widthOfLoop($_)               for 1..$d->numberOfLoops;                   # Add Loop width estimate at each point
  $d                                                                            # Return new image with path details
 } # new


sub fillPartition($$)                                                           #P Remove any interior voids in a partition.
 {my ($i, $partition) = @_;                                                     # Image, partition
  my $p = $i->partitions->{$partition};                                         # Pixels in partition
  my $b = $i->bounds->{$partition};                                             # Rectangular bounding area of partition
  my ($x1, $y1, $x2, $y2) = @$b;                                                # Rectangle bounding the partition
  my %image;                                                                    # The image of the inverted partition restricted to the bounding arae
  my $count = 0;                                                                # Number of pixels in th image of the inverted partition

  for   my $x($x1..$x2)                                                         # Define the image of the inverted partition
   {for my $y($y1..$y2)
     {next if defined $p->{$x}{$y};
      $image{$x}{$y} = 0; ++$count;
     }
   }

  my $I = bless
   {%$i, image=>\%image, count=>$count, bounds=>{1=>$b}, partitions=>{}};       # Create image of inverted partition

  $I->partitionImage(0);                                                        # Partition the image of the inverted partition considering partitions of all sizes

  my %ignore;                                                                   # Ignore the partitions of the inverted image that touch the border of the original partition as the touch confirms that they are part of the exterior
  for my $invertedPartition(sort keys %{$I->partitions})                        # Each partition of the image of the inverted partition
   {my $p = $I->partitions->{$invertedPartition};
    First:                                                                      # Each pixel in the current partition of the inverted partition
    for   my $x(keys % $p)
     {for my $y(keys %{$p->{$x}})
       {if ($x == $x1 || $x == $x2 and $y == $y1 || $y == $y2)                  # This partition touches the border so we know that all of this partition is part of the exterior
         {$ignore{$invertedPartition}++;
          last First;
         }
       }
     }
   }

  for my $invertedPartition(sort keys %{$I->partitions})                        # Fill in the internal partitions in the original partition so that any internal voids become filled
   {next if $ignore{$invertedPartition};                                        # Ignore exterior partitions to leave just the interior partitions
    my $P = $I->partitions->{$invertedPartition};
    for   my $x(keys % $P)                                                      # Each pixel of an interior partition of the inverted original partition
     {for my $y(keys %{$P->{$x}})
       {$p->{$x}{$y} = $partition;                                              # Fill in an interior pixel that was void in the original partition
       }
     }
   }
 } # fillPartition

sub clone($)                                                                    #P Clone an image.
 {my ($i) = @_;                                                                 # Image

  my %partitions;                                                               # Clone partitions
  for     my $p(keys %{$i->partitions})
   {for   my $x(keys %{$i->partitions->{$p}})
     {for my $y(keys %{$i->partitions->{$p}{$x}})
       {$partitions{$p}{$x}{$y}++# = $i->partitions->{$p}{$x}{$y};
       }
     }
   }

  bless {%$i, partitions=>\%partitions};                                        # Cloned image
 } # clone

sub clonePartition($$)                                                          #P Clone a partition of an image.
 {my ($i, $partition) = @_;                                                     # Image, partition
  my %partition;                                                                # Cloned partition

  for   my $x(keys %{$i->partitions->{$partition}})
   {for my $y(keys %{$i->partitions->{$partition}{$x}})
     {$partition{$x}{$y} = $i->partitions->{$partition}{$x}{$y};
     }
   }

  my $I = bless {%$i};                                                          # Clone image quickly
  $I->partitions = {%{$i->partitions}};                                         # Clone partitions quickly
  $I->partitions->{$partition} = \%partition;                                   # Replace cloned partition
  $I                                                                            # Return new image
 } # clonePartition

sub numberOfLoops($)                                                            # Number of loops in the image.  The partitions and loops are numbered from 1.
 {my ($i) = @_;                                                                 # Image
  scalar(keys %{$i->partitions})
 } # numberOfLoops

sub partitionImage($$)                                                          #P Partition the  images into disjoint sets of connected points.
 {my ($i, $small) = @_;                                                         # Image, minimum size of a partition - smaller partitions will be ignored

  for   my $x(sort{$a<=>$b} keys %{$i->image})                                  # Stabilize partition numbers to make testing possible
   {for my $y(sort{$a<=>$b} keys %{$i->image->{$x}})
     {my $p = $i->image->{$x}{$y};
      $i->mapPartition($x, $y, $small) if defined($p) and $p == 0;              # Bucket fill anything that touches this pixels
     }
   }
 } # partitionImage

sub mapPartition($$$$)                                                          #P Locate the pixels in the image that are connected to a pixel with a specified value.
 {my ($i, $x, $y, $small) = @_;                                                 # Image, x coordinate of first point in partition, y coordinate of first point in partition, delete partitions of fewer pixels
  my $p = $i->image->{$x}{$y} = $i->numberOfLoops+1;                            # Next partition
  $i->partitions->{$p}{$x}{$y}++;                                               # Add first pixel to this partition
  my $pixelsInPartition = 0;

  my ($x1, $x2, $y1, $y2);                                                      # Rectangle bounding the partition
  for(1..$i->count)                                                             # Worst case - each pixel is a separate line
   {my $changed = 0;                                                            # Number of pixels added to this partition on this pass
    for   my $x(keys %{$i->image})                                              # Each pixel
     {for my $y(keys %{$i->image->{$x}})
       {next if $i->image->{$x}{$y} == $p;                                      # Already partitioned
        my $I = $i->image;
        my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);
        if (exists($I->{$𝘅}) && exists($I->{$𝘅}{$y}) && $I->{$𝘅}{$y} == $p or   # Add this pixel to the partition if a neigboring pixel exists and is already a part of the paritition
            exists($I->{$x}) && exists($I->{$x}{$𝘆}) && $I->{$x}{$𝘆} == $p or
            exists($I->{$𝕩}) && exists($I->{$𝕩}{$y}) && $I->{$𝕩}{$y} == $p or
            exists($I->{$x}) && exists($I->{$x}{$𝕪}) && $I->{$x}{$𝕪} == $p)
         {$i->image->{$x}{$y} = $p;
          ++$changed;
          ++$i->partitions->{$p}{$x}{$y};                                       # Pixels in this partition
          ++$pixelsInPartition;
          $x1 = $x if !defined($x1) or $x1 > $x;                                # Rectangular bounds for partition
          $x2 = $x if !defined($x2) or $x2 < $x;
          $y1 = $y if !defined($y1) or $y1 > $y;
          $y2 = $y if !defined($y2) or $y2 < $y;
         }
       }
     }
    last unless $changed;                                                       # No more pixels in parition to consider
   }

  if ($pixelsInPartition <= $small)                                             # Remove small partitions
   {for   my $x(keys %{$i->image})
     {for my $y(keys %{$i->image->{$x}})
       {delete $i->image->{$x}{$y} if            $i->image->{$x}{$y} == $p;
        delete $i->image->{$x}     unless keys %{$i->image->{$x}};              # Remove containing hash if now empty
       }
     }
    delete $i->partitions->{$p}
   }
  else
   {$i->bounds->{$p} = [$x1, $y1, $x2, $y2];                                    # Record bounds
   }
 } # mapPartition

sub removeInteriorOfPartition($$)                                               #P Remove the interior of a partition to leave the exterior loop.
 {my ($I, $partition) = @_;                                                     # Image, partition
  my $i = $I->clonePartition($partition);
  my $p = $i->partitions->{$partition};                                         # Each point in image

  for   my $x(keys % $p)                                                        # Zero out the interior
   {for my $y(keys %{$p->{$x}})
     {my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);

      $p->{$x}{$y} = 0 if                                                       # Zero an element theat does not touch the exterior of the partition
        exists $p->{$x}{$𝕪} and exists $p->{$x}{$𝘆} and
        exists $p->{$𝘅}{$y} and exists $p->{$𝘅}{$𝘆} and exists $p->{$𝘅}{$𝕪} and
        exists $p->{$𝕩}{$y} and exists $p->{$𝕩}{$𝘆} and exists $p->{$𝕩}{$𝕪};
     }
   }

  for   my $x(keys % $p)                                                        # The remaining pixels are the exterior edge of the partition
   {for my $y(keys %{$p->{$x}})
     {delete $I->partitions->{$partition}{$x}{$y} unless $p->{$x}{$y};
     }
   }
 } # removeInteriorOfPartition

sub findLongestLoop($$)                                                         #P Find the longest loop in a partition.
 {my ($I, $partition) = @_;                                                     # Image, partition
  my $i = $I->clonePartition($partition);
  my $p = $i->partitions->{$partition};                                         # Pixels in the partition

  my $break = sub
   {for   my $x(sort keys % $p)                                                 # Break the loop into a path
     {for my $y(sort keys %{$p->{$x}})
       {return [$x, $y];
       }
     }
    confess "No pixels in partition $partition?";                               # This should not happen!
   }->();

  my ($x, $y) = @$break;                                                        # The start/end point for this partition
  delete $p->{$x}{$y};                                                          # Break the loop to get to end points that we can find the shortest path between
  my ($start, $end) = $i->searchArea($partition, $x, $y);                       # Start and end points
  $start or confess "No start point";
  $end   or confess "No end point";
  my ($X, $Y) = @$end;                                                          # Coordinates of end point
  my @loop = $start;                                                            # Start the path
  my @longestLoop;                                                              # Shortest path so far
  my @search = [$i->searchArea($partition, @$start)];                           # Initial search area is the pixels around the start pixel
  my %visited;                                                                  # Pixels we have already visited along the possible path

  while(@search)                                                                # Find the shortest path amongst all the possible paths
   {@loop == @search or confess "Search and path depth mismatch";               # These two arrays must stay in sync because their dimensions reflects the progress along the possible path
    my $search = $search[-1];                                                   # Pixels to search for latest path element
    if (!@$search)                                                              # Nothing left to search at this level
     {pop @search;                                                              # Remove search level
      my ($x, $y) = @{pop @loop};                                               # Pixel to remove from possible path
      delete $visited{$x}{$y};                                                  # Pixel no longer visited on this possible path
     }
    else
     {my ($x, $y) = @{pop @$search};                                            # Next pixel to add to path
      next if $visited{$x}{$y};                                                 # Pixel has already been vsisited on this path so skip it
      if ($x == $X and $y == $Y)
       {@longestLoop = @loop if !@longestLoop or @loop > @longestLoop;
        my ($x, $y) = @{pop @loop};                                             # Pixel to remove from possible path
        pop @search;                                                            # any other adjacent pixels will not produce a shorter path
        delete $visited{$x}{$y};                                                # Pixel no longer visited on this possible path
       }
      else                                                                      # Extend the search
       {push @loop, [$x, $y];                                                   # Extend the path
        $visited{$x}{$y}++;
        push @search,                                                           # Extend the search area to pixels not already visited on this path
         [grep {my ($x, $y) = @$_; !$visited{$x}{$y}}
            $i->searchArea($partition, $x, $y)]
       }
     }
   }

  $I->partitionLoop->{$partition} = [$break, @longestLoop, $end]                # Return the shortest path from start to end and the break point to make a loop
 } # findLongestLoop

sub searchArea($$$$)                                                            #P Return the pixels to search from around a given pixel.
 {my ($i, $partition, $x, $y) = @_;                                             # Image, partition, x coordinate of center of search, y coordinate of center of search.
  my $p = $i->partitions->{$partition};
  my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);
  my @s;                                                                        # Pixels to search from
  push @s, [$𝘅, $y] if exists $p->{$𝘅}{$y};
  push @s, [$x, $𝘆] if exists $p->{$x}{$𝘆};
  push @s, [$x, $𝕪] if exists $p->{$x}{$𝕪};
  push @s, [$𝕩, $y] if exists $p->{$𝕩}{$y};
  @s                                                                            # Return all possible pixels
 } # searchArea

sub widthOfLoop($$)                                                             #P Find the (estimated) width of the loop at each point.
 {my ($I, $partition) = @_;                                                     # Image, partition
  my $i = $I->clonePartition($partition);                                       # Clone the specified partition so that we can remove pixels once they have been processed to spped up the remaining search
  my $loop = $i->partitionLoop->{$partition};                                   # Loop in image
  my $maxSteps = @$loop;

  for my $step(keys @$loop)                                                     # Each pixel in the path
   {my ($x, $y) = @{$$loop[$step]};

    my $explore = sub                                                           #P Explore away from a point checking that we are still in the partition associated with the Loop
     {my ($dx, $dy) = @_;                                                       # x direction, y direction
      for my $step(1..$maxSteps)                                                # Maximum possible width
       {return $step-1 unless $i->partitions->{$partition}                      # Keep stepping whilst still in partition
         {$x+$step*$dx}
         {$y+$step*$dy};
       }
      $maxSteps                                                                 # We never left the partition
     };

    push @{$I->partitionLoop->{$partition}[$step]}, 1 + min                     # Explore in opposite directions along 4 lines and take the minimum as the width
     ($explore->(1,  0) + $explore->(-1,  0),
      $explore->(1,  1) + $explore->(-1, -1),
      $explore->(0,  1) + $explore->( 0, -1),
      $explore->(1, -1) + $explore->(-1, +1));
   }
 } # widthOfLoop

sub loop($$)                                                                    # Return an array of arrays [x, y] of sequentially touching pixels describing the largest loop in the specified partition where the loops in an image are numbered from 1.
 {my ($i, $partition) = @_;                                                     # Image, partition
  $i->partitionLoop->{$partition}                                               # Return the loop
 } # loop

sub printLoop($$)                                                               # Print a loop in the image numbering pixels with the estimated thickness of the loop.
 {my ($i, $partition) = @_;                                                     # Image, partition
  my $X = $i->x; my $Y = $i->y;                                                 # Image dimensions
  my $s =  ' ' x $X;                                                            # Image line
  my @s = ($s) x $Y;                                                            # Image lines
  my $p = $i->partitionLoop->{$partition};                                      # Each point in image
  my $c = 0;                                                                    # Cycle though 0..9 to show loop

  my $plot = sub                                                                # Plot a pixel
   {my ($x, $y, $symbol) = @_;
    substr($s[$y], $x, 1) = $symbol % 10 if $y< $Y and $x < $X;
   };

  $plot->(@$_) for @$p;                                                         # Plot each pixel in the loop

  my ($x1, $y1, $x2, $y2) = my @bounds = @{$i->bounds->{$partition}};           # Bounds
  $x1--, $x2++ while $x1 > 0 and $x2 < $X-1 and $x2 - $x1 <= 10;
  $y1--, $y2++ while $y1 > 0 and $y2 < $Y-1;
  my ($xl, $yl)           = ($x2-$x1+1, $y2-$y1+1);                             # Lengths

  my $h = sub                                                                   # Header layout
   {my ($space) = @_;
    my $N = 1 + int($X/10);
    my $s = join '',
            map{substr($_, -1) ? q( ) : $_ > 9 ? substr($_, -2, 1) : 0} 0..$X;
    my $t = substr(("0123456789"x(1 + int($X/10))), 0, $X);
    $s = substr($s, $x1, $xl);
    $t = substr($t, $x1, $xl);
    "$space $s\n$space $t\n"
   }->(" " x indent);

  my $m =                                                                       # Loop layout
    join "\n",
      map{sprintf("%".indent."d ", $_).substr($s[$_].(q( )x$X), $x1, $xl)}
        grep{$_ >= $y1 and $_ <= $y2}
        keys @s;

  my $f = "Image: X = $X, Y = $Y, Loop = $partition";                           # Footer layout

  join "\n", $h, $m, $f;
 } # printLoop

sub print($)                                                                    # Print the loops in an image sequentially numbering adjacent pixels in each loop from 0..9.
 {my ($i) = @_;                                                                 # Image
  my $X = $i->x; my $Y = $i->y;                                                 # Image dimensions
  my $s =  ' ' x $X;                                                            # Image line
  my @s = ($s) x $Y;                                                            # Image lines

  for my $partition(1..$i->numberOfLoops)                                       # Each partition
   {my $p = $i->partitionLoop->{$partition};                                    # Each point in image
    my $c = 0;                                                                  # Cycle though 0..9 to show loop

    my $plot = sub                                                              # Plot a pixel
     {my ($x, $y) = @_;
      substr($s[$y], $x, 1) = (++$c % 10) if $y < $Y and $x < $X;
     };

    $plot->(@$_) for @$p;                                                       # Plot each pixel in the loop
   }

  my $h = sub                                                                   # Header layout
   {my ($space) = @_;
    my $N = 1 + int($X/10);
    my $s = join '',
            map{substr($_, -1) ? q( ) : $_ > 9 ? substr($_, -2, 1) : 0} 0..$X;
    my $t = substr(("0123456789"x(1 + int($X/10))), 0, $X);
    "$space $s\n$space $t\n"
   }->(" " x indent);

  my $m = join "\n", map{sprintf("%".indent."d ", $_).$s[$_]} keys @s;          # Loop layout

  my $f = "Image: X = $X, Y = $Y, Loops = ".$i->numberOfLoops;                  # Footer layout

  join "\n", $h, $m, $f;
 } # print

#1 Attributes                                                                   # Attributes of an image

BEGIN{
genLValueScalarMethods(q(bounds));                                              # The bounds of each partition: [$x1, $y1, $x2, $y2].
genLValueScalarMethods(q(count));                                               # Number of points in the image.
genLValueScalarMethods(q(image));                                               # Image data points.
genLValueScalarMethods(q(partitions));                                          # Number of partitions in the image.
genLValueScalarMethods(q(partitionLoop));                                       # Loop for each partition.
genLValueScalarMethods(q(x));                                                   # Image dimension in x.
genLValueScalarMethods(q(y));                                                   # Image dimension in y.
 }

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Image::Find::Loops - Find loops in an image.

=head1 Synopsis

Use L<new|/new> to create and analyze a new image, then L<print|/print> to
visualize the loops detected, or L<loop|/loop> to get the coordinates of
points in each loop in sequential order.

=head1 Description

Find loops in an image.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Methods

Find loops in an image.

=head2 new($)

Find loops in an image represented as a string.

     Parameter  Description
  1  $string    String of blanks; non blanks; new lines defining the image

Example:


  my $d = new (<<END);

       11                       11111111111        11111111111
      1111                      1         1        1         1
     11  11    1111             1   111   1        1         1              1
     11  11    11 11            1   1 1   1        1         1
     11  11    11 11            1   1 1   1        1         1
      1111     11111            1   1 1   1        1         1
       11      1111             1   1 1   1111111111         1                  1
                 1111           1   1 1   1111111111         1            1
                11111           1   1 1   1        1         1
        111111111111111111      1   1 1   1        1         1
        11    1111111111        1   111   1        1         1                1
        1      11111111         1         1        1         1
       11111111111              1         1        1         1
                111             11111111111        11111111111

  END

  ok nws($d->print) eq nws(<<END);
       0         1         2         3         4         5         6         7
       0123456789012345678901234567890123456789012345678901234567890123456789012345678
     0
     1      56                       12345678901        23456789012
     2     3478                      8         2        1         3
     3    12  90    1234             7   432   3        0         4
     4    2    1    09 5             6   5 1   4        9         5
     5    10  32    78 67            5   6 0   5        8         6
     6     9854     63298            4   7 9   6        7         7
     7      76      5410             3   8 8   7890123456         8
     8                0123           2   9 7   0987654321         9
     9               89  4           1   0 6   1        0         0
    10       123412367   5678        0   1 5   2        9         1
    11       0     45      09        9   234   3        8         2
    12       9        654321         8         4        7         3
    13       8765432107              7         5        6         4
    14               98              65432109876        54321098765

  Image: X = 79, Y = 15, Loops = 4
  END

  ok nws($d->printLoop(2)) eq nws(<<END);
           1         2
       678901234567890123

     3        1111
     4        22 1
     5        22 22
     6        22412
     7        1334
     8          3411
     9         11  1
    10 111111111   1111
    11 1     22      22
    12 1        111111
    13 1111111122
    14         21

  Image: X = 79, Y = 15, Loop = 2
  END

  ok nws($d->printLoop(3)) eq nws(<<END);
       3         4         5
       012345678901234567890123456789

     1 11111111111        11111111111
     2 1         1        1         1
     3 1         1        1         1
     4 1         1        1         1
     5 1         1        1         1
     6 1         1        1         1
     7 1         1222222221         1
     8 1         1222222221         1
     9 1         1        1         1
    10 1         1        1         1
    11 1         1        1         1
    12 1         1        1         1
    13 1         1        1         1
    14 11111111111        11111111111

  Image: X = 79, Y = 15, Loop = 3
  END

  ok nws($d->printLoop(4)) eq nws(<<END);
        3         4
       9012345678901

     0
     1
     2
     3      111
     4      1 1
     5      1 1
     6      1 1
     7      1 1
     8      1 1
     9      1 1
    10      1 1
    11      111
    12
    13
    14

  Image: X = 79, Y = 15, Loop = 4
  END


This is a static method and so should be invoked as:

  Image::Find::Loops::new


=head2 numberOfLoops($)

Number of loops in the image.  The partitions and loops are numbered from 1.

     Parameter  Description
  1  $i         Image

Example:


  is_deeply [$d->count, $d->x, $d->y, $d->numberOfLoops],

  [239,       79,    15,    4];


=head2 loop($$)

Return an array of arrays [x, y] of sequentially touching pixels describing the largest loop in the specified partition where the loops in an image are numbered from 1.

     Parameter   Description
  1  $i          Image
  2  $partition  Partition

Example:


  is_deeply [grep{$_->[2] > 2} @{$d->loop(2)}],

  [[15, 8, 3],

  [15, 7, 3],

  [15, 6, 4],

  [14, 7, 3],

  [16, 7, 4],


=head2 printLoop($$)

Print a loop in the image numbering pixels with the estimated thickness of the loop.

     Parameter   Description
  1  $i          Image
  2  $partition  Partition

Example:


  ok nws($d->printLoop(2)) eq nws(<<END);
           1         2
       678901234567890123

     3        1111
     4        22 1
     5        22 22
     6        22412
     7        1334
     8          3411
     9         11  1
    10 111111111   1111
    11 1     22      22
    12 1        111111
    13 1111111122
    14         21

  Image: X = 79, Y = 15, Loop = 2
  END

  ok nws($d->printLoop(3)) eq nws(<<END);
       3         4         5
       012345678901234567890123456789

     1 11111111111        11111111111
     2 1         1        1         1
     3 1         1        1         1
     4 1         1        1         1
     5 1         1        1         1
     6 1         1        1         1
     7 1         1222222221         1
     8 1         1222222221         1
     9 1         1        1         1
    10 1         1        1         1
    11 1         1        1         1
    12 1         1        1         1
    13 1         1        1         1
    14 11111111111        11111111111

  Image: X = 79, Y = 15, Loop = 3
  END

  ok nws($d->printLoop(4)) eq nws(<<END);
        3         4
       9012345678901

     0
     1
     2
     3      111
     4      1 1
     5      1 1
     6      1 1
     7      1 1
     8      1 1
     9      1 1
    10      1 1
    11      111
    12
    13
    14

  Image: X = 79, Y = 15, Loop = 4
  END


=head2 print($)

Print the loops in an image sequentially numbering adjacent pixels in each loop from 0..9.

     Parameter  Description
  1  $i         Image

Example:


  ok nws($d->print) eq nws(<<END);
       0         1         2         3         4         5         6         7
       0123456789012345678901234567890123456789012345678901234567890123456789012345678
     0
     1      56                       12345678901        23456789012
     2     3478                      8         2        1         3
     3    12  90    1234             7   432   3        0         4
     4    2    1    09 5             6   5 1   4        9         5
     5    10  32    78 67            5   6 0   5        8         6
     6     9854     63298            4   7 9   6        7         7
     7      76      5410             3   8 8   7890123456         8
     8                0123           2   9 7   0987654321         9
     9               89  4           1   0 6   1        0         0
    10       123412367   5678        0   1 5   2        9         1
    11       0     45      09        9   234   3        8         2
    12       9        654321         8         4        7         3
    13       8765432107              7         5        6         4
    14               98              65432109876        54321098765

  Image: X = 79, Y = 15, Loops = 4
  END


=head1 Attributes

Attributes of an image

=head2 bounds :lvalue

The bounds of each partition: [$x1, $y1, $x2, $y2].


=head2 count :lvalue

Number of points in the image.


=head2 image :lvalue

Image data points.


=head2 partitions :lvalue

Number of partitions in the image.


=head2 partitionLoop :lvalue

Loop for each partition.


=head2 x :lvalue

Image dimension in x.


=head2 y :lvalue

Image dimension in y.



=head1 Private Methods

=head2 fillPartition($$)

Remove any interior voids in a partition.

     Parameter   Description
  1  $i          Image
  2  $partition  Partition

=head2 clone($)

Clone an image.

     Parameter  Description
  1  $i         Image

Example:


  is_deeply $d, $d->clone;


=head2 clonePartition($$)

Clone a partition of an image.

     Parameter   Description
  1  $i          Image
  2  $partition  Partition

=head2 partitionImage($$)

Partition the  images into disjoint sets of connected points.

     Parameter  Description
  1  $i         Image
  2  $small     Minimum size of a partition - smaller partitions will be ignored

=head2 mapPartition($$$$)

Locate the pixels in the image that are connected to a pixel with a specified value.

     Parameter  Description
  1  $i         Image
  2  $x         X coordinate of first point in partition
  3  $y         Y coordinate of first point in partition
  4  $small     Delete partitions of fewer pixels

=head2 removeInteriorOfPartition($$)

Remove the interior of a partition to leave the exterior loop.

     Parameter   Description
  1  $I          Image
  2  $partition  Partition

=head2 findLongestLoop($$)

Find the longest loop in a partition.

     Parameter   Description
  1  $I          Image
  2  $partition  Partition

=head2 searchArea($$$$)

Return the pixels to search from around a given pixel.

     Parameter   Description
  1  $i          Image
  2  $partition  Partition
  3  $x          X coordinate of center of search
  4  $y          Y coordinate of center of search.

=head2 widthOfLoop($$)

Find the (estimated) width of the loop at each point.

     Parameter   Description
  1  $I          Image
  2  $partition  Partition


=head1 Index


1 L<bounds|/bounds>

2 L<clone|/clone>

3 L<clonePartition|/clonePartition>

4 L<count|/count>

5 L<fillPartition|/fillPartition>

6 L<findLongestLoop|/findLongestLoop>

7 L<image|/image>

8 L<loop|/loop>

9 L<mapPartition|/mapPartition>

10 L<new|/new>

11 L<numberOfLoops|/numberOfLoops>

12 L<partitionImage|/partitionImage>

13 L<partitionLoop|/partitionLoop>

14 L<partitions|/partitions>

15 L<print|/print>

16 L<printLoop|/printLoop>

17 L<removeInteriorOfPartition|/removeInteriorOfPartition>

18 L<searchArea|/searchArea>

19 L<widthOfLoop|/widthOfLoop>

20 L<x|/x>

21 L<y|/y>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>7;

#         1         2         3         4         5         6         7
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
my $d = new (<<END);                                                            #Tnew

     11                       11111111111        11111111111
    1111                      1         1        1         1
   11  11    1111             1   111   1        1         1              1
   11  11    11 11            1   1 1   1        1         1
   11  11    11 11            1   1 1   1        1         1
    1111     11111            1   1 1   1        1         1
     11      1111             1   1 1   1111111111         1                  1
               1111           1   1 1   1111111111         1            1
              11111           1   1 1   1        1         1
      111111111111111111      1   1 1   1        1         1
      11    1111111111        1   111   1        1         1                1
      1      11111111         1         1        1         1
     11111111111              1         1        1         1
              111             11111111111        11111111111

END

is_deeply [$d->count, $d->x, $d->y, $d->numberOfLoops],                         #Tx #Ty #Tcount #TnumberOfLoops
          [239,       79,    15,    4];                                         #Tx #Ty #Tcount #TnumberOfLoops

is_deeply [grep{$_->[2] > 2} @{$d->loop(2)}],                                   #Tloop
 [[15, 8, 3],                                                                   #Tloop
  [15, 7, 3],                                                                   #Tloop
  [15, 6, 4],                                                                   #Tloop
  [14, 7, 3],                                                                   #Tloop
  [16, 7, 4],                                                                   #Tloop
  [16, 8, 4]];

is_deeply $d, $d->clone;                                                        #Tclone

ok nws($d->print) eq nws(<<END);                                                #Tprint #Tnew
     0         1         2         3         4         5         6         7
     0123456789012345678901234567890123456789012345678901234567890123456789012345678
   0
   1      56                       12345678901        23456789012
   2     3478                      8         2        1         3
   3    12  90    1234             7   432   3        0         4
   4    2    1    09 5             6   5 1   4        9         5
   5    10  32    78 67            5   6 0   5        8         6
   6     9854     63298            4   7 9   6        7         7
   7      76      5410             3   8 8   7890123456         8
   8                0123           2   9 7   0987654321         9
   9               89  4           1   0 6   1        0         0
  10       123412367   5678        0   1 5   2        9         1
  11       0     45      09        9   234   3        8         2
  12       9        654321         8         4        7         3
  13       8765432107              7         5        6         4
  14               98              65432109876        54321098765

Image: X = 79, Y = 15, Loops = 4
END

ok nws($d->printLoop(2)) eq nws(<<END);                                         #TprintLoop #Tnew
         1         2
     678901234567890123

   3        1111
   4        22 1
   5        22 22
   6        22412
   7        1334
   8          3411
   9         11  1
  10 111111111   1111
  11 1     22      22
  12 1        111111
  13 1111111122
  14         21

Image: X = 79, Y = 15, Loop = 2
END

ok nws($d->printLoop(3)) eq nws(<<END);                                         #TprintLoop #Tnew
     3         4         5
     012345678901234567890123456789

   1 11111111111        11111111111
   2 1         1        1         1
   3 1         1        1         1
   4 1         1        1         1
   5 1         1        1         1
   6 1         1        1         1
   7 1         1222222221         1
   8 1         1222222221         1
   9 1         1        1         1
  10 1         1        1         1
  11 1         1        1         1
  12 1         1        1         1
  13 1         1        1         1
  14 11111111111        11111111111

Image: X = 79, Y = 15, Loop = 3
END

ok nws($d->printLoop(4)) eq nws(<<END);                                         #TprintLoop #Tnew
      3         4
     9012345678901

   0
   1
   2
   3      111
   4      1 1
   5      1 1
   6      1 1
   7      1 1
   8      1 1
   9      1 1
  10      1 1
  11      111
  12
  13
  14

Image: X = 79, Y = 15, Loop = 4
END
