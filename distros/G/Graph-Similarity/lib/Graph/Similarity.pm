package Graph::Similarity;

use warnings;
use strict;

use version; 
our $VERSION = qv('0.0.5');

use Moose;

use Graph::Similarity::SimRank;
use Graph::Similarity::SimilarityFlooding;
use Graph::Similarity::CoupledNodeEdgeScoring;

has 'graph' => (is => 'rw', isa => 'ArrayRef[Graph]', required => 1);

__PACKAGE__->meta->make_immutable;
no Moose;

#===========================================================================
# Select which algorithm is used. And make sure the proper graph is used.
# arg1: algorithm - Please check perldoc for more details
#===========================================================================
sub use {
    my ($self, $algo) = @_; 
    my $g = $self->graph;

    my $method;
    if ($algo eq "SimRank") {

        die "This algorithm can only apply to single graph\n" if (scalar @$g != 1); 
        die "The graph needs to be directed graph\n" unless ($$g[0]->is_directed);
        $method = new Graph::Similarity::SimRank(graph => $$g[0]);

    }elsif ($algo eq "SimilarityFlooding"){

        die "This algorithm can only applied to two graph\n" if (scalar @$g != 2); 
        die "The graph needs to be multiedged\n" unless ($$g[0]->is_multiedged && $$g[1]->is_multiedged);
        die "The graph needs to be directed graph\n" unless ($$g[0]->is_directed && $$g[1]->is_directed);
        $method = new Graph::Similarity::SimilarityFlooding(graph => $g);
    }

    elsif ($algo eq "CoupledNodeEdgeScoring"){

        die "This algorithm can applied to only two graphs\n" if (scalar @$g != 2); 
        die "The graph needs to be directed graph\n" unless ($$g[0]->is_directed && $$g[1]->is_directed);
        $method = new Graph::Similarity::CoupledNodeEdgeScoring(graph => $g);
    }
    else {
        die "$algo is not supported\n";
    }

    return $method;
}




1; # Magic true value required at end of module
__END__

=head1 NAME

Graph::Similarity - Calculate similarity of the vertices in graph(s) 

=head1 VERSION

This document describes Graph::Similarity version 0.0.5


=head1 SYNOPSIS

    use Graph;
    use Graph::Similarity;

    my $g = Graph->new; # Use Graph module
    $g->add_vertices("a","b","c","d","e");
    $g->add_edges(['a', 'b'], ['b', 'c'], ['a', 'd'], ['d', 'e']);

    # Calculate by SimRank
    my $s = new Graph::Similarity(graph => [$g]);
    my $method = $s->use('SimRank');
    $method->setConstnact(0.8);
    $method->calculate();
    $method->showAllSimilarities;
    $method->getSimilarity("c","e"); 

    #===============================================
    # Or by Coupled Node Edge Scoring
    my $g1 = Graph->new;
    $g1->add_vertices("A","B","C");
    $g1->add_edges(['A', 'B'], ['B','C']);

    my $g2 = Graph->new;
    $g2->add_vertices("a","b","c","d","e");
    $g2->add_edges(['a', 'b'], ['b', 'c'], ['a', 'd'], ['d', 'e']);
    my $method = $s->use('CoupledNodeEdgeScoring');
    $method->calculate();
    $method->showAllSimilarities;

    #===============================================
    # Or by Similarity Flooding 
    my $g1 = Graph->new(multiedged => 1);
    $g1->add_vertices("I","coffee","apple","swim");
    $g1->add_edge_by_id("I", "coffee", "drink");
    $g1->add_edge_by_id("I", "swim", "can't");
    $g1->add_edge_by_id("I", "apple", "eat");

    my $g2 = Graph->new(multiedged => 1);
    $g2->add_vertices("she","cake","apple juice","swim");
    $g2->add_edge_by_id("she", "apple juice", "drink");
    $g2->add_edge_by_id("she", "swim", "can");
    $g2->add_edge_by_id("she", "cake", "eat");
    
    my $s = new Graph::Similarity(graph => [$g1,$g2]);
    my $method = $s->use('SimimilarityFlooding');
    $method->calculate();
    $method->showAllSimilarities;
  
