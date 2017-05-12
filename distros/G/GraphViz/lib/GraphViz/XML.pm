package GraphViz::XML;

use strict;
use warnings;
use Carp;
use lib '..';
use GraphViz;
use XML::Twig;

our $VERSION = '2.24';

=head1 NAME

GraphViz::XML - Visualise XML as a tree

=head1 SYNOPSIS

  use GraphViz::XML;

  my $graph = GraphViz::XML->new($xml);
  print $g->as_png;

=head1 DESCRIPTION

This module makes it easy to visualise XML as a tree. XML is hard for
humans to grasp, especially if the XML is computer-generated. This
modules aims to visualise the XML as a graph in order to make the
structure of the XML clear and to aid in understanding the XML.

XML elements are represented as diamond nodes, with links to elements
within them. Character data is represented in round nodes.

Note that the XML::Twig module should be installed.

=head1 METHODS

=head2 new

This is the constructor. It takes one mandatory argument, which is the
XML to be visualised. A GraphViz object is returned.

  my $graph = GraphViz::XML->new($xml);

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $xml   = shift;

    my $t = XML::Twig->new(no_xxe => 1);
    $t->parse($xml);
    my $graph = GraphViz->new();
    _init( $graph, $t->root );

    return $graph;
}

=head2 as_*

The XML can be visualised in a number of different graphical
formats. Methods include as_ps, as_hpgl, as_pcl, as_mif, as_pic,
as_gd, as_gd2, as_gif, as_jpeg, as_png, as_wbmp, as_ismap, as_imap,
as_vrml, as_vtx, as_mp, as_fig, as_svg. See the GraphViz documentation
for more information. The two most common methods are:

  # Print out a PNG-format file
  print $g->as_png;

  # Print out a PostScript-format file
  print $g->as_ps;

=cut

sub _init {
    my ( $g, $root ) = @_;

    #warn "$root $root->gi\n";

    my $label  = $root->gi;
    my $colour = 'blue';
    my $shape  = 'ellipse';

    if ( $root->is_pcdata ) {
        $label = $root->text;
        $label =~ s|^\s+||;
        $label =~ s|\s+$||;
        $colour = 'black';
    } else {
        $shape = "diamond";
    }

    $g->add_node( $root, label => $label, color => $colour, shape => $shape );
    foreach my $child ( $root->children ) {
        $g->add_edge( $root => $child );
        _init( $g, $child );
    }

}

=head1 BUGS

GraphViz tends to reorder the nodes. I hope to find a work around soon
(possibly with ports).

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001, Leon Brocard

This module is free software; you can redistribute it or modify it under the Perl License,
a copy of which is available at L<http://dev.perl.org/licenses/>.

=cut

1;
