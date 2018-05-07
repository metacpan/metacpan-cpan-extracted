#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Image::Find::Paths - Find paths in an image.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
package Image::Find::Paths;
our $VERSION = "20180505";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
#use Time::HiRes qw(time);
use utf8;

#my %exec; sub e($) {$exec{$_[0]}++}

#1 Methods                                                                      # Find paths in an image

sub new($)                                                                      #S Find paths in an image represented as a string.
 {my ($string) = @_;                                                            # String of blanks; non blanks; new lines defining the image
  my @lines = split /\n/, $string;
  my $count;                                                                    # Number of active pixels
  my %image;                                                                    # {x}{y} of active pixels
  my $x;                                                                        # Image dimension in x
  for   my $j(0..$#lines)                                                       # Load active pixels
   {my $line = $lines[$j];
    $x = length($line) if !defined($x) or length($line) > $x;                   # Longest line
    for my $i(0..length($line)-1)                                               # Parse each line
     {$image{$i}{$j} = 0, $count++ if substr($line, $i, 1) ne q( );
     }
   }

  my $d = bless{image=>\%image, x=>$x, y=>scalar(@lines), count=>$count,        # Create image of paths
                partitions=>{}, partitionStart=>{}, partitionEnd=>{},
                partitionPath=>{}};

  $d->partition;                                                                # Partition the image
  $d->start($_), $d->end($_)               for 1..$d->numberOfPaths;            # Find a start point for each partition
  my $h = $d->height;                                                           # Clone and add height
  $d->shortestPathBetweenEndPoints($h, $_) for 1..$d->numberOfPaths;            # Find the longest path in each partition
  $d->widthOfPaths;
  $d                                                                            # Return new image with path details
 } # new

sub clone($)                                                                    #P Clone an image.
 {my ($i) = @_;                                                                 # Image
  my %partitions;                                                               # Clone partitions
  for     my $p(keys %{$i->partitions})
   {for   my $x(keys %{$i->partitions->{$p}})
     {for my $y(keys %{$i->partitions->{$p}{$x}})
       {$partitions{$p}{$x}{$y} = $i->partitions->{$p}{$x}{$y};
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

sub countPixels($)                                                              #P Count the pixels in an image.
 {my ($i) = @_;                                                                 # Image

  my $count;
  for     my $p(keys %{$i->partitions})
   {for   my $x(keys %{$i->partitions->{$p}})
     {for my $y(keys %{$i->partitions->{$p}{$x}})
       {++$count
       }
     }
   }

  $count
 } # countPixels

sub height($)                                                                   #P Clone an image adding height to each pixel.
 {my ($i) = @_;                                                                 # Image

  my %contours;                                                                 # Clone partitions
  my $pixels = 0;
  for     my $p(keys %{$i->partitions})                                         # Base
   {for   my $x(keys %{$i->partitions->{$p}})
     {for my $y(keys %{$i->partitions->{$p}{$x}})
       {$contours{$p}{1}{$x}{$y} = 1;
        $pixels++;
       }
     }
   }

  for         my $p(keys %contours)                                             # Contours
   {for     my $h(1..$pixels)
     {my $count;
      for   my $x(keys %{$contours{$p}{$h}})
       {for my $y(keys %{$contours{$p}{$h}{$x}})
         {my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);
          if (exists $contours{$p}{$h  }{$x}{$𝕪} and
              exists $contours{$p}{$h  }{$x}{$𝘆} and
              exists $contours{$p}{$h  }{$𝘅}{$y} and
              exists $contours{$p}{$h  }{$𝘅}{$𝘆} and
              exists $contours{$p}{$h  }{$𝘅}{$𝕪} and
              exists $contours{$p}{$h  }{$𝕩}{$y} and
              exists $contours{$p}{$h  }{$𝕩}{$𝘆} and
              exists $contours{$p}{$h  }{$𝕩}{$𝕪})
           {         $contours{$p}{$h+1}{$x}{$y}++;
            ++$count;
           }
         }
       }
      last unless defined $count;
     }
   }

  my %partitions;                                                               # Project contours to obtain height partition
  for       my $p(keys %  contours)
   {for     my $h(sort{$a<=>$b}keys %{$contours{$p}})
     {for   my $x(keys %{$contours{$p}{$h}})
       {for my $y(keys %{$contours{$p}{$h}{$x}})
         {$partitions{$p}{$x}{$y} = $h;
         }
       }
     }
   }

  bless {%$i, partitions=>\%partitions};                                        # Cloned image
 } # height

sub numberOfPaths($)                                                            # Number of paths in the image.
 {my ($i) = @_;                                                                 # Image
  scalar(keys %{$i->partitions})
 } # numberOfPaths

sub partition($)                                                                #P Partition the  images into disjoint sets of connected points.
 {my ($i) = @_;                                                                 # Image
  for   my $x(sort{$a<=>$b} keys %{$i->image})                                  # Stabilize partition numbers to make testing possible
   {for my $y(sort{$a<=>$b} keys %{$i->image->{$x}})
     {$i->mapPartition($x, $y) if $i->image->{$x}{$y} == 0;                     # Bucket fill anything that touches this pixels
     }
   }
 } # partition

sub mapPartition($$$)                                                           #P Locate the pixels in the image that are connected to a pixel with a specified value.
 {my ($i, $x, $y) = @_;                                                         # Image, x coordinate of first point in partition, y coordinate of first point in partition
  my $p = $i->image->{$x}{$y} = $i->numberOfPaths+1;                            # Next partition
  $i->partitions->{$p}{$x}{$y}++;                                               # Add first pixel to this partition
  my $pixelsInPartition = 0;

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
         }
       }
     }
    last unless $changed;                                                       # No more pixels in parition to consider
   }

  if ($pixelsInPartition <= 1)                                                  # Remove partitions of just one pixel
   {for   my $x(keys %{$i->image})
     {for my $y(keys %{$i->image->{$x}})
       {delete $i->image->{$x}{$y} if            $i->image->{$x}{$y} == $p;
        delete $i->image->{$x}     unless keys %{$i->image->{$x}};              # Remove containing hash if now empty
       }
     }
    delete $i->partitions->{$p}
   }
 } # mapPartition

