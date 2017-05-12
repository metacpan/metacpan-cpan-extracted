#
# Graph::Writer::VCG - write a directed graph out in VCG format
#
package Graph::Writer::VCG;
$Graph::Writer::VCG::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

use parent 'Graph::Writer';

#-----------------------------------------------------------------------
# Attribute type information
#-----------------------------------------------------------------------
use constant VCG_ATTR_TYPE_INTEGER	=> 1;
use constant VCG_ATTR_TYPE_STRING	=> 2;
use constant VCG_ATTR_TYPE_FLOAT	=> 3;

my $enum_color = [qw(aquamarine black blue cyan darkblue darkcyan darkgreen
		darkgrey darkmagenta darkred darkyellow gold green khaki
		lightblue lightcyan lightgreen lightgrey lightmagenta
		lightred lightyellow lilac magenta orange orchid pink
		purple red turquoise white yellow yellowgreen)];
my $enum_yes_no = [qw(yes no)];
my $enum_textmode = [qw(center left_justify right_justify)];
my $enum_shape	= [qw(box rhomb ellipse triangle)];
my $enum_arrowstyle = [qw(none line solid)];

my %common_attrs =
(
    label => VCG_ATTR_TYPE_STRING,
    color => $enum_color,
    textcolor => $enum_color,
);


