package Map::Tube::GraphViz;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use GraphViz2;
use List::MoreUtils qw(none);
use Map::Tube::GraphViz::Utils qw(node_color);
use Scalar::Util qw(blessed);

our $VERSION = 0.07;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Edge callback.
	$self->{'callback_edge'} = sub {
		my ($self, $from, $to) = @_;
		$self->{'g'}->add_edge(
			'from' => $self->{'callback_node_id'}->($self, $from),
			'to' => $self->{'callback_node_id'}->($self, $to),
		);
		return;
	};

	# Node callback.
	$self->{'callback_node'} = \&node_color;

	# Node id callback.
	$self->{'callback_node_id'} = sub {
		my ($self, $node) = @_;
		return $node->name;
	};

	# Driver.
	$self->{'driver'} = 'neato';

	# Name of map.
	$self->{'name'} = undef;

	# GraphViz2 object.
	$self->{'g'} = undef;

	# Output.
	$self->{'output'} = 'png';

	# Map::Tube object.
	$self->{'tube'} = undef;

	# Process params.
	set_params($self, @params);

	# Check Map::Tube object.
	if (! defined $self->{'tube'}) {
		err "Parameter 'tube' is required.";
	}
	if (! defined &UNIVERSAL::DOES) {
		eval {
			require UNIVERSAL::DOES;
		};
		if ($EVAL_ERROR) {
			err 'Cannot load UNIVERSAL::DOES module.';
		}
	}
	if (! blessed($self->{'tube'})
		|| ! $self->{'tube'}->DOES('Map::Tube')) {

		err "Parameter 'tube' must be 'Map::Tube' object.";
	}

	# GraphViz2 object.
	if (defined $self->{'g'}) {
		if (defined $self->{'name'}) {
			err "Parameter 'name' cannot be used with ".
				"'g' parameter.";
		}

		# Check GraphViz2 object.
		if (! blessed($self->{'g'})
			|| ! $self->{'g'}->isa('GraphViz2')) {

			err "Parameter 'g' must be 'GraphViz2' object.";
		}
	} else {
		my $name = $self->{'name'};
		if (! defined $name) {
			$name = $self->{'tube'}->name;
		}
		$self->{'g'} = GraphViz2->new(
			'global' => {
				'directed' => 0,
			},
			$name ? (
				'graph' => {
					'label' => $name,
					'labelloc' => 'top',
				},
			) : (),
		);
	}

	# Check output format.
	if (! defined $self->{'output'}) {
		err "Parameter 'output' is required.";
	}
	if (! exists $self->{'g'}->valid_output_format->{$self->{'output'}}) {
		err "Unsupported 'output' parameter '$self->{'output'}'.";
	}

	# Object.
	return $self;
}

# Get graph.
sub graph {
	my ($self, $output_file) = @_;
	my $node_cache_hr = {};
	foreach my $node (values %{$self->{'tube'}->nodes}) {
		$self->{'callback_node'}->($self, $node);
		$node_cache_hr->{$node->id} = $node;
	}
	my @processed;
	foreach my $node (values %{$self->{'tube'}->nodes}) {
		foreach my $link (split m/,/ms, $node->link) {
			if (none {
				($_->[0] eq $node->id && $_->[1] eq $link) 
				|| 
				($_->[0] eq $link && $_->[1] eq $node->id)
				} @processed) {

				# Skip link to myself.
				my $link_node = $node_cache_hr->{$link};
				if ($self->{'callback_node_id'}->($self, $node)
					ne $self->{'callback_node_id'}
					->($self, $link_node)) {

					$self->{'callback_edge'}->($self, $node,
						$link_node);
				}
				push @processed, [$node->id, $link];
			}
		}
	}
	eval {
		$self->{'g'}->run(
			'driver' => $self->{'driver'},
			'format' => $self->{'output'},
			'output_file' => $output_file,
		);
	};
	if ($EVAL_ERROR) {
		err 'Cannot create GraphViz output.',
			'Error', $EVAL_ERROR,
			'Dot input', $self->{'g'}->dot_input;
	}
	return;
}