sub start($$)                                                                   #P Find the starting point for a path in a partition.
 {my ($i, $partition) = @_;                                                     # Image, partition
  my $remove;                                                                   # Removal sequence

  for   my $x((sort{$a<=>$b} keys %{$i->partitions->{$partition}    })[0])      # Find the first point in a partition
   {for my $y((sort{$a<=>$b} keys %{$i->partitions->{$partition}{$x}})[0])
     {$remove = [$x, $y];
     }
   }

  $i->partitionStart->{$partition} =                                            # Record start point
    $i->traverseToOtherEnd($partition, @$remove);
 } # start

sub end($$)                                                                     #P Find the other end of a path in a partition.
 {my ($i, $partition) = @_;                                                     # Image, partition
  $i->partitionEnd->{$partition} =                                              # Record start point
    $i->traverseToOtherEnd($partition, @{$i->partitionStart->{$partition}});
 } # end

sub traverseToOtherEnd($$$$)                                                    #P Traverse to the other end of a partition.
 {my ($I, $partition, $X, $Y) = @_;                                             # Image, partition, start x coordinate, start y coordinate
  my $i = $I->clonePartition($partition);                                       # Clone the specified partition so that we can remove pixels once they have been processed to spped up the remaining search
  my @remove = ([$X, $Y]);                                                      # Removal sequence
  my %remove = ($X=>{$Y=>1});                                                   # Removal sequence deduplication
  my $last;                                                                     # We know that there are two or more pixels in the paritition
  while(@remove)
   {$last = shift @remove;
    my ($x, $y) = @$last;
    delete $i->partitions->{$partition}{$x}{$y};
    $remove{$x}{$y}++;
    my @r = $i->searchArea($partition, $x, $y);
    my @s = grep {my ($x, $y) = @$_; !$remove{$x}{$y}} @r;
    for(@r)
     {my ($x, $y) = @$_; $remove{$x}{$y}++;
     }
    push @remove, @s;
    $i->searchArea($partition, $x, $y);
   }
  $last                                                                         # Last point is the other end
 } # traverseToOtherEnd

