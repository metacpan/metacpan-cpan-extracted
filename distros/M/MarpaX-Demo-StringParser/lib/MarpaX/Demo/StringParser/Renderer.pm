package MarpaX::Demo::StringParser::Renderer;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use GraphViz2;

use Log::Handler;

use Moo;

use Types::Standard qw/Any Int Str/;

has dot_input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has format =>
(
	default  => sub{return 'svg'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has graph =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has graphviz_tree =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has output_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has rankdir =>
(
	default  => sub{return 'TB'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has tree =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has uid =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '2.04';

# --------------------------------------------------

sub BUILD
{
	my($self) = @_;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				alias          => 'logger',
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
			}
		);
	}

} # End of BUILD.

# ------------------------------------------------

sub _add_anonymous_daughter
{
	my($self, $mother, $i) = @_;
	my($new_node) = $self -> _create_daughter('node_id', {});

	$new_node -> add_daughter($self -> _create_daughter('literal', {value => '{'}) );
	$new_node -> add_daughter($self -> _create_daughter('color',   {value => 'invis'}) );
	$new_node -> add_daughter($self -> _create_daughter('label',   {value => ''}) );
	$new_node -> add_daughter($self -> _create_daughter('shape',   {value => 'point'}) );
	$new_node -> add_daughter($self -> _create_daughter('width',   {value => 0}) );
	$new_node -> add_daughter($self -> _create_daughter('literal', {value => '}'}) );

	my(@daughters) = $mother -> daughters;

	splice(@daughters, $i, 0, $new_node);

	$mother ->  set_daughters(@daughters);

} # End of _add_anonymous_daughter.

# ------------------------------------------------

sub _bump_uid
{
	my($self) = @_;

	return $self -> uid($self -> uid + 1);

} # End of _bump_uid.

# ------------------------------------------------

sub _create_daughter
{
	my($self, $name, $attributes) = @_;
	$$attributes{uid}   = $self -> _bump_uid;
	$$attributes{value} = $self -> uid if (! defined $$attributes{value}); # Just for the node_id.

	return Tree::DAG_Node -> new({name => $name, attributes => $attributes});

} # End of _create_daughter.

# --------------------------------------------------

sub _determine_digraph_status
{
	my($self) = @_;

	my(@daughters) = $self -> tree -> daughters;
	my($index)     = 1; # 0 => prolog, 1 => graph.
	my($directed)  = 1;

	my($attributes);
	my($type);

	$daughters[$index] -> walk_down
	({
		callback => sub
		{
			my($node) = @_;
			$type     = $node -> name;

			return 1 if ($type ne 'edge_id');

			$attributes = $node -> attributes;
			$directed   = 0 if ($$attributes{value} eq '--');

			# Stop recursing.

			return 0;
		},
		_depth => 0,
	});

	return $directed;

} # End of _determine_digraph_status.

# --------------------------------------------------

sub _find_contiguous_edges
{
	my($self) = @_;

	# Graphviz won't accept a graphs with edges side-by-side, so ...
	# ... we walk the tree looking for such cases, and stash them.
	# Then we insert anonymous nodes between any such cases.
	# The Tree::DAG_Node docs warn against modifying the tree during a walk,
	# so we need to stash some information and process it later.

	my(@daughters) = $self -> tree -> daughters;
	my($index)     = 1; # 0 => prolog, 1 => graph.

	my($attributes);
	my($daughter_uid);
	my($i);
	my($name);
	my(@sisters, %seen, @stack);
	my($mother_uid);

	$daughters[$index] -> walk_down
	({
		callback => sub
		{
			my($node) = @_;

			# Skip the 'graph' node itself.

			return 1 if ($node -> mother -> is_root);

			# Skip everything but edges.

			$name = $node -> name;

			return 1 if ($name ne 'edge_id');

			# Only process 1 edge per mother, since this code covers all her daughters.

			$attributes = $node -> mother -> attributes;
			$mother_uid = $$attributes{uid};

			return 1 if ($seen{$mother_uid});

			$seen{$mother_uid} = 1;

			@sisters = $node -> self_and_sisters;

			for $i (1 .. $#sisters)
			{
				$name = $sisters[$i - 1] -> name;

				next if ($name ne 'edge_id');

				$name = $sisters[$i] -> name;

				next if ($name ne 'edge_id');

				push @stack, $node -> mother;

				last;
			}

			# Keep recursing.

			return 1;
		},
		_depth => 0,
	});

	my($added_anonymous_node);

	for my $node (@stack)
	{
		$added_anonymous_node = 1;

		while ($added_anonymous_node)
		{
			@daughters            = $node -> daughters;
			$added_anonymous_node = 0;

			for $i (1 .. $#daughters)
			{
				$name = $daughters[$i - 1] -> name;

				next if ($name ne 'edge_id');

				$name = $daughters[$i] -> name;

				next if ($name ne 'edge_id');

				$added_anonymous_node = 1;

				$self -> _add_anonymous_daughter($node, $i);

				last;
			}
		}
	}

} # End of _find_contiguous_edges.

# --------------------------------------------------

sub _find_first_edge
{
	my($self) = @_;

	# Graphviz won't accept a graph starting with an edge, so ...
	# ... we scan the daughters of the 'graph' node, looking for a node or an edge.
	# If the first thing we find is an edge, we output a dummy, invisible node before it.

	my(@daughters) = $self -> tree -> daughters;
	my($index)     = 1; # 0 => prolog, 1 => graph.

	my($first_edge);
	my($name);

	for my $daughter ($daughters[$index] -> daughters)
	{
		$name = $daughter -> name;

		# If there is a node before the first edge, we quit.

		last if ($name eq 'node_id');

		# There is no node before the first edge.
		# If there is an edge, remember it and quit.
		# If there is no no edge, just quit.

		$first_edge = $daughter if ($name eq 'edge_id');

		last;
	}

	if ($first_edge)
	{
		$self -> _add_anonymous_daughter($daughters[$index], 0);
	}

	return $daughters[$index];

} # End of _find_first_edge.

# --------------------------------------------------

sub _find_last_edge
{
	my($self) = @_;

	# Graphviz won't accept a graph ending with an edge, so ...
	# ... we examine the daughters of the 'graph' node, looking for an edge.
	# If the last thing we find is an edge, we output a dummy, invisible node after it.

	my(@daughters1) = $self -> tree -> daughters;
	my($index)     	= 1; # 0 => prolog, 1 => graph.
	my(@daughters2) = $daughters1[$index] -> daughters;

	if ( ($#daughters2 >= 0) && ($daughters2[$#daughters2] -> name eq 'edge_id') )
	{
		$self -> _add_anonymous_daughter($daughters1[$index], scalar @daughters2);
	}

} # End of _find_last_edge.

# --------------------------------------------------

sub _find_head_and_tail
{
	my($self, $node)     = @_;
	my($index)           = $node -> my_daughter_index;
	my(@daughters)       = $node -> mother -> daughters;
	my($from_attributes) = $daughters[$index - 1] -> attributes;
	my($to_attributes)   = $daughters[$index + 1] -> attributes;

	return ($$from_attributes{value}, $$to_attributes{value});

} # End of _find_head_and_tail.

# --------------------------------------------------

sub _initialize_uid
{
	my($self)     = @_;
	my($max_uid)  = 0;

	my($attributes);
	my($uid);

	$self -> tree -> walk_down
	({
		callback => sub
		{
			my($node) = @_;
			$attributes = $node -> attributes;
			$uid        = $$attributes{uid};
			$max_uid    = $uid if ($uid > $max_uid);

			# Keep recursing.

			return 1;
		},
		_depth => 0,
	});

	$self -> uid($max_uid);

} # End of _initialize_uid.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub output_all_edges
{
	my($self, $graph_subtree) = @_;

	$graph_subtree -> walk_down
	({
		callback => sub
		{
			my($node) = @_;

			# Skip the 'graph' node itself.

			return 1 if ($node -> mother -> is_root);

			$self -> output_node($node) if ($node -> name eq 'edge_id');

			# Keep recursing.

			return 1;
		},
		_depth => 0,
	});

} # End of output_all_edges.

# --------------------------------------------------

sub output_all_nodes
{
	my($self, $graph_subtree) = @_;

	my($attributes);
	my(%seen);
	my($type);
	my($uid);

	$graph_subtree -> walk_down
	({
		callback => sub
		{
			my($node) = @_;

			# Skip the 'graph' node itself.

			return 1 if ($node -> mother -> is_root);

			$type       = $node -> name;
			$attributes = $node -> attributes;
			$uid        = $$attributes{value};

			# Skip any node we've seen before.

			return 1 if ($type ne 'node_id');
			return 1 if ($seen{$uid});

			$seen{$uid} = 1;

			$self -> output_node($node);

			# Keep recursing.

			return 1;
		},
		_depth => 0,
	});

} # End of output_all_nodes.

# --------------------------------------------------

sub output_node
{
	my($self, $node) = @_;
	my($node_type)   = $node -> name;
	my($node_name)   = ${$node -> attributes}{value};

	# Accumulate all the attributes of the node's daughters.

	my($child_attributes, %node_attributes);
	my($child_name);

	for my $daughter ($node -> daughters)
	{
		$child_name = $daughter -> name;

		# Skip nodes called '{' and '}'.

		next if ($child_name eq 'literal');

		$child_attributes             = $daughter -> attributes;
		$node_attributes{$child_name} = $$child_attributes{value};
	}

	if ($node_type eq 'node_id')
	{
		$self -> graph -> add_node(name => $node_name, %node_attributes);
	}
	else
	{
		# Use the mother's daughters to get the nodes on either side of the edge.

		my($from_name, $to_name) = $self -> _find_head_and_tail($node);

		$self -> graph -> add_edge(from => $from_name, to => $to_name, %node_attributes);
	}

} # End of output_node.

# --------------------------------------------------

sub run
{
	my($self, %arg)     = @_;
	my($dot_input_file) = $arg{dot_input_file} || $self -> dot_input_file;
	my($format)         = $arg{format}         || $self -> format;
	my($output_file)    = $arg{output_file}    || $self -> output_file;
	my($graphviz_tree)  = $arg{graphviz_tree}  || $self -> graphviz_tree;
	my($rankdir)        = $arg{rankdir}        || $self -> rankdir;

	$self -> graph
	(
		GraphViz2 -> new
		(
			edge    => {color    => 'grey'},
			global  => {directed => $self -> _determine_digraph_status},
			graph   => {rankdir  => $rankdir},
			logger  => $self -> logger,
			node    => {shape => 'oval'},
			verbose => 0,
		)
	);
	$self -> _initialize_uid;

	my($graph_subtree) = $self -> _find_first_edge;

	$self -> _find_last_edge;
	$self -> _find_contiguous_edges;
	$self -> output_all_nodes($graph_subtree);
	$self -> output_all_edges($graph_subtree);

	# Save the dot input in case dot exits abnormally.
	# Note: We can't use $self -> graph -> dot_input()
	# until after $self -> graph -> run() is called.
	# So we use $self -> graph -> command -> print() instead.

	if ($dot_input_file)
	{
		open(my $fh, '>:encoding(utf-8)', $dot_input_file);
		print $fh (map{$_} @{$self -> graph -> command -> print}), "}\n";
		close $fh;
	}

	if ($graphviz_tree)
	{
		$self -> logger -> set_level(logger => {maxlevel => 'info'});
		$self -> log(info => join("\n", @{$self -> tree -> tree2string}) );
	}

	$self -> graph -> run(format => $format, output_file => $output_file);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<MarpaX::Demo::StringParser::Renderer> - The default rendering engine for MarpaX::Demo::StringParser

=head1 Synopsis

See L<MarpaX::Demo::StringParser/Synopsis>.

In particular, L<MarpaX::Demo::StringParser/DASH> describes DASH, the Graphviz-like graph
definition language supported by these modules.

See also scripts/render.pl and scripts/render.sh.

=head1 Description

This module is the default rendering engine for L<MarpaX::Demo::StringParser>.

It provides a L<GraphViz2>-based renderer for DASH, as parsed by L<MarpaX::Demo::StringParser>.

For more details, see L<MarpaX::Demo::StringParser/Description>.

=head1 Installation

Install L<MarpaX::Demo::StringParser> as you would for any C<Perl> module:

Run:

	cpanm MarpaX::Demo::StringParser

or run:

	sudo cpan MarpaX::Demo::StringParser

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = MarpaX::Demo::StringParser::Renderer -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Demo::StringParser::Renderer>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. maxlevel()]):

=over 4

=item o dot_input_file => $file_name

Specify the name of a file that the rendering engine can write to, which will contain the input
to dot (or whatever). This is good for debugging.

Default: ''.

If '', the file will not be created.

=item o format => $format

This is the format of the output file.

You can also pass this value into L</run(%arg)>.

The value passed in to run() takes precedence over the value passed in to new().

Default: 'svg'.

=item o graphviz_tree => $Boolean

Specify whether (1) or not (0) to display the tree of nodes after this module has inserted any
anonymous nodes necessary to keep Graphviz happy.

Default: 0.

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

Default: An object of type L<Log::Handler>.

=item o maxlevel => $level

This option is only used if this module creates an object of type L<Log::Handler>.

See L<Log::Handler::Levels>.

Default: 'notice'. A typical choice is 'info' or 'debug'.

=item o minlevel => $level

This option is only used if this module creates an object of type L<Log::Handler>.

See L<Log::Handler::Levels>.

Default:  'error'.

No lower levels are used.

=item o output_file => $file_name

Specify the name of the output file to write.

You can also pass this value into L</run(%arg)>.

The value passed in to run() takes precedence over the value passed in to new().

Default: ''.

=item o rankdir => $direction

$direction must be one of: LR or RL or TB or BT.

Specify the rankdir of the graph as a whole.

The value for I<rankdir> is passed to L<MarpaX::Demo::StringParser::Renderer>.

Default: 'TB'.

=back

=head1 Methods

=head2 dot_input_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file into which the rendering engine will write to input to dot (or whatever).

You can pass 'dot_input_file' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

'dot_input_file' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 format([$format])

Here, the [] indicate an optional parameter.

Get or set the format of the output file.

You can pass 'format' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

'format' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 graphviz_tree([$Boolean])

Here, the [] indicate an optional parameter.

Get or set whether or not to display the tree of nodes after this module has inserted any anonymous
nodes necessary to keep Graphviz happy.

You can pass 'graphviz_tree' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

'graphviz_tree' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 log($level, $s)

If a logger is defined, this logs the message $s at level $level.

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

You can pass 'logger' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

'logger' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if this module creates an object of type L<Log::Handler>.

See L<Log::Handler::Levels>.

'maxlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if this module creates an object of type L<Log::Handler>.

See L<Log::Handler::Levels>.

'minlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 output_all_edges($graph_subtree)

Walk the tree and output, via L</output_node($node)>, all edges and the nodes on either side of it.

=head2 output_all_nodes($graph_subtree)

Walk the tree and output, via L</output_node($node)>, all nodes.

=head2 output_node($node)

Convert, via L<GraphViz2>, the node into DOT format.

This is a tree node, not a DOT node.

=head2 output_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the output file.

You can pass 'output_file' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

'output_file' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 rankdir([$direction])

Here, the [] indicate an optional parameter.

Get or set the rankdir of the graph as a whole.

You can pass 'rankdir' as a key into new() and run().

The value passed in to run() takes precedence over the value passed in to new().

'rankdir' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 run(%arg)

Renders a set of items as an image, using L<GraphViz2>.

Keys and values in %arg are (see for L</Constructor and Initialization> details):

=over 4

=item o dot_output_file => $file_name

=item o format => $format

=item o graphtree_viz => $Boolean

=item o output_file => $file_name

=item o rankdir => $string

=back

=head1 FAQ

=head2 What is DASH?

See L<MarpaX::Demo::StringParser/DASH>.

This module does not use DASH. Rather, it interprets the tree of parsed nodes output by
L<MarpaX::Demo::StringParser>.

=head2 How is the parsed graph stored in RAM?

See L<MarpaX::Demo::StringParser/How is the parsed graph stored in RAM?>.

=head2 What are the defaults for GraphViz2?

	 GraphViz2 -> new
	 (
	 	edge    => {color => 'grey'},
	 	global  => {directed => $self -> _determine_digraph_status},
	 	graph   => {rankdir => $self -> rankdir},
	 	logger  => $self -> logger,
	 	node    => {shape => 'oval'},
	 	verbose => 0,
	 )

=head2 Why is _determine_digraph_status() undocumented?

It would never be overridden by a sub-class.

It determines if the output DOT file contains 'graph' or 'digraph', by examining the first edge in
the tree. '--' means 'graph' and '->' means 'digraph'.

Yes, I know I just documented it! It's an Easter Egg.

=head1 See also

L<Marpa::R2>, L<GraphViz2> and L<GraphViz2::Marpa>.

L<The Marpa homepage|http://savage.net.au/Marpa.html>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Demo::StringParser>.

=head1 Author

L<MarpaX::Demo::StringParser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