#-----------------------------------------------------------------------
# List of valid dot attributes for the entire graph, per node,
# and per edge. You can set other attributes, but they won't get
# written out.
#-----------------------------------------------------------------------
my %valid_attributes =
(
    graph => {

	    %common_attrs,

	    title		=> VCG_ATTR_TYPE_STRING,
	    info1		=> VCG_ATTR_TYPE_STRING,
	    info2		=> VCG_ATTR_TYPE_STRING,
	    info3		=> VCG_ATTR_TYPE_STRING,
	    bordercolor		=> $enum_color,
	    width		=> VCG_ATTR_TYPE_INTEGER,
	    height		=> VCG_ATTR_TYPE_INTEGER,
	    borderwidth		=> VCG_ATTR_TYPE_INTEGER,
	    x			=> VCG_ATTR_TYPE_INTEGER,
	    y			=> VCG_ATTR_TYPE_INTEGER,
	    # loc
	    folding		=> VCG_ATTR_TYPE_INTEGER,
	    scaling		=> VCG_ATTR_TYPE_FLOAT,
	    shrink		=> VCG_ATTR_TYPE_INTEGER,
	    stretch		=> VCG_ATTR_TYPE_INTEGER,
	    textmode		=> $enum_textmode,
	    shape		=> $enum_shape,
	    level		=> VCG_ATTR_TYPE_INTEGER,
	    vertical_order	=> VCG_ATTR_TYPE_INTEGER,
	    horizontal_order	=> VCG_ATTR_TYPE_INTEGER,
	    status		=> [qw(black grey white)],
	    xmax		=> VCG_ATTR_TYPE_INTEGER,
	    ymax		=> VCG_ATTR_TYPE_INTEGER,
	    xbase		=> VCG_ATTR_TYPE_INTEGER,
	    ybase		=> VCG_ATTR_TYPE_INTEGER,
	    xspace		=> VCG_ATTR_TYPE_INTEGER,
	    xlspace		=> VCG_ATTR_TYPE_INTEGER,
	    yspace		=> VCG_ATTR_TYPE_INTEGER,
	    xraster		=> VCG_ATTR_TYPE_INTEGER,
	    xlraster		=> VCG_ATTR_TYPE_INTEGER,
	    invisble		=> VCG_ATTR_TYPE_INTEGER,
	    hidden		=> VCG_ATTR_TYPE_INTEGER,
		# classname
		# colorentry
		# infoname
	    layoutalgorithm	=> [qw(tree maxdepth mindepth maxdepthslow
					mindepthslow maxdegree mindegree
					maxindegree minindegree maxoutdegree
					minoutdegree minbackward dfs)],
	    layout_downfactor	=> VCG_ATTR_TYPE_INTEGER,
	    layout_upfactor	=> VCG_ATTR_TYPE_INTEGER,
	    layout_nearfactor	=> VCG_ATTR_TYPE_INTEGER,
	    splinefactor	=> VCG_ATTR_TYPE_INTEGER,
	    late_edge_labels	=> $enum_yes_no,
	    display_edge_labels	=> $enum_yes_no,
	    dirty_edge_labels	=> $enum_yes_no,
	    finetuning		=> $enum_yes_no,
	    ignoresingles	=> $enum_yes_no,
	    straight_phase	=> $enum_yes_no,
	    priority_phase	=> $enum_yes_no,
	    manhattan_edges	=> $enum_yes_no,
	    smanhattan_edges	=> $enum_yes_no,
	    nearedges		=> $enum_yes_no,
	    orientation		=> [qw(top_to_bottom bottom_to_top
					left_to_right right_to_left)],
	    node_alignment	=> [qw(bottom top center)],
	    port_sharing	=> $enum_yes_no,
	    arrowmode		=> [qw(fixed free)],
	    spreadlevel		=> VCG_ATTR_TYPE_INTEGER,
	    treefactor		=> VCG_ATTR_TYPE_FLOAT,
	    crossingphase2	=> $enum_yes_no,
	    crossingoptimization=> $enum_yes_no,
	    crossingweight	=> [qw(bary median barymedian medianbary)],
	    view		=> [qw(cfish fcfish pfish fpfish)],
	    edges		=> $enum_yes_no,
	    nodes		=> $enum_yes_no,
	    splines		=> $enum_yes_no,
	    bmax		=> VCG_ATTR_TYPE_INTEGER,
	    cmax		=> VCG_ATTR_TYPE_INTEGER,
	    cmin		=> VCG_ATTR_TYPE_INTEGER,
	    pmax		=> VCG_ATTR_TYPE_INTEGER,
	    pmin		=> VCG_ATTR_TYPE_INTEGER,
	    rmax		=> VCG_ATTR_TYPE_INTEGER,
	    rmin		=> VCG_ATTR_TYPE_INTEGER,
	    smax		=> VCG_ATTR_TYPE_INTEGER,

		},
    node  => {

	    %common_attrs,

	    info1		=> VCG_ATTR_TYPE_STRING,
	    info2		=> VCG_ATTR_TYPE_STRING,
	    info3		=> VCG_ATTR_TYPE_STRING,
	    bordercolor		=> $enum_color,
	    width		=> VCG_ATTR_TYPE_INTEGER,
	    height		=> VCG_ATTR_TYPE_INTEGER,
	    borderwidth		=> VCG_ATTR_TYPE_INTEGER,
	    # loc
	    folding		=> VCG_ATTR_TYPE_INTEGER,
	    scaling		=> VCG_ATTR_TYPE_FLOAT,
	    shrink		=> VCG_ATTR_TYPE_INTEGER,
	    stretch		=> VCG_ATTR_TYPE_INTEGER,
	    textmode		=> $enum_textmode,
	    shape		=> $enum_shape,
	    level		=> VCG_ATTR_TYPE_INTEGER,
	    vertical_order	=> VCG_ATTR_TYPE_INTEGER,
	    horizontal_order	=> VCG_ATTR_TYPE_INTEGER,

	     },
    edge  => {

	    %common_attrs,

	    thickness		=> VCG_ATTR_TYPE_INTEGER,
	    class		=> VCG_ATTR_TYPE_INTEGER,
	    priority		=> VCG_ATTR_TYPE_INTEGER,
	    arrowcolor		=> $enum_color,
	    backarrowcolor	=> $enum_color,
	    arrowsize		=> VCG_ATTR_TYPE_INTEGER,
	    backarrowsize	=> VCG_ATTR_TYPE_INTEGER,
	    arrowstyle		=> $enum_arrowstyle,
	    backarrowstyle	=> $enum_arrowstyle,
	    linestyle		=> [qw(continuous solid dotted
					dashed invisible)],
	    anchor		=> VCG_ATTR_TYPE_INTEGER,
	    horizontal_order	=> VCG_ATTR_TYPE_INTEGER,

	     },
);

