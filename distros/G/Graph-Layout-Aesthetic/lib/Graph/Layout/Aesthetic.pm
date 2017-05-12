package Graph::Layout::Aesthetic;
use 5.006001;
use strict;
use warnings;
use Carp;

use Graph::Layout::Aesthetic::Force;

our $VERSION = "0.12";

require XSLoader;
XSLoader::load('Graph::Layout::Aesthetic', $VERSION);

sub new {
    my ($class, $topology, $dimensions) = @_;
    $dimensions = 2 unless defined($dimensions);
    return $class->new_state($topology, $dimensions);
}

sub add_force {
    my $aglo = shift;
    defined(my $name = shift) || croak "No force name";
    $name =~ s/(?:^|_)([[:lower:]])/\u$1/g;
    my $force = Graph::Layout::Aesthetic::Force::name2force($name);
    $aglo->_add_force($force, @_);
}

sub gloss {
    my ($aglo, %params) = @_;

    my $beg_t = delete $params{begin_temperature};
    $beg_t = 1e2 if !defined $beg_t;

    my $end_t = delete $params{end_temperature};
    $end_t = 1e-3 if !defined $end_t;

    my $iter = delete $params{iterations};
    $iter = 1e3 if !defined $iter;
    croak "Iterations should be >= 0" if $iter < 0;
    croak "Iterations should be an integer" if $iter != int($iter);

    my $mon_delay = delete $params{monitor_delay};
    $mon_delay = 2 if !defined $mon_delay;
    croak "MonitorDelay should be >= 0" if $mon_delay < 0;

    my $monitor = delete $params{monitor};
    my $hold = delete $params{hold};

    croak "Unknown parameter ", join(", ", keys %params) if %params;

    $aglo->init_gloss($beg_t, $end_t, $iter, $hold ? -1 : 1);
    if ($monitor) {
        my $code;
        # In case the monitor call already says to pause
        $aglo->paused(0);
        if (ref($monitor) eq "CODE") {
            $monitor->($aglo);
            $code = 1;
        } else {
            $monitor->plot($aglo);
        }
        while ($aglo->iterations > 0 && !$aglo->paused) {
            $aglo->_gloss(time() + $mon_delay);
            if ($code) {
                $monitor->($aglo);
            } else {
                $monitor->plot($aglo);
            }
        }
    } elsif ($aglo->iterations > 0) {
        $aglo->_gloss;
    }
}

sub pause {
    return shift->paused(1);
}

sub coordinates_to_graph {
    my ($aglo, $graph, %params) = @_;

    my $pos = exists $params{pos_attribute} ?
        delete $params{pos_attribute} : "layout_pos";

    my $min_attr = exists $params{min_attribute} ?
        delete $params{min_attribute} : "layout_min";

    my $max_attr = exists $params{max_attribute} ?
        delete $params{max_attribute} : "layout_max";

    my $name = delete $params{id_attribute};
    $name = "layout_id" unless defined $name;

    croak "Unknown parameter ", join(", ", keys %params) if %params;

    my $ref_name = ref($name) && 1;
    my $id;
    if (ref $pos) {
        my $coordinates = $aglo->all_coordinates;
        my @pos = @$pos;
        @pos == $aglo->nr_dimensions || croak "Number of entries in the position attribute array must be equal to the number of dimensions";
        for my $vertex ($ref_name ? keys %$name : $graph->vertices) {
            defined($id = $ref_name ? $name->{$vertex} :
                    $graph->get_vertex_attribute($vertex, $name)) ||
                    croak "Vertex '$vertex' has no '$name' attribute";
            my $coordinate = $coordinates->[$id];
            $graph->set_vertex_attribute($vertex, $pos[$_], $coordinate->[$_])
                for 0..$#pos;
        }
    } elsif (defined($pos)) {
        my $coordinates = $aglo->all_coordinates;
        for my $vertex ($ref_name ? keys %$name : $graph->vertices) {
            defined($id = $ref_name ? $name->{$vertex} :
                    $graph->get_vertex_attribute($vertex, $name)) ||
                    croak "Vertex '$vertex' has no '$name' attribute";
            $graph->set_vertex_attribute($vertex, $pos, $coordinates->[$id]);
        }
    }

    if (defined $min_attr || defined $max_attr) {
        my ($min, $max) = $aglo->frame;

        if (ref $min_attr) {
            @$min_attr == $aglo->nr_dimensions || croak "Number of entries in the minimum attribute array must be equal to the number of dimensions";
            $graph->set_graph_attribute($_, shift @$min) for @$min_attr;
        } elsif (defined $min_attr) {
            $graph->set_graph_attribute($min_attr, $min);
        }

        if (ref $max_attr) {
            @$max_attr == $aglo->nr_dimensions || croak "Number of entries in the maximum attribute array must be equal to the number of dimensions";
            $graph->set_graph_attribute($_, shift @$max) for @$max_attr;
        } elsif (defined $max_attr) {
            $graph->set_graph_attribute($max_attr, $max);
        }
    }
}

