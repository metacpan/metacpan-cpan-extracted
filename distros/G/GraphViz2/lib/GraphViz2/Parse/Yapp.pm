package GraphViz2::Parse::Yapp;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '2.47';

use GraphViz2;
use Moo;
use Graph::Directed;

my %EDGEATTR = (headport => 'port1');
my %GRAPHVIZ_ARGS = (
    edge   => {color => 'grey'},
    global => {directed => 1, combine_node_and_port => 0},
    graph  => {rankdir => 'TB'},
    node   => {color => 'blue', shape => 'oval'},
);

has as_graph => (
    is       => 'lazy',
    required => 0,
);
sub _build_as_graph { to_graph($_[0]->file_name) }

has graph => (
    is       => 'lazy',
    #isa     => 'GraphViz2',
    required => 0,
);
sub _build_graph {
    GraphViz2->new(%GRAPHVIZ_ARGS)->from_graph(graphvizify($_[0]->as_graph));
}

has file_name => (
    is       => 'rw',
    required => 0,
);

sub read_file {
  open my $fh, '<:encoding(UTF-8)', $_[0] or die "$_[0]: $!";
  map +((chomp, $_)[1]), <$fh>;
}

sub create {
    my ($self, %arg) = @_;
    $self->file_name($arg{file_name});
    $self->graph->from_graph(graphvizify($self->as_graph));
    return $self;
}

sub to_graph {
    my ($file_name) = @_;
    my $g = Graph::Directed->new;
    my (%edges, %labels);
    for my $line (read_file($file_name)) {
        next if ($line !~ /\w/) || ($line !~ /^\d+:\s+/);
        $line =~ s/^\d+:\s+//;
        my ($rule, $text) = split ' -> ', $line, 2;
        $text = '(empty)' if ($text eq '/* empty */');
        push @{$labels{$rule}}, $text;
        @{$edges{$rule}}{split ' ', $text} = (); # only needs to exist
    }
    for my $f (keys %edges) {
        $g->add_edges(map [$f, $_], grep $edges{$_}, keys %{$edges{$f}});
        $g->set_vertex_attribute($f, labels => $labels{$f});
    }
    $g;
}

sub _quote { my $t = $_[0]; $t =~ s/\\/\\\\/g; $t; }

sub graphvizify {
    my ($g) = @_;
    for my $v ($g->vertices) {
        $g->set_vertex_attribute($v, graphviz => {
            label => [$v, [ map _quote($_).'\\l', @{$g->get_vertex_attribute($v, 'labels')} ]],
        });
        $g->set_edge_attribute(@$_, graphviz => \%EDGEATTR) for $g->edges_from($v);
    }
    $g->set_graph_attribute(graphviz => { global => $GRAPHVIZ_ARGS{global} });
    $g;
}

1;

=head1 NAME

L<GraphViz2::Parse::Yapp> - Visualize a yapp grammar as a graph

=head1 SYNOPSIS

    use GraphViz2::Parse::Yapp;
    # no objects - quicker
    my $gd = GraphViz2::Parse::Yapp::to_graph('t/calc.output');

    # populate a GraphViz2 object with a Graph::Directed of a parser
    my $gv = GraphViz2->from_graph(GraphViz2::Parse::Yapp::graphvizify($gd));

    # OO interface, using lazy-built attributes
    my $gvp = GraphViz2::Parse::Yapp->new(file_name => $file_name);
    my $gd = $gvp->as_graph; # Graph::Directed object
    # or supply a suitable Graph::Directed object
    my $gvp = GraphViz2::Parse::Yapp->new(as_graph => $gd);
    # then get the GraphViz2 object
    my $gv = $gvp->graph;

    # DEPRECATED ways to get $gvp with populated $gv
    my $gvp = GraphViz2::Parse::Yapp->new;
    $gvp->create(file_name => 't/calc.output');
    my $gv = $gvp->graph;
    # or give it a pre-set-up GraphViz2 object
    my $gv = GraphViz2->new(...);
    my $gvp = GraphViz2::Parse::Yapp->new(graph => $gv);
    # call ->create as above

    # produce a visualisation
    my $format = shift || 'svg';
    my $output_file = shift || "output.$format";
    $gv->run(format => $format, output_file => $output_file);

See F<t/gen.parse.yapp.pl>.

=head1 DESCRIPTION

Takes a yapp grammar and converts it into a L<Graph::Directed>
object, or directly into a L<GraphViz2> object.

=head1 FUNCTIONS

This is the recommended interface.

=head2 to_graph

    my $gd = GraphViz2::Parse::Yapp::to_graph('t/calc.output');

Given a yapp grammar, returns a L<Graph::Directed> object
describing the finite state machine for it.

=head2 graphvizify

    my $gv = GraphViz2->from_graph(GraphViz2::Parse::Yapp::graphvizify($gd));

Mutates the given graph object to add to it the C<graphviz> attributes
visualisation "hints" that will make the L<GraphViz2/from_graph> method
visualise this regular expression in the most meaningful way, including
labels and groupings.

It is idempotent as it simply sets the C<graphviz> attribute of the
relevant graph entities.

Returns the graph object for convenience.

=head1 METHODS

This is a L<Moo> class, but with a recommended functional interface.

=head2 Constructor attributes

=head3 file_name

The name of a yapp output file. See F<t/calc.output>.

This key is optional. You need to provide it by the time you access
either the L</as_graph> or L</graph>.

=head3 as_graph

The L<Graph::Directed> object to use. If not given, will be lazily built
on access, from the L</regexp>.

=head3 graph

The L<GraphViz2> object to use. This allows you to configure it as desired.

This key is optional. If provided, the C<create> method will populate it.
If not, it will have these defaults, lazy-built and populated from the
L</as_graph>.

    my $gv = GraphViz2->new(
            edge   => {color => 'grey'},
            global => {directed => 1},
            graph  => {rankdir => 'TB'},
            node   => {color => 'blue', shape => 'oval'},
    );

=head2 create(regexp => $regexp)

DEPRECATED. Mutates the object to set the C<file_name> attribute, then
accesses the C<as_graph> attribute (possibly lazy-building it), then
C<graphvizify>s its C<as_graph> attribute with that information, then
C<from_graph>s its C<graph>.

Returns $self for method chaining.

=head1 THANKS

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 AUTHOR

L<GraphViz2> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 COPYRIGHT

Australian copyright (c) 2011, Ron Savage.

All Programs of mine are 'OSI Certified Open Source Software';
you can redistribute them and/or modify them under the terms of
The Perl License, a copy of which is available at:
http://dev.perl.org/licenses/

=cut
