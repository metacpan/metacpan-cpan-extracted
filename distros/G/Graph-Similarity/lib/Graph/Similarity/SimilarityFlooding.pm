package Graph::Similarity::SimilarityFlooding;

use strict;
use warnings;

use Graph;
use Moose;
use Text::Levenshtein qw(distance);

our $VERSION = '0.02';

with 'Graph::Similarity::Method';

has 'graph' => (is => 'rw', isa => 'ArrayRef[Graph]', required => 1);

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

    # Create InitialMap
    # Similarity is calculated by 1 - (edit distnace(stringA, stringB) / length of the stringA + stringB)
    # This calcualtion can be changed
    for my $v1 ($g1->vertices){
        for my $v2 ($g2->vertices){
            $sim{$v1}{$v2} = 1 - (distance($v1, $v2) / length("$v1$v2"));
            #print "$v1-$v2\n";
            #$sim{$v1}{$v2} = 1;
        }
    }

    # Create Pairwise Connectivity Graph
    my $pcg = Graph->new(multiedged => 1);

    # Frist, collect source, destination node and label
    # The is for Graph1
    my %m1;
    my %labels;
    for my $v1 ($g1->vertices){
        for my $p1 ($g1->predecessors($v1)){
            for my $label ($g1->get_multiedge_ids($p1, $v1)){
                # {"LABEL"}{"SOURCE NODE"}{"DESTINATION NODE"}
                $m1{$label}{$p1}{$v1} = 1; # There is no meaing to put 1. Just want to pickup unique key later
                $labels{$label} = 1;
            }
        }
    }
    # For Graph2
    my %m2;
    my @labels;
    for my $v2 ($g2->vertices){
        for my $p2 ($g2->predecessors($v2)){
            for my $label ($g2->get_multiedge_ids($p2, $v2)){
                # {"LABEL"}{"SOURCE NODE"}{"DESTINATION NODE"}
                $m2{$label}{$p2}{$v2} = 1;
                $labels{$label} = 1;
            }
        }
    }

    # Secondary, add pairwise node.
    # Node name is src1(from graph1)/src2(from graph2) or dest1(from graph1)/dest2(from graph2)
    # %edges used for couting the label of neighbors
    my %edges;
    for my $label (keys %labels) {
        #print $label, "------\n";
        for my $src1 (keys %{$m1{$label}}){
            for my $src2 (keys %{$m2{$label}}){
                for my $dest1 (keys %{$m1{$label}{$src1}}){
                    for my $dest2 (keys %{$m2{$label}{$src2}}){
                        #print "src - $src1,$src2\n";
                        #print "dest - $dest1,$dest2\n";
                        $pcg->add_edge_by_id("$src1/$src2", "$dest1/$dest2", $label );
                        $pcg->add_edge_by_id("$dest1/$dest2", "$src1/$src2", $label );
                        $edges{"$src1/$src2"}{$label}++;
                        $edges{"$dest1/$dest2"}{$label}++;
                    }
                }
            }
        }
    }



    # Start iteration 
    for (my $i=0; $i<$itr; $i++){
    
        # Based on label info, create the logic to behave as the same as "Induced Propagation Graph" in the paper
        my $max=0;
        my %next_sim;
        for my $v1 ($g1->vertices){
            for my $v2 ($g2->vertices){

                my $sum=0;
                for my $n ($pcg->neighbours("$v1/$v2")){
                    for my $label ($pcg->get_multiedge_ids($n, "$v1/$v2")){
                        #print 1/$edges{$n}{$label};
                        #print " * $n : neighbor of $v1/$v2\n";
                        my ($n1, $n2) = split /\//, $n;
                        $sum += $sim{$n1}{$n2} / $edges{$n}{$label};

                    }
                }

                $next_sim{$v1}{$v2} = $sim{$v1}{$v2} + $sum; 
                if ($max < $next_sim{$v1}{$v2}){
                    $max = $next_sim{$v1}{$v2};
                }
            }
        }


        # Normalizing
        # Deviding the maximum value
        for my $v1 ($g1->vertices){
            for my $v2 ($g2->vertices){

                if (defined $next_sim{$v1}{$v2}){
                    $sim{$v1}{$v2} = $next_sim{$v1}{$v2} / $max;
                }
                else {
                    $sim{$v1}{$v2} = $sim{$v1}{$v2} / $max;
                }
            }
        } 

    }

    $self->_setSimilarity(\%sim);
    return \%sim;
    #return 1;
}



=head1 NAME

Graph::Similarity::SimilarityFlooding -  Similarity Flooding implementation

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Please see L<Graph::Similarity>

=head1 DESCRIPTION 

This is the implementation of the below paper.

B<Sergey Melnik, Hector Garcia-Molina, Erhard Rahm "Similarity Flooding: A Versatile Graph Matching Algorithm
and its Application to Schema Matching">

=head1 METHODS

=head2 calculate()

This calculates Similarity Flooding. The algorithm is not clearly mentioned in the papeer.
I made it to code from reading "Figure 3. Example illustrating the Similarity Flooding Algorithm".

=head1 AUTHOR

Shohei Kameda, C<< <shoheik at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shohei Kameda.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Graph::Similarity::SimilarityFlooding