sub gloss_graph {
    my $class = $_[0]->isa(__PACKAGE__) ? shift : __PACKAGE__;
    my ($graph, %params) = @_;

    my $literal = delete $params{literal};

    my $dim = delete $params{nr_dimensions};
    $dim = 2 unless defined($dim);

    my $pos = delete $params{pos_attribute};
    $pos = "layout_pos" unless defined $pos;

    defined(my $forces = delete $params{forces}) ||
        croak "No forces were defined";

    my @to_graph_params;
    exists $params{$_} && push @to_graph_params, $_, delete $params{$_} for
        qw(min_attribute max_attribute);

    require Graph::Layout::Aesthetic::Topology;
    my $topology = Graph::Layout::Aesthetic::Topology->from_graph
        ($graph,
         literal => $literal,
         id_attribute => \my %id);
    my $aglo = $class->new($topology, $dim);
    $aglo->add_force($_ => $forces->{$_}) for keys %$forces;

    # Pick up old coordinates if requested
    if ($params{hold}) {
        my $hold = $params{hold};
        $hold = $pos if !ref($hold) && $hold eq 1;
        if (ref($hold)) {
            my @hold = @$hold;
            @hold == $aglo->nr_dimensions || croak "Number of entries in the position attribute array must be equal to the number of dimensions";
            for my $vertex (keys %id) {
                $aglo->coordinates($id{$vertex}, map $graph->has_vertex_attribute($vertex, $_) ? $graph->get_vertex_attribute($vertex, $_) : croak("Attribute '$_' for vertex '$vertex' doesn't exist"), @hold);
            }
        } else {
            $aglo->coordinates($id{$_}, $graph->get_vertex_attribute($_, $hold) ||
                               croak "Attribute '$hold' for vertex '$_' is not an array reference") for keys %id;
        }
    }

    # This will implicitely check for bad parameters
    $aglo->gloss(%params);
    $aglo->coordinates_to_graph($graph,
                                id_attribute  => \%id,
                                pos_attribute => $pos,
                                @to_graph_params);
}

*layout = \&gloss_graph;

1;
__END__

=head1 NAME

Graph::Layout::Aesthetic - A module for laying out graphs

