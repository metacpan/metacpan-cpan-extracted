#!/usr/bin/perl   
#-------------------------------------------------------------------------------
# Image::Find::Paths - Locate paths in an image.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2018
#-------------------------------------------------------------------------------
package Image::Find::Paths;
our $VERSION = "20180429";
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use utf8;

#1 Attributes                                                                   # Attributes of an image

genLValueScalarMethods(q(count));                                               # Number of points in the image.
genLValueScalarMethods(q(image));                                               # Image data points. 
genLValueScalarMethods(q(partitions));                                          # Number of partitions in the image.
genLValueScalarMethods(q(partitionEnd));                                        # End points for each path.
genLValueScalarMethods(q(partitionStart));                                      # Start points for each path.
genLValueScalarMethods(q(partitionPath));                                       # Path for each partition.
genLValueScalarMethods(q(x));                                                   # Image dimension in x.
genLValueScalarMethods(q(y));                                                   # Image dimension in y.

#1 Methods                                                                      # Locate paths in an image

sub new($)                                                                      #S Find paths in an image represented as a string.   
 {my ($string) = @_;                                                            # String of blanks; non blanks; new lines defining the image 
  my @lines = split /\n/, $string;
  my $count;                                                                    # Number of active pixels  
  my %image;                                                                    # {x}{y} of active pixels
  my $x;                                                                        # Image dimension in x
  for   my $j(0..$#lines)                                                       # Load active pixels 
   {my $line = $lines[$j]; 
    $x = length($line) if !defined($x) or  length($line) > $x;                  # Longest line
    for my $i(0..length($line)-1)                                               # Parse each line  
     {$image{$i}{$j} = 0, $count++ if substr($line, $i, 1) ne q( ); 
     }
   }
   
  my $d = bless{image=>\%image, x=>$x, y=>scalar(@lines), count=>$count,        # Create image of paths
                partitions=>{}, partitionStart=>{}, partitionEnd=>{},
                partitionPath=>{}}; 

  $d->partition;                                                                # Partition the image
  $d->start($_), $d->end($_) for 1..$d->numberOfPaths;                          # Find a start point for each partition 
  $d->shortestPathBetweenEndPoints($_) for 1..$d->numberOfPaths;                # Find the longest path in each partition

  $d                                                                            # Return new image with path details                 
 }
 
sub clone($)                                                                    # Clone an image.
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
 }
 
sub numberOfPaths($)                                                            # Number of paths in the image.
 {my ($i) = @_;                                                                 # Image
  scalar(keys %{$i->partitions})        
 }
 
sub partition($)                                                                #P Partition == set of connected points.
 {my ($i) = @_;                                                                 # Image
  for   my $x(sort{$a<=>$b} keys %{$i->image})                                  # Stabilize partition numbers to make testing possible
   {for my $y(sort{$a<=>$b} keys %{$i->image->{$x}})
     {$i->mapPartition($x, $y) if $i->image->{$x}{$y} == 0;                     # Bucket fill anything that touches this pixels    
     } 
   }
 }

sub mapPartition($$$)                                                           #P Locate the pixels in the image that are connected to a pixel with a specified value 
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
 }

sub traverseToOtherEnd($$$$)                                                    #P Traverse to the other end of a partition.
 {my ($I, $partition, $x, $y) = @_;                                             # Image, partition, start x coordinate, start y coordinate
  my $i = $I->clone;                                                            # Clone the image so that we can remove pixels once they have been processed to spped up the remaining search 
  my @remove = ([$x, $y]);                                                      # Removal sequence 
  my $last;                                                                     # We know that there are two or more pixels in the paritition
  while(@remove)
   {$last = shift @remove;
    my ($x, $y) = @$last;                                                       
    my $P = $i->partitions->{$partition};
    delete $P->{$x}{$y};                                                        # Remove the pixel currently being examined
    push @remove, $i->searchArea($partition, $x, $y);
   } 
  $last                                                                         # Last point is the other end
 }

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
 }

sub end($$)                                                                     #P Find the other end of a path in a partition.
 {my ($i, $partition) = @_;                                                     # Image, partition
  $i->partitionEnd->{$partition} =                                              # Record start point 
    $i->traverseToOtherEnd($partition, @{$i->partitionStart->{$partition}});                              
 }

sub searchArea($$$$)                                                            #P Return the pixels to search from around a given pixel.
 {my ($i, $partition, $x, $y) = @_;                                             # Image, partition, x coordinate of center of search, y coordinate of center of search.
  my @s;                                                                        # Pixels to search from
  my $P = $i->partitions->{$partition};
  my ($𝘅, $𝕩, $𝘆, $𝕪) = ($x+1, $x-1, $y+1, $y-1);
  push @s, [$𝘅, $y] if exists $P->{$𝘅}{$y};
  push @s, [$x, $𝘆] if exists $P->{$x}{$𝘆};
  push @s, [$x, $𝕪] if exists $P->{$x}{$𝕪};
  push @s, [$𝕩, $y] if exists $P->{$𝕩}{$y};
  @s                                                                            # Return all possible pixels
 }  