sub searchArea($$$$)                                                            #P Return the pixels to search from around a given pixel.
 {my ($i, $partition, $x, $y) = @_;                                             # Image, partition, x coordinate of center of search, y coordinate of center of search.
  my @s;                                                                        # Pixels to search from
  my $P = $i->partitions->{$partition};
  my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);
  push @s, [$𝘅, $y] if exists $P->{$𝘅} and exists $P->{$𝘅}{$y};
  push @s, [$x, $𝘆] if exists $P->{$x} and exists $P->{$x}{$𝘆};
  push @s, [$x, $𝕪] if exists $P->{$x} and exists $P->{$x}{$𝕪};
  push @s, [$𝕩, $y] if exists $P->{$𝕩} and exists $P->{$𝕩}{$y};
  @s                                                                            # Return all possible pixels
 } # searchArea

sub checkAtLevelOne($$$)                                                        #P Confirm that the specified pixel is at level one.
 {my ($i, $partition, $pixel) = @_;                                             # Image, partition, pixel
  my ($x, $y) = @$pixel;
  my $h = $i->partitions->{$partition}{$x}{$y};
  defined($h) or confess "No pixel in partition=$partition at x=$x, y=$y";
  $h == 1 or confess "Pixel in partition=$partition at x=$x, y=$y is $h not one";
 } # checkAtLevelOne

sub searchAreaHighest($$$$$$)                                                   #P Return the highest pixels to search from around a given pixel.
 {my ($i, $partition, $seen, $depth, $x, $y) = @_;                              # Image, partition, pixels already visited, depth of search, x coordinate of center of search, y coordinate of center of search.
  my @s;                                                                        # Pixels to search from
  my $P = $i->partitions->{$partition};
  my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);
  push @s, [$𝘅, $y, $P->{$𝘅}{$y}] if exists $P->{$𝘅} and exists $P->{$𝘅}{$y} and !$seen->{$𝘅}{$y} || $seen->{$𝘅}{$y} > $depth;
  push @s, [$x, $𝘆, $P->{$x}{$𝘆}] if exists $P->{$x} and exists $P->{$x}{$𝘆} and !$seen->{$x}{$𝘆} || $seen->{$x}{$𝘆} > $depth;
  push @s, [$x, $𝕪, $P->{$x}{$𝕪}] if exists $P->{$x} and exists $P->{$x}{$𝕪} and !$seen->{$x}{$𝕪} || $seen->{$x}{$𝕪} > $depth;
  push @s, [$𝕩, $y, $P->{$𝕩}{$y}] if exists $P->{$𝕩} and exists $P->{$𝕩}{$y} and !$seen->{$𝕩}{$y} || $seen->{$𝕩}{$y} > $depth;
  return @s unless @s > 1;                                                      # Nothing further to search or just  one pixel - which is then the higest pixel returned
  my @S = sort {$$b[2] <=> $$a[2]} @s;                                          # Highest pixels first
  my $h = $S[0][2];                                                             # Highest height
  grep {$$_[2] == $h} @S                                                        # Remove lower pixels
 } # searchAreaHighest