=head1 SYNOPSIS

  use Graph::Layout::Aesthetic;

  $aglo = Graph::Layout::Aesthetic->new($topology, ?$nr_dimensions?);
  $aglo->add_force($force ?, $weight?);
  @forces = $aglo->forces;
  $forces = $aglo->forces;
  $aglo->clear_forces;

  $nr_dimensions = $aglo->nr_dimensions;
  $topology = $aglo->topology;

  @old_vertex_coordinates = $aglo->coordinates($vertex?@new_vertex_coordinates?);
  $old_vertex_coordinates = $aglo->coordinates($vertex?@new_vertex_coordinates?);
  @old_coordinates = $aglo->all_coordinates(?@new_coordinates?);
  $old_coordinates = $aglo->all_coordinates(?@new_coordinates?);

  @edges = $aglo->increasing_edges;
  $edges = $aglo->increasing_edges;

  $aglo->zero;
  $aglo->randomize(?$size?);
  $aglo->jitter(?$distance?);
  ($min, $max) = $aglo->frame;
  ($min, $max) = $aglo->iso_frame;
  $aglo->normalize;

  $aglo->init_gloss($temperature, $end_temperature, $iterations ?,$randomize_size?);
  $aglo->step(?$temperature ?, $jitter_size??);
  $aglo->pause;
  $paused = $aglo->paused;
  $aglo->_gloss($end_time);
  # Valid parameter keys/value pairs are:
  #   begin_temperature => $temperature
  #   end_temperature   => $end_temperature
  #   iterations        => $iterations
  #   hold              => $boolean
  #   monitor           => $monitor
  #   monitor_delay     => $seconds
  $aglo->gloss(%parameters);
  @gradient = $aglo->gradient;
  $gradient = $aglo->gradient;
  $stress = $aglo->stress;

  $old_temperature   = $aglo->temperature(?$new_temperature ?, $warn??);;
  $old_end_temperature = $aglo->end_temperature(?$new_end_temperature ?,
    						$warn??);
  $old_iterations = $aglo->iterations(?$new_iterations?);

  $aglo->coordinates_to_graph($graph, %parameters);
  # Valid parameter keys/value pairs are:
  #   id_attribute  => $string
  #   id_attribute  => \%name_to_num
  #   pos_attribute => $string
  #   pos_attribute => \@strings
  #   min_attribute => $string
  #   min_attribute => \@strings
  #   max_attribute => $string
  #   max_attribute => \@strings

  Graph::Layout::Aesthetic->gloss_graph($graph, %parameters)
  # Valid parameter keys/value pairs are:
  #   literal           => $boolean
  #   nr_dimensions     => $integer
  #   forces            => \%forces
  #   begin_temperature => $temperature
  #   end_temperature   => $end_temperature
  #   iterations        => $iterations
  #   hold              => false or 1
  #   monitor           => $monitor
  #   monitor_delay     => $seconds
  #   pos_attribute     => $string
  #   pos_attribute     => \@strings

=head1 DESCRIPTION

A Graph::Layout::Aesthetic object represents a state in the process of laying
out a graph. The idea is that the state is repeatedly modified until an
acceptable layout is reached. This is done by considering the current state
from the point of view of a number of aesthetic criteria, each of which will
provide a step along which it would like to change the current state. A
weighted average is then taken of all these steps, leading to a proposed step.
The size of this step is then limited using a decreasing parameter (the
temperature) and applied. Small random disturbances may also be applied to
avoid getting stuck in a subspace.

The package also comes with a simple commandline tool L<gloss.pl|gloss.pl(1)>
(based on this package) that allows you to lay out graphs.

=head1 EXAMPLE1

  use Graph::Layout::Aesthetic;
  use Graph::Layout::Aesthetic::Monitor::GnuPlot;

  # Set up some $topology here, see Graph::Layout::Aesthetic::Toplogy
  my $aglo = Graph::Layout::Aesthetic->new($topology);

  # Decide what kind of aesthetic properties we want
  # We want nodes not to close to each other
  $aglo->add_force("node_repulsion");
  # We want edge lengths short
  $aglo->add_force("min_edge_length");

  # Do the actual layout and monitor progress (optional)
  $aglo->gloss(monitor => Graph::Layout::Aesthetic::Monitor::GnuPlot->new);

  # Display the result
  my $i;
  for ($aglo->all_coordinates) {
    print "Vertex ", $i++, ": @$_\n";
  }

=head1 EXAMPLE2

  use Graph 0.50;
  use Graph::Layout::Aesthetic;

  my $g = Graph->new(...);
  # set up your graph here

  Graph::Layout::Aesthetic->gloss_graph($g,
                                        forces => {
                                            node_repulsion  => 1,
                                            min_edge_length => 1
                                        });
  # That's all folks. Vertex positions will be in the "layout_pos" attribute

=head1 EXAMPLE3

See L<gloss.pl|gloss.pl> (found in the bin/ directory of the
Graph::Layout::Aesthetic distribution) for an example of a simple commandline
program based on this module. If you have L<gnuplot|gnuplot(1)> you can use
L<the examples documented there|gloss.pl/EXAMPLES> to view the kind of layouts
you can generate using this module.

=head1 METHODS

=over

=item X<new>$aglo = Graph::Layout::Aesthetic->new($topology, ?$nr_dimensions?)

