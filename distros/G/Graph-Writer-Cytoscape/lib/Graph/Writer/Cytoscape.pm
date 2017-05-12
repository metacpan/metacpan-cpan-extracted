package Graph::Writer::Cytoscape;

use warnings;
use strict;

use parent 'Graph::Writer';

=head1 NAME

Graph::Writer::Cytoscape - Write a directed graph out as Cytoscape competible input file

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Graph;
    use Graph::Writer::Cytoscape;
    
    $graph = Graph->new();
    # add edges and nodes to the graph
    
    $writer = Graph::Writer::Cytoscape->new();
    $writer->write_graph($graph, 'mygraph');

=head1 SUBROUTINES/METHODS

=head2 _write_graph

=cut

sub _write_graph
{
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;
	
	my $v;
    my $from;
    my $to;
    my $aref;
    my $time = time;
    my %titles;
    
	
    #-------------------------------------------------------------------
    # dump out vertices of the graph, including any attributes
    #-------------------------------------------------------------------
    foreach $v (sort $graph->vertices)
    {
	$aref = $graph->get_vertex_attributes($v);

	if (keys(%{ $aref }) > 0)
	{

	    foreach my $attr (keys %{ $aref })
	    {
	    	open(OUT_NODE, ">>",$time."_NODE_".$attr.".txt") or die("No output!\n");
	    	
	    	if (!$titles{$attr}) 
	    	{
	    		print OUT_NODE $attr,"Attribute\n";
				$titles{$attr} = 1;	
	    	}
	    	
			print OUT_NODE $v," = ",$aref->{$attr},"\n";
			close(OUT_NODE);
	    }
	}
	else
	{
	    #Do nothing if it is empty
	}
    }
	
	%titles = (); #clean the hash
	
	#-------------------------------------------------------------------
    # dump out edges of the graph, including any attributes
    #-------------------------------------------------------------------
    foreach my $edge (sort _by_vertex $graph->edges)
    {
	($from, $to) = @$edge;
	$aref = $graph->get_edge_attributes($from, $to);
	if (keys(%{ $aref }) > 0)
	{
	    
	    foreach my $attr (keys %{ $aref })
	    {
			open(OUT_EDGE, ">>",$time."_EDGE_".$attr.".txt") or die("No output!\n");
	    	if (!$titles{$attr}) 
	    	{
	    		print OUT_EDGE $attr,"\n";
				$titles{$attr} = 1;	
	    	}
	    	print OUT_EDGE $from," (pp) ",$to," = ", $aref->{$attr},"\n"; 
	    	
	    	open(OUT_NETWORK, ">>",$time."_NETWORK.sif") or die("No output!\n");
	    	print OUT_NETWORK $from," pp ",$to,"\n";
	    	close(OUT_NETWORK);
	    	
			close(OUT_EDGE);
	    }
	}
	else
	{
	    #Do nothing if it is empty
	}
    }
        
    return 1;
}

sub _by_vertex
{
    return $a->[0].$a->[1] cmp $b->[0].$b->[1];
}

=head1 AUTHOR

Haktan Suren, C<< <hsuren at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-graph-writer-cytoscape at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Writer-Cytoscape>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DESCRIPTION

B<Graph::Writer::Cytoscape> is a class for writing out a directed graph
as Cytoscape competible input file.

The graph must be an instance of the Graph class, which is
actually a set of classes developed by Jarkko Hietaniemi.

The Cytoscape format is designed to support Cytoscape program, It simply
generates the necessary files for Cytoscape. So, it allows you to use Graphviz
file in Cytoscape.   

The graph, nodes, and edges can all have attributes specified,
where an attribute is a (name,value) pair, with the value being scalar.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Graph::Writer::Cytoscape


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Writer-Cytoscape>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-Writer-Cytoscape>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-Writer-Cytoscape>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-Writer-Cytoscape/>

=back


=head1 ACKNOWLEDGEMENTS

All credits go to Neil Bowers for developing B<Graph::Writer> class.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Haktan Suren.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Graph::Writer::Cytoscape