sub shortestPathBetweenEndPoints($$$)                                           #P Find the shortest path between the start and the end points of a partition.
 {my ($I, $i, $partition) = @_;                                                 # Image, image height clone, partition

  $i->checkAtLevelOne($partition, $i->partitionStart->{$partition});            # The end points should be at level one because that is the boundary
  $i->checkAtLevelOne($partition, $i->partitionEnd  ->{$partition});

  my ($X, $Y) = @{$i->partitionEnd->{$partition}};                              # The end point for this partition
  my @path = ($i->partitionStart->{$partition});                                # A possible path
  my @shortestPath;                                                             # Shortest path so far
  my @search = [$i->searchArea($partition, @{$path[0]})];                       # Initial search area is the pixels around the start pixel
  my %seen;                                                                     # Pixels we have already visited along the possible path

  while(@search)                                                                # Find the shortest path amongst all the possible paths
   {@path == @search or confess "Search and path depth mismatch";               # These two arrays must stay in sync because their dimensions reflects the progress along the possible path
    my $search = $search[-1];                                                   # Pixels to search for latest path element
    if (!@$search)                                                              # Nothing left to search at this level
     {pop @search;                                                              # Remove search level
      pop @path;                                                                # Pixel to remove from possible path
     }
    else
     {my ($x, $y) = @{pop @$search};                                            # Next pixel to add to path
      if ($x == $X and $y == $Y)
       {@shortestPath = @path if !@shortestPath or @path < @shortestPath;
        pop @search;                                                            # Remove search level
        pop @path;                                                              # Pixel to remove from possible path
       }
      else                                                                      # Extend the search
       {push @path, [$x, $y];                                                   # Extend the path
        my $P = scalar(@path);                                                  # Current path length
 #      e(q(shortestPath));
        my @r = $i->searchAreaHighest($partition, \%seen, $P, $x, $y);
        for(@r)                                                                 # Update visitation status
         {my ($x, $y) = @$_;
         $seen{$x}{$y} = $P if !exists $seen{$x}{$y} or $seen{$x}{$y} > $P;
 #       e(q(shortestPath - loop));
         }
        push @search, [@r];
       }

      if (1)                                                                    # Set minimum path for surrounding pixels
       {my $P = scalar(@path) + 1; my $Q = $P + 1;
        my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);

        $seen{$x}{$𝘆} = $P if !exists $seen{$x}{$𝘆} or $seen{$x}{$𝘆} > $P;
        $seen{$x}{$𝕪} = $P if !exists $seen{$x}{$𝕪} or $seen{$x}{$𝕪} > $P;
        $seen{$𝘅}{$y} = $P if !exists $seen{$𝘅}{$y} or $seen{$𝘅}{$y} > $P;
        $seen{$𝕩}{$y} = $P if !exists $seen{$𝕩}{$y} or $seen{$𝕩}{$y} > $P;
       }
     }
   }

  push @shortestPath, $i->partitionEnd->{$partition};                           # Add end point.
  $I->partitions = $i->partitions;                                              # Save the partition with height information added
  $I->partitionPath->{$partition} = [@shortestPath]                             # Return the shortest path
 } # shortestPathBetweenEndPoints

sub widthOfPath($$)                                                             #P Find the (estimated) width of the path at each point.
 {my ($I, $partition) = @_;                                                     # Image, partition
  my $i = $I->clonePartition($partition);                                       # Clone the specified partition so that we can remove pixels once they have been processed to spped up the remaining search
  my $path = $i->partitionPath->{$partition};                                   # Path in image
  my $maxSteps = @$path;
  for my $step(keys @$path)
   {my ($x, $y) = @{$$path[$step]};

    my $explore = sub                                                           #P Explore away from a point checking that we are still in the partition associated with the path
     {my ($dx, $dy) = @_;                                                       # x direction, y direction
      for my $step(1..$maxSteps)                                                # Maximum possible width
       {return $step-1 unless $i->partitions->{$partition}                      # Keep stepping whilst still in partition
         {$x+$step*$dx}
         {$y+$step*$dy};
       }
      $maxSteps                                                                 # We never left the partition
     };

    push @{$I->partitionPath->{$partition}[$step]}, 1 + min                     # Explore in opposite directions along 4 lines and take the minimum as the width
     ($explore->(1,  0) + $explore->(-1,  0),
      $explore->(1,  1) + $explore->(-1, -1),
      $explore->(0,  1) + $explore->( 0, -1),
      $explore->(1, -1) + $explore->(-1, +1));
   }
 } # widthOfPath

sub widthOfPaths($)                                                             #P Find the (estimated) width of each path at each point.
 {my ($i) = @_;                                                                 # Image
  $i->widthOfPath($_) for 1..$i->numberOfPaths;                                 # Add path width estimate at each point
 } # widthOfPaths

sub path($$)                                                                    # Returns an array of arrays [x, y, t] where x, y are the coordinates of each point sequentially along the specified path and t is the estimated thickness of the path at that point. Paths are numbered from 1 to L<numberOfPaths|/numberOfPaths>.
 {my ($i, $partition) = @_;                                                     # Image, partition
  $i->partitionPath->{$partition}                                               # Return the shortest path
 } # path

sub printHeader($)                                                              #P Print a header for the image so we can locate pixels by their coordinates.
 {my ($i) = @_;                                                                 # Image
  my $X = $i->x; my $Y = $i->y;
  my $indent = length($Y);
  my $space  = q( ) x $indent;
  my $N = 1 + int($X/10);
  my $s = join '',
          map{substr($_, -1) ? q( ) : $_ > 9 ? substr($_, -2, 1) : 0} 0..$X;
  my $t = substr(("0123456789"x(1 + int($X/10))), 0, $X);

  my $f = "Image: X = $X, Y = $Y, Paths = ".$i->numberOfPaths;                  # Footer layout

 ("$space $s\n$space $t\n", "%".$indent."d %s", $f)                             # Header, line format, footer
 } # printHeader

