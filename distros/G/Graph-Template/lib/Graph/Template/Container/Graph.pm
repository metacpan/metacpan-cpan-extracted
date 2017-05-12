package Graph::Template::Container::Graph;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw( Graph::Template::Container );

    use Graph::Template::Container;
}

use Graph::Template::Constants qw( %GraphTypes );

sub render
{
    my $self = shift;
    my ($context) = @_;

    $self->{SIZE}    ||= 400;
    $self->{X_WIDTH} ||= $self->{SIZE};
    $self->{Y_WIDTH} ||= $self->{SIZE};

    $self->{TYPE} ||= 'vert_bars';
    my $type = $context->get($self, 'TYPE');
    my $class = $GraphTypes{$type}
        || die "'$type' is not a legal graph type.\n";

    eval {
        (my $filename = "GD::Graph::$class") =~ s!::!/!g;
        require "$filename.pm";
        "GD::Graph::$class"->import;
    }; if ($@) {
        die "Internal Error: Cannot compile 'GD::Graph::$class'!: $!\n";
    }

    my $graph = "GD::Graph::$class"->new(@{$self}{qw( X_WIDTH Y_WIDTH )});
    $self->{FORMAT} ||= $graph->export_format;

    for ($context)
    {
        $_->graph($graph);
        $_->format($self->{FORMAT});
    }

    return $self->SUPER::render($context);;
}

1;
__END__

=head1 NAME

Graph::Template::Container::Graph - Graph::Template::Container::Graph

=head1 PURPOSE

The root node

=head1 NODE NAME

GRAPH

=head1 INHERITANCE

Graph::Template::Container

=head1 ATTRIBUTES

=over 4

=item * X_WIDTH / Y_WIDTH / SIZE

These are the width of the final graph. The defaults for both X_WIDTH and Y_WIDTH
are 400. If SIZE is set, then that will be used instead of 400.

=item * TYPE

This is the chart type. You can choose from the following:

=over 4

=item * vert_bars (default)

Bar chart with the bars going vertically (from bottom to top)

=item * horiz_bars

Bar chart with the bars going horizontally (from left to right)

=item * line_graph

A graph with lines going from one point to another (similar to geometry class)

=item * point_graph

A graph with unconnected points

=item * line_point

A graph with points connected by lines

=item * pie

A standard pie-chart

=item * mixed (Currently unsupported)

This will allow mixed graphs, once I figure out a nice way for the template to
specify it. (If you have any ideas, please let me know.)

=back 4

Most of the types can support more than one dataset in the Y axis. The only
exception is 'pie'. (q.v. the POD for DATAPOINT for more details on this.)

=item * FORMAT

This is the output format. You can choose from any format your current version of
GD allows. The default is the return value from GD::Graph->export_format() (This
will be either png or gif, depending on if your version of GD supports gif or not.
Please see the GD and GD::Graph documentation for more details.)

=back 4

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

  <graph type="horiz_bars" format="jpeg" size="$graph_size">

    ... Children here ...

  </graph>

This will give you a jpeg of a chart with horizontal bars and a size set by the
graph_size parameter

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

GD, GD::Graph

=cut