Creates a new Graph::Layout::Aesthetic object that will be used to lay out
the graph described by the
L<finished|Graph::Layout::Aesthetic::Topology/finish>
L<Graph::Layout::Aesthetic::Topology|Graph::Layout::Aesthetic::Topology> object
$topology. The position space for each vertex is assumed to have $nr_dimensions
dimensions (defaults to 2 if not given).

Vertices start out without any particular positions (they may not even be valid
numbers). You'll have to do some initial placement yourself (notice that
L<gloss|"gloss"> already has a L<randomize|"randomize"> built in).

The initial temperature is 1e2, the end_temperature is 1e-3 and the default
number of iterations is 1000.

=item X<add_force>$aglo->add_force($force_name ?, $weight?)

The steps on the Graph::Layout::Aesthetic state are caused by applying forces
to the vertices that will supposedly make the graph layout more pleasing.
Each application of this method will add a new force named $force_name with
weight $weight (defaults to 1) working on the graph vertices.

$force_name has to be a name potentially known to
L<Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force>. Because
this will try to load force modules on demand, force names are first converted
to a style more in line with the one used for perl modules by using:

    $force_name =~ s/(?:^|_)([[:lower:]])/\u$1/g;

So if you use C<"node_repulsion"> as force name, it will actually try to
load L<Graph::Layout::Aesthetic::Force::NodeRepulsion|Graph::Layout::Aesthetic::Force::NodeRepulsion>. This package comes with a number of preprogrammed
forces, see L<Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force>
for a list.

There are no forces defined for a newly created
L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> object, so you'll have to
apply this method one or more times if you want anything to happen.

=item X<forces>@forces = $aglo->forces

Returns a list of the forces being applied to $aglo. Each element is a two
element array reference consisting of force and weight.

=item X<scalar_forces>$forces = $aglo->forces

This is the same as

    $forces = [$aglo->forces];

=item X<clear_forces>$aglo->clear_forces

Forgets about any forces that have been added (for example by using
L<add_force|"add_force">).

=item X<nr_dimensions>$nr_dimensions = $aglo->nr_dimensions

Returns the dimension of the space in which the vertices will be placed.

=item X<topology>$topology = $aglo->topology

Returns the
L<Graph::Layout::Aesthetic::Topology|Graph::Layout::Aesthetic::Topology>
object that's being laid out.

=item X<coordinates>@old_vertex_coordinates = $aglo->coordinates($vertex,?@new_vertex_coordinates?)

Returns the $nr_dimensions coordinates of vertex $vertex just before this call.

If @new_vertex_coordinates is given these become the new vertex coordinates.
Can be passed as a list of coordinates or as an array reference.

=item X<scalar_coordinates>$old_vertex_coordinates = $aglo->coordinates($vertex,?@new_vertex_coordinates?)

This is the same as:

    $old_vertex_coordinates = [$aglo->coordinates($vertex,@new_vertex_coordinates)];

If you just wanted to know how many elements are in a coordinate, this would of
course be the number of dimensions,

    $aglo->nr_dimensions;

=item X<all_coordinates>@old_coordinates = $aglo->all_coordinates(?@new_coordinates?)

Returns a list of coordinate references just before this call, one for each
vertex.

If @new_coordinates is given these become the new coordinates. Can be passed as
a list of coordinates or as an array reference.

=item X<scalar_all_coordinates>$old_coordinates = $aglo->all_coordinates(?@new_coordinates?)

This is the same as:

    $old_coordinates = [$aglo->all_coordinates(?@new_coordinates?)];

If you wanted to know how many elements there are in the all_coordinates list,
that would be the same as the number of vertices,

    $aglo->topology->nr_vertices;

=item X<increasing_edges>@edges = $aglo->increasing_edges

Returns a list of edges, where each edge is a reference to an array of
start point and end point. Each point itself again is represented by a
reference to its coordinates. The direction of the returned edges is from
lower numbered vertex to higher numbered vertex (so it ignores the direction
with which the edge was entered into the topology).

This method exists for backward compatibility with the way the original
L<gloss|gloss(1)> program reported the edge list. For many applications
it will probably make more sense to combine the result of
L<$topology-E<gt>edges|Graph::Layout::Aesthetic::Topology/edges> with
L<$aglo-E<gt>all_coordinates|"all_coordinates">.