sub print($)                                                                    # Print the image: use B<S>, B<E> to show the start and end of each path, otherwise use the estimated thickness of the path at each point to mark the track of each path within each connected partition of the image.
 {my ($i) = @_;                                                                 # Image
  my $X = $i->x; my $Y = $i->y;
  my $s = ' ' x $X;
  my @s = ($s) x $Y;

  my $plot = sub                                                                # Plot a pixel
   {my ($x, $y, $symbol) = @_;
    substr($s[$y], $x, 1) = $symbol;
   };

  my ($header, $line, $footer) = $i->printHeader;

  for my $partition(keys %{$i->partitionPath})                                  # Each path
   {my ($start, @p) = @{$i->partitionPath->{$partition}};                       # Draw path
    my @start = @$start;   pop @start;
    my @end   = @{pop @p}; pop @end;

    $plot->(@start, q(S));
    for(@p)
     {my ($x, $y, $h) = @$_;
      $plot->($x, $y, $h % 10);
     }
    $plot->(@end,   q(E));
   }
  join "\n", $header, (map{sprintf($line, $_, $s[$_])} keys @s), $footer
 } # print

#1 Attributes                                                                   # Attributes of an image

genLValueScalarMethods(q(count));                                               # Number of points in the image.
genLValueScalarMethods(q(image));                                               # Image data points.
genLValueScalarMethods(q(partitions));                                          # Number of partitions in the image.
genLValueScalarMethods(q(partitionEnd));                                        # End points for each path.
genLValueScalarMethods(q(partitionStart));                                      # Start points for each path.
genLValueScalarMethods(q(partitionPath));                                       # Path for each partition.
genLValueScalarMethods(q(x));                                                   # Image dimension in x.
genLValueScalarMethods(q(y));                                                   # Image dimension in y.

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

Image::Find::Paths - Find paths in an image.

=head1 Synopsis

Use L<new|/new> to create and analyze a new image, then L<print|/print> to
visualize the paths detected, or L<path|/path> to get the coordinates of points
along each path in sequential order with an estimate of the thickness of the
path at each point.

=head1 Description

Find paths in an image.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Methods

Find paths in an image

=head2 new($)

Find paths in an image represented as a string.

     Parameter  Description                                                 
  1  $string    String of blanks; non blanks; new lines defining the image  

Example:


  my $d = new(<<END);
       11                                                                      111
        11                                                                 1   111
         1111                            111                                   111
            1                           111111             1                   111
          111                            1111             111                  111
         11  1111111                      1                1
        11    11111                       1                                      1
        1      111                        1                 1                    1
       1111111111                         1             111111                   1
                111                       1                               1      1
  END
  
  is_deeply [$d->count, $d->x, $d->y, $d->numberOfPaths], [96, 80, 10, 6];
  
  ok nws($d->print) eq nws(<<END);
     0         1         2         3         4         5         6         7         8
     01234567890123456789012345678901234567890123456789012345678901234567890123456789
  
   0      E1                                                                      E
   1       11                                                                     23
   2        1111                                                                   3
   3           1                             322E             S                    3
   4         111                             2               E1                    2S
   5        11     221S                      1
   6       11     23                         1                                      E
   7       1      3                          1                 S                    1
   8       11111112                          1             E1111                    1
   9                                         S                                      S
  
  Image: X = 80, Y = 10, Paths = 6
  END
  
  is_deeply $d->path(5),
  
  [[79,4, 1], [78,4, 2], [78,3, 3], [78,2, 3], [78,1, 3], [77,1, 2], [77,0, 1]];
  

This is a static method and so should be invoked as:

  Image::Find::Paths::new


=head2 numberOfPaths($)

Number of paths in the image.

     Parameter  Description  
  1  $i         Image        

Example:


  is_deeply [$d->count, $d->x, $d->y, $d->numberOfPaths], [96, 80, 10, 6];
  

=head2 path($$)