#=======================================================================
#
# _write_graph()
#
# The private method which actually does the writing out in
# VCG format.
#
# This is called from the public method, write_graph(), which is
# found in Graph::Writer.
#
#=======================================================================
sub _write_graph
{
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;

    my $v;
    my $from;
    my $to;
    my $aref;
    my @keys;


    #-------------------------------------------------------------------
    #-------------------------------------------------------------------
    print $FILE "graph: {\n";

    #-------------------------------------------------------------------
    # Dump out any overall attributes of the graph
    #-------------------------------------------------------------------
    $aref = $graph->get_graph_attributes();
    _render_attributes('graph', $aref, $FILE);

    #-------------------------------------------------------------------
    # Dump out a list of the nodes, along with any defined attributes
    #-------------------------------------------------------------------
    foreach $v (sort $graph->vertices)
    {
        print $FILE "  node: { title: \"$v\"";
        $aref = $graph->get_vertex_attributes($v);
        _render_attributes('node', $aref, $FILE, 1);
        print $FILE "  }\n";
    }
    print $FILE "\n";

    #-------------------------------------------------------------------
    # Dump out a list of the edges, along with any defined attributes
    #-------------------------------------------------------------------
    foreach my $edge (sort _by_vertex $graph->edges)
    {
        ($from, $to) = @$edge;
        print $FILE "  edge: { sourcename: \"$from\" targetname: \"$to\"";
        $aref = $graph->get_edge_attributes($from, $to);
        _render_attributes('edge', $aref, $FILE, 1);
        print $FILE "  }\n";
    }

    print $FILE "}\n";

    return 1;
}


sub _by_vertex
{
    return $a->[0].$a->[1] cmp $b->[0].$b->[1];
}


#=======================================================================
#
# _render_attributes
#
# Take a hash of attribute names and values and format
# as VCG attribute specs, quoting the value if needed.
# We filter the hash against legal attributes, since VCG will
# barf on unknown attribute names.
#
# Returns the number of attributes written out.
#
#=======================================================================
sub _render_attributes
{
    my $entity = shift;		# 'graph' or 'node' or 'edge'
    my $attref = shift;
    my $FILE   = shift;
    my $depth  = @_ > 0 ? shift : 0;

    my @keys;
    my $type;


    @keys = grep(exists $attref->{$_}, keys %{$valid_attributes{$entity}});
    if (@keys > 0)
    {
        print $FILE "\n";
        foreach my $a (@keys)
        {
            $type = $valid_attributes{$entity}->{$a};
            if (ref $type || $type == VCG_ATTR_TYPE_INTEGER
            || $type == VCG_ATTR_TYPE_FLOAT)
            {
                print $FILE "  ", '  ' x $depth, "$a: ", $attref->{$a}, "\n";
            }
            else
            {
                print $FILE "  ", '  ' x $depth,
                            "$a: \"", $attref->{$a}, "\"\n";
            }
        }
    }
    return int @keys;
}

1;

__END__

=head1 NAME

Graph::Writer::VCG - write out directed graph in VCG format

=head1 SYNOPSIS

  use Graph;
  use Graph::Writer::VCG;

  $graph = Graph->new();
  # add edges and nodes to the graph

  $writer = Graph::Writer::VCG->new();
  $writer->write_graph($graph, 'mygraph.vcg');

=head1 DESCRIPTION

B<Graph::Writer::VCG> is a class for writing out a directed graph
in the file format used by the I<VCG> tool, originally developed
for Visualising Compiler Graphs.
The graph must be an instance of the Graph class, which is
actually a set of classes developed by Jarkko Hietaniemi.

If you have defined any attributes for the graph,
nodes, or edges, they will be written out to the file,
as long as they are attributes understood by VCG.

=head1 METHODS

=head2 new()

Constructor - generate a new writer instance.

  $writer = Graph::Writer::VCG->new();

This doesn't take any arguments.

=head2 write_graph()

Write a specific graph to a named file:

  $writer->write_graph($graph, $file);

The C<$file> argument can either be a filename,
or a filehandle for a previously opened file.

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item *

Attributes with non-atomic values aren't currently handled.
This includes the B<loc>, B<classname>, B<colorentry>,
and B<infoname> attributes for graphs,
and the B<loc> attribute for nodes, 

=item *

Can currently only handle B<graph>, B<node>, and B<edge> elements
and their attributes.
So doesn't know about B<foldnode_defaults> and things like that.

=back

=head1 SEE ALSO

=over 4

=item http://www.cs.uni-sb.de/RW/users/sander/html/gsvcg1.html

The home page for VCG.

=item L<Graph>

Jarkko Hietaniemi's modules for representing directed graphs,
available from CPAN under modules/by-module/Graph/

=item Algorithms in Perl

The O'Reilly book which has a chapter on directed graphs,
which is based around Jarkko's modules.

=item L<Graph::Writer>

The base-class for Graph::Writer::VCG

=back

=head1 REPOSITORY

L<https://github.com/neilb/Graph-ReadWrite>

=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2001-2012, Neil Bowers. All rights reserved.
Copyright (c) 2001, Canon Research Centre Europe. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