1;

__END__

=encoding utf8

=head1 NAME

Map::Tube::GraphViz - GraphViz output for Map::Tube.

=head1 SYNOPSIS

 use Map::Tube::GraphViz;

 my $obj = Map::Tube::GraphViz->new(%params);
 $obj->graph($output_file);

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<callback_edge>

 Edge callback.
 Default value is this:
 sub { 
         my ($self, $from, $to) = @_;
         $self->{'g'}->add_edge(
         	'from' => $from,
         	'to' => $to,
         );
         return;
 }

=item * C<callback_node>

 Node callback.
 Default value is \&Map::Tube::GraphViz::Utils::node_color.

=item * C<driver>

 GraphViz2 driver.
 Default value is 'neato'.

=item * C<g>

 GraphViz2 object.
 Parameters 'g' and 'name' cannot combine.
 Default value is this:
 GraphViz2->new(
 	'global' => {
 		'directed' => 0,
 	},
 	$name ? (
 		'graph' => {
 			'label' => $name,
 			'labelloc' => 'top',
 		},
 	) : (),
 );

=item * C<name>

 Name of map.
 Parameters 'g' and 'name' cannot combine.
 Default value is Map::Tube->name or undef.

=item * C<output>

 GraphViz2 output.
 It is required.
 Default value is 'png'.
 Possible values are every formats supported by GraphViz2 module.
 See L<http://www.graphviz.org/content/output-formats>.

=item * C<tube>

 Map::Tube object.
 It is required.
 Default value is undef.

=back

=item C<graph($output_file)>
 
 Get graph and save it to $output_file file.
 Returns undef.

=back