=item X<scalar_increasing_edges>$edges = $aglo->increasing_edges

This is the same as

    $edges = [$aglo->increasing_edges];

=item X<zero>$aglo->zero

Sets all coordinates of all vertices to 0.

=item X<randomize>$aglo->randomize(?$size?)

For every coordinate of every vertex a random number (2*rand()-1)*$size is
chosen and assigned (but rand() returning exactly 0 is excluded).
$size defaults to 1 if not given.

=item X<jitter>$aglo->jitter(?$distance?)

Chooses one coordinate of one vertex and displaces it by
(rand()*2-1)*$distance (but rand() returning exactly 0 or 0.5 is excluded).
$distance defaults to 1e-5.

=item X<frame>($min, $max) = $aglo->frame

Calculates the smallest enclosing box of all coordinates. $min will be
a reference to minimal values for each coordinate, and $max a reference to
maximum values.

=item X<iso_frame>($min, $max) = $aglo->iso_frame

Calculates the smallest enclosing box of all coordinates where all box sizes
are the same. The box will be symmetrically placed around the box that would be
returned by L<frame|"frame">. $min will be a reference to minimal values for
each coordinate, and $max a reference to maximum values.

=item X<normalize>$aglo->normalize

Scales and moves all points so that the new iso_frame has minimum [0, 0, ..]
and maximum [1, 1,...].

=item X<init_gloss>$aglo->init_gloss($temperature, $end_temperature, $iterations?, $randomize_size?)

Sets new values for current (starting) $temperature, $end_temperature and
$iterations. If $randomize_size is bigger than 0 (the default is 1) it also
does a:

    $aglo->randomize($randomize_size);

This method is used before a new or restarted L<_gloss|"_gloss"> or to change
the initial default values.

=item X<step>$aglo->step(?$temperature ?, $jitter_size??)

Do a single step at temperature $temperature (defaults to $aglo->temperature)
and with jitter size $jitter_size (defaults to the minimum of 1e-5 and
temperature). A step involves:

=over

=item $aglo->jitter($jitter_size) if $jitter_size;

=item Calculate the weighted sum of all aesthetic forces

=item Limit the size of the displacement the combined force would like to cause to the $temperature if it's bigger (but keep the direction).

=item Apply the calculated displacement to all vertices

=back

Notice it doesn't change L<iterations|"iterations"> or
L<temperature|"temperature">.

=item X<pause>$aglo->pause

Normally the layout methods L<_gloss|"_gloss"> and L<gloss|"gloss"> run until
there are no more iteration to be done. By calling this method you set a flag
telling them to stop as soon as a new step would be taken. The only chance
you get to do this is normally during the
L<gloss monitor calbback|"gloss_monitor"> or during a
L<force gradient call|Graph::Layout::Aesthetic::Force/aesth_gradient>.

The pause flag is implictly cleared at object construction or when you enter
L<_gloss|"_gloss"> or L<gloss|"gloss">.

=item X<paused>$paused = $aglo->paused

Return true if layout is paused, false otherwise.

=item X<_gloss>$aglo->_gloss(?$end_time?)

A convenience method that repeatedly applies the L<step|"step"> method
until $end_time is reached, the target number of iterations is reached or
the layout gets L<paused|"pause">.
After each step it changes the temperature in the direction of the
end temperature. $end_time defaults to some huge number, so if it's not given
the loop will be completely controlled by the target number of iterations.
Giving 0 as $end_time will do only one step (including lowering of temperature
and iterations left).

_gloss basically equivalent to:

    if ($aglo->iterations <= 0) croak("No more iterations left");
    my $lambda = ($aglo->temperature / $aglo->end_temperature) ** (1 / $aglo->iterations);
    $aglo->paused(0);
    while ($aglo->iterations > 0 && !$aglo->paused) {
        $aglo->step;

        $aglo->temperature($aglo->temperature / lambda);
        $aglo->iterations( $aglo->iterations() - 1);

        return if $end_time <= time();
    }

=item X<gloss>$aglo->gloss(%parameters)