Returns an array of arrays [x, y, t] where x, y are the coordinates of each point sequentially along the specified path and t is the estimated thickness of the path at that point. Paths are numbered from 1 to L<numberOfPaths|/numberOfPaths>.

     Parameter   Description  
  1  $i          Image        
  2  $partition  Partition    

Example:


  is_deeply $d->path(5),
  
  [[79,4, 1], [78,4, 2], [78,3, 3], [78,2, 3], [78,1, 3], [77,1, 2], [77,0, 1]];
  

=head2 print($)

Print the image: use B<S>, B<E> to show the start and end of each path, otherwise use the estimated thickness of the path at each point to mark the track of each path within each connected partition of the image.

     Parameter  Description  
  1  $i         Image        

Example:


  ok nws($d->print) eq nws(<<END);
     0         1         2         3         4         5         6         7         8
     01234567890123456789012345678901234567890123456789012345678901234567890123456789
  
   0      E1                                                                      E
   1       11                                                                     23
   2        1111                                                                   3
   3           1                             322E             S                    3
   4         111                             2               E1                    2S
   5        11     221S                      1
   6       11     23                         1                                      E
   7       1      3                          1                 S                    1
   8       11111112                          1             E1111                    1
   9                                         S                                      S
  
  Image: X = 80, Y = 10, Paths = 6
  END
  

=head1 Attributes

Attributes of an image

=head2 count :lvalue

Number of points in the image.


=head2 image :lvalue

Image data points.


=head2 partitions :lvalue

Number of partitions in the image.


=head2 partitionEnd :lvalue

End points for each path.


=head2 partitionStart :lvalue

Start points for each path.


=head2 partitionPath :lvalue

Path for each partition.


=head2 x :lvalue

Image dimension in x.


=head2 y :lvalue

Image dimension in y.



=head1 Private Methods

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

=head2 countPixels($)

Count the pixels in an image.

     Parameter  Description  
  1  $i         Image        

=head2 height($)

Clone an image adding height to each pixel.

     Parameter  Description  
  1  $i         Image        

=head2 partition($)

Partition the  images into disjoint sets of connected points.

     Parameter  Description  
  1  $i         Image        

=head2 mapPartition($$$)

Locate the pixels in the image that are connected to a pixel with a specified value.

     Parameter  Description                               
  1  $i         Image                                     
  2  $x         X coordinate of first point in partition  
  3  $y         Y coordinate of first point in partition  

=head2 start($$)

Find the starting point for a path in a partition.

     Parameter   Description  
  1  $i          Image        
  2  $partition  Partition    

=head2 end($$)

Find the other end of a path in a partition.

     Parameter   Description  
  1  $i          Image        
  2  $partition  Partition    

=head2 traverseToOtherEnd($$$$)

Traverse to the other end of a partition.

     Parameter   Description         
  1  $I          Image               
  2  $partition  Partition           
  3  $X          Start x coordinate  
  4  $Y          Start y coordinate  

=head2 searchArea($$$$)

Return the pixels to search from around a given pixel.

     Parameter   Description                        
  1  $i          Image                              
  2  $partition  Partition                          
  3  $x          X coordinate of center of search   
  4  $y          Y coordinate of center of search.  

=head2 checkAtLevelOne($$$)

Confirm that the specified pixel is at level one.

     Parameter   Description  
  1  $i          Image        
  2  $partition  Partition    
  3  $pixel      Pixel        

=head2 searchAreaHighest($$$$$$)

Return the highest pixels to search from around a given pixel.

     Parameter   Description                        
  1  $i          Image                              
  2  $partition  Partition                          
  3  $seen       Pixels already visited             
  4  $depth      Depth of search                    
  5  $x          X coordinate of center of search   
  6  $y          Y coordinate of center of search.  

=head2 shortestPathBetweenEndPoints($$$)

Find the shortest path between the start and the end points of a partition.

     Parameter   Description         
  1  $I          Image               
  2  $i          Image height clone  
  3  $partition  Partition           

=head2 widthOfPath($$)

Find the (estimated) width of the path at each point.

     Parameter   Description  
  1  $I          Image        
  2  $partition  Partition    

=head2 widthOfPaths($)

Find the (estimated) width of each path at each point.

     Parameter  Description  
  1  $i         Image        

=head2 printHeader($)

