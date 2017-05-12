package Graph::Similarity::CoupledNodeEdgeScoring;

use strict;
use warnings;

use Moose;
use Graph;
use Math::Matrix;

our $VERSION = '0.02';

with 'Graph::Similarity::Method';

has 'graph' => (is => 'rw', isa => 'ArrayRef[Graph]', required => 1);
#has 'num_of_iteration'  => (is => 'rw', isa => 'Int', default => 10);

__PACKAGE__->meta->make_immutable;
no Moose;

sub calculate {
    my $self = shift;

    # Store similarity matrix $sim{vertex1}{vertex2} 
    my %sim;
    my $itr = $self->num_of_iteration;
    my $g = $self->graph;
    my $g1 = $$g[0];
    my $g2 = $$g[1];

    # Create Matrix
    # for graph1 
    my $adj1 = Graph::BitMatrix->new($g1);
    my @v1 = $adj1->vertices; # the sequence order is importanct. Keep this.
    my %v1;
    my @a1;
    my $c1=0;
    for my $v (@v1){
        $v1{$v}= $c1++;
        my @tmp = $adj1->get_row($v, @v1);
        push @a1, \@tmp;
    }
    my $m1 = new Math::Matrix(@a1);

    # for graph2
    my $adj2 = Graph::BitMatrix->new($g2);
    my @v2 = $adj2->vertices; 
    my %v2;
    my @a2;
    my $c2=0;
    for my $v (@v2){
        $v2{$v}= $c2++;
        my @tmp = $adj2->get_row($v, @v2);
        push @a2, \@tmp;
    }
    my $m2 = new Math::Matrix(@a2);

    # for initial z = 1
    my @z;
    for my $v2 (@v2){
        my @tmp;
        for my $v1 (@v1){
            push @tmp, 1;
        }
        push @z, \@tmp;
    }
    my $z = new Math::Matrix(@z);

    # loop should be even count
    $itr++ unless ($itr%2 == 0);

  for (my $i=0; $i<$itr;$i++){

        # B * Z * A^T
        my $tmp1 = $m2->multiply($z)->multiply($m1->transpose);
        # B^T * Z * A
        my $tmp2 = $m2->transpose->multiply($z)->multiply($m1);
        
        my $numerator = $tmp1->add($tmp2);

        my ($m, $n) = $numerator->size;

        my $sum=0;
        for my $row(0..($m-1)){
            for my $col (0..($n-1)){
                $sum += $numerator->[$row][$col] * $numerator->[$row][$col];
            }
        }
        my $denominator = sqrt($sum);
        $z = $numerator->multiply_scalar(1/$denominator);
    }

    my $i=0;
    for my $n2 (@v2){
        my $j=0;
        for my $n1 (@v1){
            $sim{$n2}{$n1} = $z->[$i][$j];
            $j++;
        }
        $i++;
    }

    $self->_setSimilarity(\%sim);
    return \%sim;
}



=head1 NAME

Graph::Similarity::CoupledNodeEdgeScoring - Coupled Node-Edge Scoring implementation 

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Please see L<Graph::Similarity>

=head1 DESCRIPTION 

This is the implementation of the below papers.

B<Vincent D. Blondel "A Measure of Similarity between Graph Vertices: Applications to Synonym Extraction and Web Searching">

and

B<Laura Zager "Graph Similarity and Matching">

=head1 METHODS

=head2 calculate()

This calculates Coupled Node-Edge Scoring. The algorithm is mentioned in Page.655 in Blondel's paper.
The convergence is not taken into account. Please set the number of iteration instead.

=head1 AUTHOR

Shohei Kameda, C<< <shoheik at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shohei Kameda.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Graph::Similarity::CoupledNodeEdgeScoring