sub shortestPathBetweenEndPoints($$)                                            #P Find the shortest path between the start and the end points of a partition.
 {my ($I, $partition) = @_;                                                     # Image, partition
  my $i = $I->clone; 
  my ($X, $Y) = @{$i->partitionEnd->{$partition}};                              # The end point for this partition
  my @path = ($i->partitionStart->{$partition});                                # A possible path
  my @shortestPath;                                                             # Shortest path so far
  my @search = [$i->searchArea($partition, @{$path[0]})];                       # Initial search area is the pixels around the start pixel 
  my %visited;                                                                  # Pixels we have already visited along the possible path 
  
  while(@search)                                                                # Find the shortest path amongst all the possible paths
   {@path == @search or confess "Search and path depth mismatch";               # These two arrays must stay in sync because their dimensions reflects the progress along the possible path
    my $search = $search[-1];                                                   # Pixels to search for latest path element  
    if (!@$search)                                                              # Nothing left to search at this level
     {pop @search;                                                              # Remove search level
      my ($x, $y) = @{pop @path};                                               # Pixel to remove from possible path
      delete $visited{$x}{$y};                                                  # Pixel no longer visited on this possible path 
     }
    else   
     {my ($x, $y) = @{pop @$search};                                            # Next pixel to add to path
      next if $visited{$x}{$y};                                                 # Pixel has already been vsisited on this path so skip it   
      if ($x == $X and $y == $Y)
       {@shortestPath = @path if !@shortestPath or @path < @shortestPath;
        my ($x, $y) = @{pop @path};                                             # Pixel to remove from possible path
        pop @search;                                                            # any other adjacent pixels will not produce a shorter path
        delete $visited{$x}{$y};                                                # Pixel no longer visited on this possible path 
       }
      else                                                                      # Extend the search
       {push @path, [$x, $y];                                                   # Extend the path             
        $visited{$x}{$y}++;
        push @search,                                                           # Extend the search area to pixels not already visited on this path
         [grep {my ($x, $y) = @$_; !$visited{$x}{$y}}
            $i->searchArea($partition, $x, $y)] 
       }    
     }    
   }

  push @shortestPath, $i->partitionEnd->{$partition};                           # Add end point.
  $I->partitionPath->{$partition} = [@shortestPath]                             # Return the shortest path  
 }

sub path($$)                                                                    # Path for a specified partition.
 {my ($i, $partition) = @_;                                                     # Image, partition
  $i->partitionPath->{$partition}                                               # Return the shortest path  
 }
 