This method does a complete graph layout. It first sets temperatures and
iterations from the given %parameters (using L<init_gloss|"init_gloss">) and
L<randomizes|"randomize"> all coordinates (unless requested not to). It then
iterates as many times as requested (using L<_gloss|"_gloss">) or until the
layout gets L<paused|"pause">.

If requested it can also monitor the progress of the layout. This means that
at the start and at regular times thereafter (including the end) a given
callback gets called which can then do things like display the current
configuration. A simple monitor based on L<gnuplot|gnuplot(1)> comes with this
package, see L<Graph::Layout::Aesthetic::Monitor::GnuPlot|Graph::Layout::Aesthetic::Monitor::GnuPlot>.

%parameters represents key/value pairs used to pass parameters. Recognized are:

=over

=item X<gloss_begin_temperature>begin_temperature => $temperature

Starting temperature, defaults to 100

=item X<gloss_end_temperature>end_temperature => $end_temperature

Ending temperature, defaults to 1e-3

=item X<gloss_iterations>iterations => $iterations

Number of iterations requested, defaults to 1000.

=item X<gloss_hold>hold => $boolean

If given a false value (the default), all vertex coordinates will be
randomized before the iterations start. If given a true value, the
vertex coordinates will remain what they were before this method call
(supposedly because you did some explicit placement before or want to
further optimize a previously generated layout).

=item X<gloss_monitor>monitor => $monitor

If given, $monitor will be called once initially and then periodically (and
once for the final configuration) like this if it's a CODE reference:

    $monitor->($aglo);

and like this if it's an object:

    $monitor->plot($aglo);

You can use this to monitor (and optionally L<pause|"pause">) the layout
progress.

The default is no monitoring.

=item X<gloss_monitor_delay>monitor_delay => $seconds

Indicates that you want the monitor callback activated every $seconds seconds
(defaults to 2). The time is checked only at the end of each iteration, so
the callbacks can come at a lower rate if your steps take very long. Using 0
as delay will cause the monitor callback to be called after each iteration.

=back

=item X<gradient>@gradient = $aglo->gradient

Does an aesthetic forces calculation and returns the steps it would like to
apply to each vertex (neither jitter nor temperature based limitation will have
been applied). It returns a step for each vertex as an array reference to
coordinate displacements.

=item X<scalar_gradient>$gradient = $aglo->gradient

This is the same as

    $gradient = [$aglo->gradient];

If you just wanted to know how many elements are in the gradient, this
would be the same as the number of vertices, so

    $aglo->topology->nr_vertices;

=item X<stress>$stress = $aglo->stress

Returns the length of the gradient vector in the vertices*dimensions
dimensional configuration space. This gives you an idea about how good or
bad the current state is.

=item X<temperature>$old_temperature = $aglo->temperature(?$new_temperature ?, $warn??);

If given a $new_temperature argument, it will set the temperature to that. The
temperature will remain unchanged otherwise. If $warn is true (the default),
it will complain if you set the temperature to lower than the current
end_temperature.

In all cases it will return the temperature as it was just before this call.

=item X<end_temperature>$old_end_temperature = $aglo->end_temperature(?$new_end_temperature ?, $warn??)

If given a $new_end_temperature argument, it will set the end_temperature to
that. The end_temperature will remain unchanged otherwise. If $warn is true
(the default), it will complain if you set the end_temperature higher than the
current temperature.

In all cases it will return the end_temperature as it was just before this
call.

=item X<iterations>$old_iterations = $aglo->iterations(?$new_iterations?);

If given a $new_iterations argument, it will set the remaining iterations to
that. The number of iterations will remain unchanged otherwise.

In all cases it will return the number of iterations left as it was just before
this call.

=item X<coordinates_to_graph>$aglo->coordinates_to_graph($graph, %parameters)

Copies the current state coordinates of $aglo to vertex attributes of the
standard L<Graph|Graph> object $graph. It also stores
L<the containing frame|"frame"> as global graph attributes.

%parameters are key/value pairs. Recognized are:

=over

=item X<coordinates_to_graph_id_attribute>id_attribute => $name

