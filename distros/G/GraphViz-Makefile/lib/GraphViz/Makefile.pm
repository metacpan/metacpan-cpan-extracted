# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2002,2003,2005,2008,2013,2020 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.rezic.de/eserte/
#

package GraphViz::Makefile;
use GraphViz2;
use Make;
use strict;
use warnings;
use Graph;

our $VERSION = '1.19';

our $V = 0 unless defined $V;
my @ALLOWED_ARGS = qw();
my %ALLOWED_ARGS = map {($_,undef)} @ALLOWED_ARGS;

our %NodeStyleTarget = (
    shape     => 'box',
    style     => 'filled',
    fillcolor => '#ffff99',
    fontname  => 'Arial',
    fontsize  => 10,
);
our %NodeStyleRecipe = (
    shape     => 'record',
    style     => 'filled',
    fillcolor => '#dddddd',
    fontname  => 'Monospace',
    fontsize  => 8,
);
our %NodeStyleRule = (
    shape => 'diamond',
    label => '',
);
my %GRAPHVIZ_GRAPH_ARGS = (global => {directed => 1, combine_node_and_port => 0});

sub new {
    my ($pkg, $g, $make, $prefix, %args) = @_;
    if (!$make) {
        $make = Make->new;
    } elsif (!UNIVERSAL::isa($make, "Make")) {
        my $makefile = $make;
        $make = Make->new;
        $make->parse($makefile);
    }
    my @illegal_args = grep !exists $ALLOWED_ARGS{$_}, keys %args;
    die "Unrecognized arguments @illegal_args, known arguments are @ALLOWED_ARGS"
        if @illegal_args;
    my $self = {
        GraphViz => $g,
        Make => $make,
        Prefix => ($prefix||""),
        %args,
    };
    bless $self, $pkg;
}

sub GraphViz { shift->{GraphViz} ||= GraphViz2->new(global => {combine_node_and_port => 0, directed => 1}) }
sub Make     { shift->{Make} }

sub generate {
    my ($self) = @_;
    $self->GraphViz->from_graph(graphvizify($self->generate_graph));
}

my %CHR2ENCODE = ("\\" => '\\\\', "\n" => "\\l");
my $CHR_PAT = join '|', map quotemeta, sort keys %CHR2ENCODE;
sub _recipe2label {
    my ($recipe) = @_;
    [
        [ map {
            my $t = $_; $t =~ s/($CHR_PAT)/$CHR2ENCODE{$1}/gs; "$t\\l";
        } @$recipe ]
    ];
}

sub graphvizify {
    my ($g) = @_;
    my $gvg = Graph->new;
    for my $v ($g->vertices) {
        my $attrs = $g->get_vertex_attributes($v);
        my ($type, $name) = @{ Make::name_decode($v) };
        $gvg->add_edge(@$_) for $g->edges_from($v);
        if ($type eq 'target') {
            $gvg->set_vertex_attribute($v, graphviz => {
                label => graphviz_escape($name),
                %NodeStyleTarget,
            });
        } else {
            my $recipe_raw = $attrs->{recipe_raw};
            if (!@$recipe_raw) {
                # bare rule
                $gvg->set_vertex_attribute($v, graphviz => \%NodeStyleRule);
                next;
            }
            $gvg->set_vertex_attribute($v, graphviz => {
                label => _recipe2label($recipe_raw),
                %NodeStyleRecipe,
            });
            for my $e ($g->edges_from($v)) {
                next if !defined(my $fromline = $g->get_edge_attribute(@$e, 'fromline'));
                $gvg->set_edge_attributes(@$e, { graphviz => {
                    tailport => ['port' . ($fromline+1), 'e'],
                } });
            }
        }
    }
    $gvg->set_graph_attribute(graphviz => \%GRAPHVIZ_GRAPH_ARGS);
    $gvg;
}

sub generate_graph {
    my ($self) = @_;
    my $prefix = $self->{Prefix};
    my $g = $self->{Make}->as_graph(recursive_make => 1);
    $g->rename_vertices(sub {
        my ($type, $name, @other) = @{ Make::name_decode($_[0]) };
        Make::name_encode([ $type, $prefix.$name, @other ]);
    });
}

my %GRAPHVIZ_ESCAPE = (
  "\n" => "n",
  map +($_ => $_), qw({ } " \\ < > [ ]),
);
my $GRAPHVIZ_ESCAPE_CHARS = join '|',
    map quotemeta, sort keys %GRAPHVIZ_ESCAPE;
sub graphviz_escape {
    my ($text) = @_;
    $text =~ s/($GRAPHVIZ_ESCAPE_CHARS)/\\$GRAPHVIZ_ESCAPE{$1}/gs;
    $text;
}

1;

__END__

=head1 NAME

GraphViz::Makefile - Create Makefile graphs using GraphViz

=head1 SYNOPSIS

Output to a .png file:

    use GraphViz::Makefile;
    my $gm = GraphViz::Makefile->new(undef, "Makefile");
    my $g = GraphViz2->new(global => {combine_node_and_port => 0, directed => 1});
    $g->from_graph(GraphViz::Makefile::graphvizify($gm->generate_graph));
    $g->run(format => "png", output_file => "makefile.png");

To output to a .ps file, just replace C<png> with C<ps> in the filename
and method above.

Or, using the deprecated mutation style:

    use GraphViz::Makefile;
    my $gm = GraphViz::Makefile->new(undef, "Makefile");
    $gm->generate;
    $gm->GraphViz->run(format => "png", output_file => "makefile.png");

=head1 DESCRIPTION

B<GraphViz::Makefile> uses the L<GraphViz2> and L<Make> modules to
visualize Makefile dependencies.

=head2 METHODS

=over

=item new($graphviz, $makefile, $prefix, %args)

Create a C<GraphViz::Makefile> object. The first argument should be a
C<GraphViz2> object or C<undef>. The second argument should be a
C<Make> object, the filename of a Makefile, or C<undef>. In the latter
case, the default Makefile is used. The third argument C<$prefix> is
optional and can be used to prepend a prefix to all rule names in the
graph output.

The created nodes are named C<$prefix$name>.

Further arguments (specified as key-value pairs): none at present.

=item generate

Generate the graph. Mutates the internal C<GraphViz2> object.

=item generate_graph

    my $gm = GraphViz::Makefile->new(undef, "Makefile");
    my $graph = $gm->generate_graph;
    $gv->from_graph(GraphViz::Makefile::graphvizify($graph));
    $gv->run(format => "png", output_file => "makefile.png");

Return a L<Graph> object representing this Makefile.

=item GraphViz

Return a reference to the C<GraphViz2> object. This object will be used
for the output methods. Will only be created if used. It is recommended
to instead use the C<generate_graph> method and make the calls on an
externally-controlled L<GraphViz2> object.

=item Make

Return a reference to the C<Make> object.
 
=back

=head1 FUNCTIONS

=head2 graphviz_escape

Turn characters in the given string, that are considered special by
GraphViz, into escaped versions so that they will appear literally as
given in the visualisation.

=head2 graphvizify

    my $gv_graph = GraphViz::Makefile::graphvizify($make_graph);

Given a L<Graph> object representing a makefile, creates a new object
to visualise it using L<GraphViz2/from_graph>.

=head1 ALTERNATIVES

There's another module doing the same thing: L<Makefile::GraphViz>.

=head1 AUTHOR

Slaven Rezic <srezic@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002,2003,2005,2008,2013 Slaven Rezic. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<GraphViz2>, L<Make>, L<make(1)>, L<tkgvizmakefile>.

=cut
