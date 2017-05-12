package Graph::Clique;

use 5.008;
use strict;
use warnings;
use re 'eval';

use base qw(Exporter);

our @EXPORT = qw(getcliques);

our @EXPORT_OK = qw(_internalfunctions);

our %EXPORT_TAGS = (all  => \@EXPORT,
                    test => \@EXPORT_OK,
                   );

our $VERSION = '0.02';

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Graph::Clique - Return all k-cliques in a graph

=head1 SYNOPSIS

  use Graph::Clique;
  
  #Edges in the form of LoL (numerical values required)
  my @edges = (
      [1,2], [1,3], [1,4], [1,5],
      [2,3], [2,4],
      [3,4],
      [5,6], [5,7], [5,9],
      [6,9],
      [7,8],
      [8,9],
  );

  my  $k = shift || 3;

  my @cliques = getcliques($k,\@edges);

 print join("\n", @cliques), "\n"; 

 #Output:
 #1 2 3
 #1 2 4
 #1 3 4
 #2 3 4
 #5 6 9
  

=head1 DESCRIPTION

This module extends Greg Bacon's implementation on clique reduction with regular expression.
Originally can be found at: L<http://home.hiwaay.net/~gbacon/perl/clique.html>

The function take clique size (k) and vertices (list of lists) and return all the vertices
that form the clique. 

K-clique problem is known to be NP-complete, so it is advisable to limit the number
of edges according to your predefined threshold, rather than exhaustively searching them.

=head1 ACKNOWLEDGEMENT

Greg Bacon who started all this, Mike Rosulek
and Roy Johnson for his advice on ways to return all k-cliques.
Finally all guys in Perlmonks.org, and  beginners.perl who has helped
me in many ways.


=head1 SEE ALSO

L<Graph>

=head1 AUTHOR

Edward Wijaya, <ewijaya@singnet.com.sg>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Edward Wijaya

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

# Preloaded methods go here.
sub getcliques {

     my ($k,$edges) = @_;
     my @cliques = ();
     my @vertices = ();
     
      @vertices = edges2vertices(@{$edges});

     my   $string = (join ',' => @vertices) .  ';'
                . (join ',' => map "$_->[0]-$_->[1]", @{$edges});

     my  $regex = '^ .*\b '
               . join(' , .*\b ' => ('(\d+)') x $k)
               . '\b .* ;'
               . "\n";

    for (my $i = 1; $i < $k; $i++) {
            for (my $j = $i+1; $j <= $k; $j++) {
                $regex .= '(?= .* \b ' . "\\$i-\\$j" . ' \b)' . "\n";
            }
        }

     # Backtrack to regain all the identified k-cliques (Credit Mike Mikero)
     $regex .= '(?{ push (@cliques, join(" ", map $$_, 1..$k) ) })(?!)';
     $string =~ /$regex/x; 
     
     return sort @cliques;
}

#----Subroutines -------------------
sub edges2vertices {
  my @edges = @_;
  my %hTemp;
  my @vertices;
  
 my  @aTemp = map{@{$_}} @edges;
      @hTemp{@aTemp}  = ();
  @vertices = sort keys %hTemp;   
  return @vertices;  
}

sub edges2vertices_slow {
  #AoA to uniq array;

  my @edges = @_;
  my @vertices;
  my @uniqv; 
  
   for my $i ( 0 .. $#edges ) {
               for my $j ( 0 .. $#{$edges[$i]} ) {
                   push @vertices, $edges[$i][$j];
               }
           }

       @uniqv = sort keys %{{map {$_,1} @vertices}};
    return @uniqv;
}


1;
__END__