=head1 DESCRIPTION

Graph is composed of vertices and edges (This is often also referred as nodes/edge in network).
Graph::Similarity calculate the similarity of the vertices(nodes) by the following algorithms,

=head3 SimRank 

=over 2

=item Jeh et al "SimRank: A Measure of Structural-Context Similarity"

=back

=head3 Coupled Node Edge Scoring

=over 2

=item Vincent D. Blondel et al "Measure of Similarity between Graph Vertices: Applications to Synonym Extraction and Web Searching"

=item Laura Zager "Graph Similarity and Matching" 

=back


=head3 Similarity Flooding 

=over 2

=item Melnik et al. "Similarity Flooding: A Versatile Graph Matching Algorithm and its Application to Schema Matching"

=back

The algorithm is implemented by referring to the above papers. Each module in implementation layer(Graph::Similarity::<algorithm>) explains briefly about the algorithm.
However, if you would like to know the details, please read the original papers.


=head1 USAGE 

=head2 $s = new Graph::Similarity(graph => [$g1, $g2])

Constructor. Create instance with L<Graph> argument. SimRank is one Graph, the others need two Graphs for the algorithm.

=head2 $method = $s->use($algorithm)  

$algorithm is either 'SimRank', 'CoupledNodeEdgeScoring' or 'SimilarityFlooding'
Return an object of method.

This use method verifies Graph feature to see whether it fits to the requirement. 
If there is no required feature, it dies out.
For example, when you specify two Graph in SimRank, it dies because SimRank needs to be calculated from one graph.

=head2 $method->calculate()

Using the method that is specified by use(), calculate the similarity. This returns a hash reference which is the results of calculation.

=head2 $method->setNumOfIteration($num)

Set the number of Iteration. The argument should be Integer.

=head2 $method->showAllSimilarities()

The results to STDOUT.     

=head2 $method->getSimilairity("X", "Y")

The vertex(node) has the name when it's created by Graph Module. Say, if you want to know the similarity between vertex "X" and "Y", use this method.

=head1 EXAMPLES

=head2 SimRank

As an example of SimRank, we use Fig1 in the paper. 

    use Graph;
    use Graph::Similarity;
    
    my $g = Graph->new;
    $g->add_vertices("Univ","ProfA","StudentA","ProfB","StudentB");
    $g->add_edges(['Univ', 'ProfA'],
                  ['ProfA', 'StudentA'],
                  ['StudentA', 'Univ'],
                  ['Univ', 'ProfB'],
                  ['ProfB', 'StudentB'],
                  ['StudentB', 'ProfB']);
    
    my $s = new Graph::Similarity(graph => [$g]);
    my $method = $s->use('SimRank');
    $method->setNumOfIteration(5);
    $method->setConst(0.8);
    my $result = $method->calculate();
    # print Dumper $result
    $method->showAllSimilarities();

The result is as follows. The number is very close to the Fig 1. 

    StudentA - StudentA : 1
    StudentA - ProfA : 0
    StudentA - StudentB : 0.33048576
    StudentA - Univ : 0
    StudentA - ProfB : 0.04096
    ProfA - StudentA : 0
    ProfA - ProfA : 1
    ProfA - StudentB : 0.1024
    ProfA - Univ : 0
    ProfA - ProfB : 0.4131072
    StudentB - StudentA : 0.33048576
    StudentB - ProfA : 0.1024
    StudentB - StudentB : 1
    StudentB - Univ : 0.032768
    StudentB - ProfB : 0.08445952
    Univ - StudentA : 0
    Univ - ProfA : 0
    Univ - StudentB : 0.032768
    Univ - Univ : 1
    Univ - ProfB : 0.128
    ProfB - StudentA : 0.04096
    ProfB - ProfA : 0.4131072
    ProfB - StudentB : 0.084983808
    ProfB - Univ : 0.132194304
    ProfB - ProfB : 1

=head2 Similarity Flooding