$name is the the $graph vertices attribute that for each vertex identifies the
corresponding vertex in L<$aglo-E<gt>topology|"topology">, and defaults to
C<"layout_id">. It may also be a hash reference, in which case node ids are
looked up in the hash instead of as atrributes in the graph. So this argument
is compatible with the
L<id_attribute parameter|Graph::Layout::Aesthetic::Topology/from_graph_attribute>
of the
L<Graph::Layout::Aesthetic::Topology from_graph method|Graph::Layout::Aesthetic::Topology/from_graph>.

=item X<coordinates_to_graph_pos_attribute>pos_attribute => $name

$name is the $graph vertices attribute that will be used to set the
coordinates and defaults to C<"layout_pos"> if not given at all.

If $name is undef, no vertex attribute will be set.

If $name is a plain string, it will set an attribute with this name on each
vertex. The value will be an array reference to the coordinates of that vertex.

If $name is an array of names (size equal to the
L<number of dimensions of the layout space|"nr_dimensions">), then for each
vertex it will set an attribute for each element in $name whose value will be
the corresponding coordinate component. So if for example you want your $graph
nodes to have an attribute C<"layout_pos1"> for the first coordinate and
C<"layout_pos2"> for the second (this is what
L<Graph::Layouter|Graph::Layouter> uses and
L<Graph::Renderer|Graph::Renderer> expects) you could use:

  $aglo->coordinates_to_graph($graph,
                              pos_attribute => ["layout_pos1", "layout_pos2"]);
  # And now you can get the second coordinate of vertex foo by doing:
  my $y = $graph->get_vertex_attribute("foo", "layout_pos2");

=item X<coordinates_to_graph_min_attribute>min_attribute => $name