=head1 ERRORS

 new():
         Cannot load UNIVERSAL::DOES module.
         Parameter 'tube' is required.
         Parameter 'tube' must be 'Map::Tube' object.
         Parameter 'output' is required.
         Unsupported 'output' parameter '%s'.
         From Map::Tube::GraphViz::Utils::color_line():
                 No color for line '%s'.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use English;
 use Error::Pure qw(err);
 use Map::Tube::GraphViz;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 metro\n";
         exit 1;
 }
 my $metro = $ARGV[0];
 
 # Object.
 my $class = 'Map::Tube::'.$metro;
 eval "require $class;";
 if ($EVAL_ERROR) {
         err "Cannot load '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # Metro object.
 my $tube = eval "$class->new";
 if ($EVAL_ERROR) {
         err "Cannot create object for '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # GraphViz object.
 my $g = Map::Tube::GraphViz->new(
         'tube' => $tube,
 );
 
 # Get graph to file.
 $g->graph($metro.'.png');

 # Print file.
 system "ls -l $metro.png";

 # Output without arguments like:
 # Usage: /tmp/SZXfa2g154 metro

 # Output with 'Berlin' argument like:
 # -rw-r--r-- 1 skim skim 1503067 Jan 27 07:24 Berlin.png

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex1.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex1.png" alt="Berlin" width="300px" height="300px" />
</a>

=end html

=head1 EXAMPLE2

 use strict;
 use warnings;

 use English;
 use Error::Pure qw(err);
 use Map::Tube::GraphViz;
 use Map::Tube::GraphViz::Utils qw(node_color_without_label);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 metro\n";
         exit 1;
 }
 my $metro = $ARGV[0];
 
 # Object.
 my $class = 'Map::Tube::'.$metro;
 eval "require $class;";
 if ($EVAL_ERROR) {
         err "Cannot load '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # Metro object.
 my $tube = eval "$class->new";
 if ($EVAL_ERROR) {
         err "Cannot create object for '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # GraphViz object.
 my $g = Map::Tube::GraphViz->new(
         'callback_node' => \&node_color_without_label,
         'tube' => $tube,
 );
 
 # Get graph to file.
 $g->graph($metro.'.png');

 # Print file.
 system "ls -l $metro.png";

 # Output without arguments like:
 # Usage: /tmp/SZXfa2g154 metro

 # Output with 'Berlin' argument like:
 # -rw-r--r-- 1 skim skim 885928 Jan 27 07:43 Berlin.png

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex2.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex2.png" alt="Berlin" width="300px" height="300px" />
</a>

=end html

=head1 EXAMPLE3

 use strict;
 use warnings;

 use English;
 use Error::Pure qw(err);
 use GraphViz2;
 use Map::Tube::GraphViz;
 use Map::Tube::GraphViz::Utils qw(node_color_without_label);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 metro\n";
         exit 1;
 }
 my $metro = $ARGV[0];
 
 # Object.
 my $class = 'Map::Tube::'.$metro;
 eval "require $class;";
 if ($EVAL_ERROR) {
         err "Cannot load '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # Metro object.
 my $tube = eval "$class->new";
 if ($EVAL_ERROR) {
         err "Cannot create object for '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # GraphViz object.
 my $g = Map::Tube::GraphViz->new(
         'callback_node' => \&node_color_without_label,
         'g' => GraphViz2->new(
                 'global' => {
                         'directed' => 0,
                 },
                 'graph' => {
                         'label' => $metro,
                         'labelloc' => 'top',
                         'overlap' => 0,
                 },
         ),
         'tube' => $tube,
 );
 
 # Get graph to file.
 $g->graph($metro.'.png');

 # Print file.
 system "ls -l $metro.png";

 # Output without arguments like:
 # Usage: /tmp/SZXfa2g154 metro

 # Output with 'Berlin' argument like:
 # -rw-r--r-- 1 skim skim 1212857 Jan 27 07:51 Berlin.png

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex3.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex3.png" alt="Berlin" width="300px" height="300px" />
</a>

=end html

=head1 EXAMPLE4

 use strict;
 use warnings;

 use English;
 use Error::Pure qw(err);
 use Map::Tube::GraphViz;
 use Map::Tube::GraphViz::Utils qw(node_color_id);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 metro\n";
         exit 1;
 }
 my $metro = $ARGV[0];
 
 # Object.
 my $class = 'Map::Tube::'.$metro;
 eval "require $class;";
 if ($EVAL_ERROR) {
         err "Cannot load '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # Metro object.
 my $tube = eval "$class->new";
 if ($EVAL_ERROR) {
         err "Cannot create object for '$class' class.",
                 'Error', $EVAL_ERROR;
 }
 
 # GraphViz object.
 my $g = Map::Tube::GraphViz->new(
         'callback_node' => \&node_color_id,
         'tube' => $tube,
 );
 
 # Get graph to file.
 $g->graph($metro.'.png');

 # Print file.
 system "ls -l $metro.png";

 # Output without arguments like:
 # Usage: /tmp/SZXfa2g154 metro

 # Output with 'Berlin' argument like:
 # -rw-r--r-- 1 skim skim 1141071 Feb 24 08:04 Berlin.png

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex4.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-GraphViz/master/images/ex4.png" alt="Berlin" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<GraphViz2>,
L<List::MoreUtils>,
L<Map::Tube::GraphViz::Utils>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Map::Metro::Graph>

Map::Metro graph.

=item L<Task::Map::Tube>

Install the Map::Tube modules.

=item L<Task::Map::Tube::Metro>

Install the Map::Tube concrete metro modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Map-Tube-GraphViz>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 CONTRIBUTORS

=over

=item Gisbert W. Selke L<gws@cpan.org>

=back

=head1 LICENSE AND COPYRIGHT

© 2014-2020 Michal Josef Špaček

Artistic License

BSD 2-Clause License

=head1 VERSION

0.07

=cut
