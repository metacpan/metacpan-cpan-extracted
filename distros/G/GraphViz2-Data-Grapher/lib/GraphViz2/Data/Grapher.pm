package GraphViz2::Data::Grapher;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '2.51';

use GraphViz2;
use Moo;
use Scalar::Util qw(blessed reftype);
use Tree::DAG_Node;

has graph =>
(
	default  => sub {
		GraphViz2->new(
			edge   => {color => 'grey'},
			global => {directed => 1},
			graph  => {rankdir => 'TB'},
			node   => {color => 'blue', shape => 'oval'},
		)
        },
	is       => 'rw',
	#isa     => 'GraphViz2',
	required => 0,
);

has tree =>
(
	is       => 'rw',
	#isa     => 'Tree::DAG_Node',
	required => 0,
);

# -----------------------------------------------
# This is a function.

sub address
{
	my($address) = @_;
	$address =~ tr/[:.]/_/;

	return $address;

} # End of address;

sub build_graph {
	my ($graph, $tree, $from) = @_;
	return unless my @child = $tree->daughters;
	my @label = map $_->name, @child;
	my $name = address($tree->address) . '_kids';
	my $to = "$name:port" . (int($#child / 2) + 1);
	my $one_ref = (@child == 1) && ($child[0]->name =~ /^(?:\&CODE|\$REF)/);
	if ($one_ref) {
		$to = $label[0];
		$graph->add_node(
			name => $to,
			color => 'grey', fontcolor => 'red',
			shape => 'oval',
		);
	} else {
		$graph->add_node(
			name => $name, label => \@label,
			color => 'grey', fontcolor => 'blue',
			shape => $graph->global->{record_shape},
		);
	}
	# Add an edge from the parent to the middle of the child list.
	$graph->add_edge(from => $from, to => $to);
	# Recurse to handle the grandkids.
	my $port = 0;
	build_graph($graph, $_, ($one_ref ? $to : "$name:port".++$port)) for @child;
}

# gives stable sequential ID number for references
my %ref2id;
my $ref_counter = 0;
sub _gen_id {
  my ($ref) = @_;
  return $ref2id{$ref} if $ref2id{$ref};
  $ref2id{$ref} = ref($ref) . ++$ref_counter;
}

sub build_tree {
	my ($name, $item) = @_;
	my $current = Tree::DAG_Node->new;
	if (defined(my $ref = reftype $item)) {
		if (my $blessed = blessed $item) {
			$current->new_daughter({name => $blessed});
			$current->name($blessed);
		}
		elsif ($ref =~ /^ARRAY/)
		{
			$current->name('@$' . $name);

			$current->add_daughter(build_tree(_gen_id($item), $_)) for @$item;
		}
		elsif ($ref =~ /^CODE/)
		{
			$current->new_daughter({name => '&' . _gen_id $item});
			$current->name('$' . $name);
		}
		elsif ($ref =~ /^HASH/)
		{
			$current->name('%$' . $name);
			for my $key (sort keys %$item)
			{
				$current->add_daughter(my $d = build_tree($key, $key));
				$d->add_daughter(build_tree($key, $$item{$key}));
			}
		}
		elsif ($ref =~ /^SCALAR/)
		{
			$current->name("\$ " . _gen_id($item) . " - Not used");
		}
		else
		{
			$current->name("Object: $name");
			$current->add_daughter(build_tree(_gen_id($item), $$item));
		}
	}
	else
	{
		$current->name($item);
	}
	$current;
}

# -----------------------------------------------

sub create
{
	my($self, %arg) = @_;
	$self->tree(build_tree($arg{name} => $arg{thing}));
	my $a2 = address(my $a1 = $self->tree->address);
	$self->graph->add_node(color => 'green', name => $a2, label => $self->tree->name, shape => 'doubleoctagon');
	build_graph($self->graph, $self->tree, $a2);
	return $self;
}

1;

=pod

=head1 NAME

L<GraphViz2::Data::Grapher> - Visualize a data structure as a graph

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use GraphViz2;
	use GraphViz2::Data::Grapher;

	my($sub) = sub{};
	my($s)   =
	{
		A =>
		{
			a =>
			{
			},
			bbbbbb => $sub,
			c123   => $sub,
			d      => \$sub,
		},
		C =>
		{
			b =>
			{
				a =>
				{
					a =>
					{
					},
					b => sub{},
					c => 42,
				},
			},
		},
		els => [qw(element_1 element_2 element_3)],
	};

	my($graph) = GraphViz2 -> new
		(
		 edge   => {color => 'grey'},
		 global => {directed => 1},
		 graph  => {rankdir => 'TB'},
		 node   => {color => 'blue', shape => 'oval'},
		);

	my($g)           = GraphViz2::Data::Grapher->new(graph => $graph);
	my($format)      = shift || 'svg';
	my($output_file) = shift || File::Spec -> catfile('html', "parse.data.$format");

	$g -> create(name => 's', thing => $s);
	$graph -> run(format => $format, output_file => $output_file);

	# If you did not provide a GraphViz2 object, do this
	# to get access to the auto-created GraphViz2 object.

	#$g -> create(name => 's', thing => $s);
	#$g -> graph -> run(format => $format, output_file => $output_file);

	# Or even

	#$g -> create(name => 's', thing => $s)
	#-> graph
	#-> run(format => $format, output_file => $output_file);

See scripts/parse.data.pl (L<GraphViz2/Scripts Shipped with this Module>).

=head1 Description

Takes a Perl data structure and recursively converts it into L<Tree::DAG_Node> object, and then graphs it.

You can write the result in any format supported by L<Graphviz|http://www.graphviz.org/>.

Here is the list of L<output formats|http://www.graphviz.org/content/output-formats>.

Within the graph:

=over 4

=item o Array names are preceeded by '@'

=item o Code references are preceeded by '&'

=item o Hash names are preceeded by '%'

=item o Scalar names are preceeded by '$'

=back

Hence, a hash ref will look like '%$h'.

Further, objects of different type have different shapes.

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2::Data::Grapher -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Data::Grapher>.

Key-value pairs accepted in the parameter list:

=over 4

=item o graph => $graphviz_object

This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
except for the graph label of course.

This key is optional.

=back

=head1 Methods

=head2 create(name => $name, thing => $thing)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self to allow method chaining.

$name is the string which will be placed in the root node of the tree.

If $s = {...}, say, use 's', not '$s', because '%$' will be prefixed automatically to the name,
because $s is a hashref.

$thing is the data stucture to graph.

=head2 graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

=head2 tree()

Returns the tree object (of type L<Tree::DAG_Node>) built before it is traversed to generate the nodes and edges.

=head1 Scripts Shipped with this Module

=head2 scripts/parse.data.pl

Demonstrates graphing a Perl data structure.

Outputs to ./html/parse.data.svg by default.

=head2 scripts/parse.html.pl

Demonstrates using L<XML::Bare> to parse HTML.

Inputs from ./t/sample.html, and outputs to ./html/parse.html.svg by default.

=head2 scripts/parse.xml.bare.pl

Demonstrates using L<XML::Bare> to parse XML.

Inputs from ./t/sample.xml, and outputs to ./html/parse.xml.bare.svg by default.

=head1 Thanks

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 Author

L<GraphViz2> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