sub print($)                                                                    # Print the image.
 {my ($i) = @_;                                                                 # Image
  my $X = $i->x; my $Y = $i->y;
  my $s = ' ' x $X;
  my @s = ($s) x $Y;

  my $plot = sub 
   {my ($x, $y, $symbol) = @_;
    substr($s[$y], $x, 1) = $symbol;  
   };

  for my $partition(keys %{$i->partitionPath})                                  # Each path
   {my ($start, @p) = @{$i->partitionPath->{$partition}};                                           # Draw path
    my $end = pop @p;
    $plot->(@$start, q(S));
    $plot->(@$_,     q(+)) for @p;
    $plot->(@$end,   q(E));
   }

  join "\n", @s  
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

Image::Find::Paths - Locate paths in an image.

=head1 Synopsis

=head1 Description

Locate paths in an image.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Attributes

Attributes of an image

=head2 count :lvalue

Number of points in image


=head2 image :lvalue

Image data points


=head2 partitions :lvalue

Number of parts in the image


=head2 partitionEnd :lvalue

End point for a partition


=head2 partitionStart :lvalue

Start point for a partition


=head2 partitionPath :lvalue

Start path for each partition


=head2 x :lvalue

Image dimension in x


=head2 y :lvalue

Image dimension in y


=head1 Methods

Locate paths in an image

=head2 new($)

Find paths in an image represented as a string.

     Parameter  Description                                                 
  1  $string    String of blanks; non blanks; new lines defining the image  

Example:


  my $d = new(<<END);
       11                                                                        1
        11                                                                 1     1
         1111                            111                                     1
            1                              11              1                     1
          111                             111             111                    1
         11  11 1                         1                1                      
        11    111                         1                                      1
        1       1                         1                 1                    1
       1111111111                         1             111111                   1
                111                       1                               1      1
  END
  
  ok $d->x     == 80;
  
  ok $d->y     == 10;
  
  ok nws($d->print) eq nws(<<END);
       E+                                                                        E
        ++                                                                       +
         ++++                            E++                                     +
            +                              +               S                     +
          +++                             ++              E+                     S
         ++  S+                           +
        ++    +++                         +                                      E
        +       +                         +                 S                    +
        +++++++++                         +             E++++                    +
                                          S                                      S
  END
  
  ok $d->numberOfPaths == 6;
  
  is_deeply $d->path(5), [[79, 4], [79, 3], [79, 2], [79, 1], [79, 0]];
  

This is a static method and so should be invoked as:

  Image::Find::Paths::new


=head2 clone($)

Clone an image.

     Parameter  Description  
  1  $i         Image        

Example:


  is_deeply $d, $d->clone;
  

=head2 numberOfPaths($)

Number of paths in the image.

     Parameter  Description  
  1  $i         Image        

Example:


  ok $d->numberOfPaths == 6;
  

=head2 path($$)

Path for a specified partition.

     Parameter   Description  
  1  $i          Image        
  2  $partition  Partition    

Example:


  is_deeply $d->path(5), [[79, 4], [79, 3], [79, 2], [79, 1], [79, 0]];
  

=head2 print($)

Print the image.

     Parameter  Description  
  1  $i         Image        

Example:


  ok nws($d->print) eq nws(<<END);
       E+                                                                        E
        ++                                                                       +
         ++++                            E++                                     +
            +                              +               S                     +
          +++                             ++              E+                     S
         ++  S+                           +
        ++    +++                         +                                      E
        +       +                         +                 S                    +
        +++++++++                         +             E++++                    +
                                          S                                      S
  END
  


=head1 Private Methods

=head2 partition($)

Partition == set of connected points.

     Parameter  Description  
  1  $i         Image        

=head2 mapPartition($$$)

Locate the pixels in the image that are connected to a pixel with a specified value

     Parameter  Description                               
  1  $i         Image                                     
  2  $x         X coordinate of first point in partition  
  3  $y         Y coordinate of first point in partition  

=head2 traverseToOtherEnd($$$$)

Traverse to the other end of a partition.

     Parameter   Description         
  1  $I          Image               
  2  $partition  Partition           
  3  $x          Start x coordinate  
  4  $y          Start y coordinate  

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

=head2 searchArea($$$$)

Return the pixels to search from around a given pixel.

     Parameter   Description                        
  1  $i          Image                              
  2  $partition  Partition                          
  3  $x          X coordinate of center of search   
  4  $y          Y coordinate of center of search.  

=head2 shortestPathBetweenEndPoints($$)

Find the shortest path between the start and the end points of a partition.

     Parameter   Description  
  1  $I          Image        
  2  $partition  Partition    


=head1 Index


1 L<clone|/clone>

2 L<count|/count>

3 L<end|/end>

4 L<image|/image>

5 L<mapPartition|/mapPartition>

6 L<new|/new>

7 L<numberOfPaths|/numberOfPaths>

8 L<partition|/partition>

9 L<partitionEnd|/partitionEnd>

10 L<partitionPath|/partitionPath>

11 L<partitions|/partitions>

12 L<partitionStart|/partitionStart>

13 L<path|/path>

14 L<print|/print>

15 L<searchArea|/searchArea>

16 L<shortestPathBetweenEndPoints|/shortestPathBetweenEndPoints>

17 L<start|/start>

18 L<traverseToOtherEnd|/traverseToOtherEnd>

19 L<x|/x>

20 L<y|/y>

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
my $d = new(<<END);                                                             #Tnew
     11                                                                        1
      11                                                                 1     1
       1111                            111                                     1
          1                              11              1                     1
        111                             111             111                    1
       11  11 1                         1                1                      
      11    111                         1                                      1
      1       1                         1                 1                    1
     1111111111                         1             111111                   1
              111                       1                               1      1
END

ok $d->count == 73;                                                             #Tcount
ok $d->x     == 80;                                                             #Tx #Tnew
ok $d->y     == 10;                                                             #Ty #Tnew
is_deeply $d, $d->clone;                                                        #Tclone 

ok nws($d->print) eq nws(<<END);                                                #Tprint #Tnew
     E+                                                                        E
      ++                                                                       +
       ++++                            E++                                     +
          +                              +               S                     +
        +++                             ++              E+                     S
       ++  S+                           +
      ++    +++                         +                                      E
      +       +                         +                 S                    +
      +++++++++                         +             E++++                    +
                                        S                                      S
END

ok $d->numberOfPaths == 6;                                                      #TnumberOfPaths #Tnew
is_deeply $d->path(5), [[79, 4], [79, 3], [79, 2], [79, 1], [79, 0]];           #Tpath          #Tnew