Print a header for the image so we can locate pixels by their coordinates.

     Parameter  Description  
  1  $i         Image        


=head1 Index


1 L<checkAtLevelOne|/checkAtLevelOne>

2 L<clone|/clone>

3 L<clonePartition|/clonePartition>

4 L<count|/count>

5 L<countPixels|/countPixels>

6 L<end|/end>

7 L<height|/height>

8 L<image|/image>

9 L<mapPartition|/mapPartition>

10 L<new|/new>

11 L<numberOfPaths|/numberOfPaths>

12 L<partition|/partition>

13 L<partitionEnd|/partitionEnd>

14 L<partitionPath|/partitionPath>

15 L<partitions|/partitions>

16 L<partitionStart|/partitionStart>

17 L<path|/path>

18 L<print|/print>

19 L<printHeader|/printHeader>

20 L<searchArea|/searchArea>

21 L<searchAreaHighest|/searchAreaHighest>

22 L<shortestPathBetweenEndPoints|/shortestPathBetweenEndPoints>

23 L<start|/start>

24 L<traverseToOtherEnd|/traverseToOtherEnd>

25 L<widthOfPath|/widthOfPath>

26 L<widthOfPaths|/widthOfPaths>

27 L<x|/x>

28 L<y|/y>

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
use Test::More tests=>9;

if (1)
 {my $d = new(<<END);

111
 111

END

  is_deeply [$d->count, $d->x, $d->y, $d->numberOfPaths], [6, 4, 3, 1];
  ok nws($d->print) eq nws(<<END);
  0
  0123
0
1 E1
2  21S
Image: X = 4, Y = 3, Paths = 1
END
 }
#         1         2         3         4         5         6         7
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
if (1)
 {my $d = new(<<END);                                                           #Tnew
     11                                                                      111
      11                                                                 1   111
       1111                            111                                   111
          1                           111111             1                   111
        111                            1111             111                  111
       11  1111111                      1                1
      11    11111                       1                                      1
      1      111                        1                 1                    1
     1111111111                         1             111111                   1
              111                       1                               1      1
END

  is_deeply [$d->count, $d->x, $d->y, $d->numberOfPaths], [96, 80, 10, 6];      #Tcount #Tx #Ty #TnumberOfPaths #Tnew
  is_deeply $d, $d->clone;                                                      #Tclone

  ok nws($d->print) eq nws(<<END);                                              #Tprint #Tnew
   0         1         2         3         4         5         6         7         8
   01234567890123456789012345678901234567890123456789012345678901234567890123456789

 0      E1                                                                      E
 1       11                                                                     23
 2        1111                                                                   3
 3           1                             322E             S                    3
 4         111                             2               E1                    2S
 5        11     221S                      1
 6       11     23                         1                                      E
 7       1      3                          1                 S                    1
 8       11111112                          1             E1111                    1
 9                                         S                                      S

Image: X = 80, Y = 10, Paths = 6
END

  is_deeply $d->path(5),                                                        #Tpath #Tnew
 [[79,4, 1], [78,4, 2], [78,3, 3], [78,2, 3], [78,1, 3], [77,1, 2], [77,0, 1]]; #Tpath #Tnew
 }

sub scale($$;$)                                                                 # Scalability
 {my ($M, $N, $print) = @_;                                                     # x dimension, y dimension, print results
  my $l = q( ).(q(1)x$N).q( );
  my $d = new join "\n", q( ), ($l)x$M, q( );

  is_deeply [$d->count, $d->x, $d->y, $d->numberOfPaths], [$M*$N, $N+2, $M+2, 1];

  ok nws($d->print) eq nws($print) if $print;
 }
if (1)
 {#my $s = time;
  scale(16, 32, <<END);
   0         1         2         3
   0123456789012345678901234567890123
 0
 1  E
 2  23
 3   45
 4    67
 5     89
 6      01
 7       23
 8        45
 9         566666666666666665
10                          43
11                           21
12                            09
13                             87
14                              65
15                               43
16                                2S
17

Image: X = 34, Y = 18, Paths = 1
END
#  say STDERR "Time:", time-$s;
 }

if (1)
 {#my $s = time;
  scale(16, 256);
  #say STDERR "Time:", time-$s;
 }

#say STDERR "EEEE", dump(\%exec);