As an example, use Fig 3 in the papaer.

    use Graph;
    use Graph::Similarity;
    
    my $g1 = Graph->new(multiedged => 1);
    $g1->add_vertices("a","a1","a2");
    $g1->add_edge_by_id("a", "a1", "l1");
    $g1->add_edge_by_id("a", "a2", "l1");
    $g1->add_edge_by_id("a1", "a2", "l2");
    
    my $g2 = Graph->new(multiedged => 1);
    $g2->add_vertices("b","b1","b2");
    $g2->add_edge_by_id("b", "b1", "l1");
    $g2->add_edge_by_id("b", "b2", "l2");
    $g2->add_edge_by_id("b2", "b1", "l2");
    
    my $s = new Graph::Similarity(graph => [$g1,$g2]);
    my $method = $s->use('SimilarityFlooding');
    $method->setNumOfIteration(5);
    my $result = $method->calculate();
    # print Dumper $result
    $method->showAllSimilarities();

The result is the below. The edit distance is not used in the paper, whereas we use edit distance as initial value.
This causes the slight difference.

    a2 - b : 0.000115041702617199
    a2 - b1 : 0.917094477998274
    a2 - b2 : 0.191429393155019
    a - b : 1
    a - b1 : 0.000115041702617199
    a - b2 : 0.000115041702617199
    a1 - b : 0.191429393155019
    a1 - b1 : 0.385493960310613
    a1 - b2 : 0.699762726488352

=head2 Coupled Node-Edge Scoring 

Fig 1.2 in the paper, "Measure of Similarity between Graph Vertices: Applications to Synonym Extraction and Web Searching",
as an example. 

    use Graph;
    use Graph::Similarity;
    
    my $g1 = Graph->new();
    $g1->add_vertices("a1","a2","a3","a4");
    $g1->add_edges(["a1","a3"],["a1","a2"],["a2","a1"],["a2","a3"],
                                  ["a3","a2"],["a4","a1"],["a4","a3"]);
    
    my $g2 = Graph->new();
    $g2->add_vertices("b1","b2","b3","b4","b5","b6");
    $g2->add_edges(["b1","b3"],["b3","b1"],["b6","b1"],["b6","b3"],
                                  ["b3","b6"],["b3","b5"],["b2","b6"],["b2","b4"],
                                                 ["b1","b4"],["b6","b4"]);
    
    my $s = new Graph::Similarity(graph => [$g1,$g2]);
    my $method = $s->use('CoupledNodeEdgeScoring');
    $method->setNumOfIteration(50);
    my $result = $method->calculate();
    # print Dumper $result
    $method->showAllSimilarities();

The result is,

    b3 - a2 : 0.311518652195988
    b3 - a4 : 0.166703492014422
    b3 - a1 : 0.290390588307599
    b3 - a3 : 0.282452510821415
    b6 - a2 : 0.301149501715672
    b6 - a4 : 0.199935544942559
    b6 - a1 : 0.30383446637482
    b6 - a3 : 0.253224302437108
    b1 - a2 : 0.278635459119205
    b1 - a4 : 0.128928289895856
    b1 - a1 : 0.263618445136368
    b1 - a3 : 0.272302658479426
    b5 - a2 : 0.0758992640884854
    b5 - a4 : 0
    b5 - a1 : 0.0633623885302286
    b5 - a3 : 0.101837901214133
    b2 - a2 : 0.126836930942235
    b2 - a4 : 0.126836930942235
    b2 - a1 : 0.128617950209435
    b2 - a3 : 0.0624424971383059
    b4 - a2 : 0.170129852866194
    b4 - a4 : 0
    b4 - a1 : 0.15400277534204
    b4 - a3 : 0.246229188289944



=head1 DIAGNOSTICS

You may see the following error messages:

=over

=item C<This algorithm can only apply to single graph>

The algorithm needs to have single graph as argument.

=item C<The graph needs to be directed graph>

Undirected graph can't be applied to this algorithm.

=item C<The graph needs to be multiedged>

The algorithm needs to has multiedged graph with Graph->new(multiedged => 1)

=back

=head1 CONFIGURATION AND ENVIRONMENT

Graph::Similarity requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 AUTHOR

Shohei Kameda  C<< <shoheik@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Shohei Kameda C<< <shoheik@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