$name is the global graph attribute that will be used to set the minimum
coordinates for the frame containing all poins (see L<the frame method|"frame">
and defaults to C<"layout_min"> if not given at all.

Like L<pos_attribute|"coordinates_to_graph_pos_attribute"> you can give it
an undef value (attribute will not be set), a string (one attribute will be
set) or an array reference (an attribute will be set for each string in the
array).

=item X<coordinates_to_graph_max_attribute>max_attribute => $name

$name is the global graph attribute that will be used to set the maximum
coordinates for the frame containing all poins (see L<the frame method|"frame">
and defaults to C<"layout_max"> if not given at all.

Like L<pos_attribute|"coordinates_to_graph_pos_attribute"> you can give it
an undef value (attribute will not be set), a string (one attribute will be
set) or an array reference (an attribute will be set for each string in the
array).

So for complete compatibility with L<Graph::Layouter|Graph::Layouter> and
L<Graph::Renderer|Graph::Renderer> you can use:

  $aglo->coordinates_to_graph($graph,
                              pos_attribute => ["layout_pos1", "layout_pos2"],
                              min_attribute => ["layout_min1", "layout_min2"],
                              max_attribute => ["layout_max1", "layout_max2"]);

=back

=item X<gloss_graph>Graph::Layout::Aesthetic->gloss_graph($graph, %parameters)

This call combines
L<the Graph::Layout::Aesthetic::Topology from_graph method|Graph::Layout::Aesthetic::Topology/from_graph>,
L<gloss|"gloss"> and L<coordinates_to_graph|"coordinates_to_graph">,
effectively giving a one call layout of a standard L<Graph|Graph> object.

The parameters are key/value pairs and correspond to the ones from the above
mentioned methods:

=over

=item X<gloss_graph_literal>literal => $boolean

Corresponds to the
L<literal parameter|Graph::Layout::Aesthetic::Topology/from_graph_literal> to
L<the Graph::Layout::Aesthetic::Topology from_graph method|Graph::Layout::Aesthetic::Topology/from_graph>.

=item X<gloss_graph_nr_dimensions>nr_dimensions => $integer

The number of dimensions of the layout space. Defaults to 2.

=item X<gloss_graph_forces>forces => \%forces

Maps force names to weigths. All the forces in %forces will be added
with their corresponding weights using L<add_force|"add_force"> internally.
(see L<EXAMPLE2|EXAMPLE2>).

=item X<gloss_graph_begin_temperature>begin_temperature => $temperature

Starting temperature, defaults to 100.
The same as the L<gloss|"gloss"> L<begin_temperature parameter|"gloss_begin_temperature">.

=item X<gloss_graph_end_temperature>end_temperature => $end_temperature

Ending temperature, defaults to 1e-3
The same as the L<gloss|"gloss"> L<end_temperature parameter|"gloss_end_temperature">.

=item X<gloss_graph_iterations>iterations => $iterations

Number of iterations requested, defaults to 1000.
The same as the L<gloss|"gloss"> L<iterations parameter|"gloss_iterations">.

=item X<gloss_graph_hold>hold => $boolean

The same as the L<gloss|"gloss"> L<hold parameter|"gloss_hold"> meaning
no randomization is done if given a true value (default is false). In the case
the boolean is 1, the initial coordinates are retrieved from the same
attributes as where the results will be set (see the
L<pos_attribute parameter|"gloss_graph_pos_attribute">.

If the true value is not 1, it will behave in the same sort of way as the
L<pos_attribute parameter|"gloss_graph_pos_attribute"> parameter: if given
a string, that will be the attribute containing the starting coordinates,
if it's an array reference, the strings in there will correspond to the
components of the starting coordinates. So you can do something like this:

    # Set up starting coordinates of vertex_0
    $graph->set_vertex_attribute("vertex_0", "x_start", 1);
    $graph->set_vertex_attribute("vertex_0", "y_start", 1);
    # Set the other vertices too
    ...

    # Do layout
    Graph::Layout::Aesthetic->gloss_graph($graph,
                                          hold => ["x_start", "y_start"],
                                          pos_attribute => ["x_end", "y_end"],
                                          forces => {
                                              min_edge_length => 1,
                                              node_repulsion  => 1,
                                          });

    printf("The final coordinates of vertex_0 are (%f, %f)\n",
           $graph->get_vertex_attribute("vertex_0", "x_end"),
           $graph->get_vertex_attribute("vertex_0", "y_end"));
    # Print the other vertices too
    ...

=item X<gloss_graph_monitor>monitor => $monitor

The same as the L<gloss|"gloss"> L<monitor parameter|"gloss_monitor">.

=item X<gloss_graph_monitor_delay>monitor_delay => $seconds

The same as the L<gloss|"gloss">
L<monitor_delay parameter |"gloss_monitor_delay">

=item X<gloss_graph_pos_attribute>pos_attribute => $string

The same as the L<coordinates_to_graph|"coordinates_to_graph">
L<pos_attribute parameter|"coordinates_to_graph_pos_attribute">
(and also defaults to C<"layout_pos">.
It's also the default attribute initial coordinates come from
if L<hold|gloss_graph_hold> is 1.

=item X<gloss_graph_graph_min_attribute>min_attribute => $name

The same as the L<coordinates_to_graph|"coordinates_to_graph">
L<min_attribute parameter|"coordinates_to_graph_min_attribute">.

=item X<gloss_graph_graph_max_attribute>max_attribute => $name

The same as the L<coordinates_to_graph|"coordinates_to_graph">
L<max_attribute parameter|"coordinates_to_graph_max_attribute">.

=back

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<http://www.cs.ucla.edu/~stott/aglo/>,
L<Graph::Layout::Aesthetic::Topology>,
L<Graph::Layout::Aesthetic::Force>,
L<Graph::Layout::Aesthetic::Monitor::GnuPlot>

Other relevant modules:

L<Graph>,
L<Graph::Layouter>,
L<Graph::Renderer>,
L<GraphViz>

=head1 BUGS

Not threadsafe. Different object may have method calls going on at the same
time, but any specific object should only have at most one call active.
Notice that all forces coming with this package are threadsafe, so it's ok
if your different objects use the same forces at the same time.

=head1 AUTHOR

Ton Hospel, E<lt>Graph-Layout-Aesthetic@ton.iguana.beE<gt> for the perl code
and the L<XS|perlxs> wrappers.

Much of the C code is equal to or derived from the original code by
D. Stott Parker.

=head1 COPYRIGHT AND LICENSE

Much of the C code is copyrighted by D. Stott Parker, who released it under
the GNU GENERAL PUBLIC LICENSE (version 1).

Copyright (C) 2004 by Ton Hospel for the perl code and the L<XS|perlxs>
wrappers. To be compatible with the original license these pieces are also
under the GNU GENERAL PUBLIC LICENSE.

=cut
