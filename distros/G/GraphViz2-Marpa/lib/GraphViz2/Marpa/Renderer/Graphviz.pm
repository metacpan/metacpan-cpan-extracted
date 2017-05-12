package GraphViz2::Marpa::Renderer::Graphviz;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Log::Handler;

use Moo;

use Types::Standard qw/Any Str/;

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'info'},
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

has tree =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 1,
);


our $VERSION = '2.11';

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
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
			}
		);
	}

} # End of BUILD.

# --------------------------------------------------

sub format_node
{
	my($self, $node, $opts) = @_;
	my($name)        = $node -> name;
	my($attributes)  = $node -> attributes;
	my($attr_string) = $self -> tree -> hashref2string($attributes);
	my($type)        = $$attributes{type} || '';
	my($value)       = defined($$attributes{value}) ? $$attributes{value} : ''; # Allow for node '0'.
	my($dot_input)   = $$opts{previous}{dot_input};
	my($depth)       = $$opts{_depth};
	my(%ignore)      = (graph => 1, prolog => 1, root => 1);
	my($message)     = "name: $name. type: $type. value: $value. depth: $depth\n";

	my($indent);
	my($offset);

	$self -> log(debug => "Rendering. $message");

	if ($name eq 'attribute')
	{
		$$opts{previous}{attribute_count}++;

		$value = qq("$value") if ( ($value !~ /^<.+>$/s) && ($value !~ /^".*"/) );

		# Separate nodes and graph attrs.

		if ($$opts{previous}{name} eq 'node_id')
		{
			$dot_input .= "\n";
		}

		if ($$opts{previous}{value} eq '[')
		{
			$indent = '';
		}
		elsif ($$opts{previous}{name} eq 'attribute')
		{
			$indent = ' ';
		}
		else
		{
			$indent = "\t" x ($depth - 2);
		}

		$dot_input .= "$indent$type = $value";
	}
	elsif ($name eq 'class')
	{
		$indent    = "\t" x ($depth - 2);
		$dot_input .= "\n"   if ($$opts{previous}{name} eq 'node_id');             # Separate classes and nodes.
		$dot_input .= "\n\n" if ($$opts{previous}{name} =~ /(?:attribute|class)/); # Separate classes and attrs.
		$dot_input .= "$indent$value";
	}
	elsif ($name eq 'edge_id')
	{
		$dot_input .= " $value";
	}
	elsif ($name eq 'literal')
	{
		$dot_input .= "\n" if ($value =~ /[{}]/);

		if ($value =~ /[{}]/)
		{
			$indent    = "\t" x ($depth - 2);
			$indent    .= "\n$indent" if ($$opts{previous}{name} eq 'edge_id'); # Separate edge from subgraph.
			$dot_input .= "$indent$value\n";
		}
		elsif ($value =~ /[\[\]]/)
		{
			$$opts{previous}{attribute_count} = 0 if ($value eq '[');

			$indent    = '';
			$dot_input .= "$indent$value";
			$dot_input .= "\n" if ($value eq ']'); # Separate attrs and other things.
		}
		elsif ($type =~ /^(?:digraph|graph|strict)_literal$/) # Must match 'graph' but not 'subgraph'!
		{
			$dot_input .= "$value ";
		}
		elsif ($type eq 'subgraph_literal')
		{
			$indent    = "\t" x ($depth - 2);
			$dot_input .= "\n" if ($$opts{previous}{name} eq 'attribute');
			$dot_input .= "\n$indent$value ";
		}
		else
		{
			die "Rendering error: Unknown literal. $message";
		}
	}
	elsif ($name =~ /(?:graph_id|node_id)/)
	{
		$indent    = "\t" x ($depth - 2);
		$dot_input .= "\n" if ($$opts{previous}{name} =~ /(?:attribute|class)/); # Separate classes and attrs.

		if ($$opts{previous}{name} eq 'edge_id')
		{
			$indent = ' '; # Don't separate nodes and edges.
		}
		elsif ($$opts{previous}{type} =~ /(?:digraph|graph)_literal/)
		{
			$indent = ''; # Don't separate nodes and 'digraph' or 'graph'.
		}
		elsif ($$opts{previous}{name} ne 'literal')
		{
			$indent = "\n$indent";
		}

		$dot_input .= "$indent$value";
	}
	elsif ($name eq 'subgraph_id')
	{
		$dot_input .= " $value";
	}
	elsif (! $ignore{$name})
	{
		die "Rendering error: Unknown name. $message";
	}

	$$opts{previous}{dot_input} = $dot_input;
	$$opts{previous}{name}      = $name;
	$$opts{previous}{type}      = $type;
	$$opts{previous}{value}     = $value;

} # End of format_node.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> $level($s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub run
{
	my($self)     = @_;
	my($previous) =
	{
		attribute_count => 0,
		dot_input       => '',
		name            => '',
		type            => '',
		value           => '',
	};

	$self -> tree -> walk_down
	({
		callback => sub
		{
			my($node, $opts) = @_;

			# Note: This $node is a Tree::DAG_Node node, not a Graphviz node.

			$self -> format_node($node, $opts);

			# Keep recursing.

			return 1;
		},
		_depth   => 0,
		previous => $previous,
	});

	my($output_file) = $self -> output_file;

	if ($output_file)
	{
		open(my $fh, '> :encoding(utf-8)', $output_file) || die "Can't open(> $output_file): $!";
		print $fh $$previous{dot_input};
		close $fh;

		$self -> log(info => "Rendered file: $output_file");
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# --------------------------------------------------

1;

=pod

=head1 NAME

C<GraphViz2::Marpa::Renderer::Graphviz> - A renderer for L<GraphViz2::Marpa>-style C<dot> files

=head1 Synopsis

See L<GraphViz2::Marpa/Synopsis>.

=head1 Description

L<GraphViz2::Marpa::Renderer::Graphviz> provides a renderer for L<Graphviz|http://www.graphviz.org/> (dot) graph definitions
parsed by L<GraphViz2::Marpa>.

It outputs a string to the output file, which (ideally) exactly matches the graph definition input to the paser,
although there might be small differences in the line-by-line formatting.

This module is the default rendering engine for L<GraphViz2::Marpa>.

=head1 Installation

Install L<GraphViz2::Marpa> as you would for any C<Perl> module:

Run:

	cpanm GraphViz2::Marpa

or run:

	sudo cpan GraphViz2::Marpa

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

C<new()> is called as C<< my($renderer) = GraphViz2::Marpa::Renderer::Graphviz -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Marpa::Renderer::Graphviz>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. maxlevel()]):

=over 4

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

Default: An object of type L<Log::Handler>.

=item o maxlevel => $level

This option is only used if this module creates an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

Default: 'notice'.

=item o minlevel => $level

This option is only used if this module creates an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

Default: 'error'.

No lower levels are used.

=item o output_file => $file_name

Specify the name of the output file to write. This will contain the text string of the rendered graph.

Default: ''.

The default means the output file is not written. Use the L</output_string()> method to retrieve the string.

=item o tree => anObjectOfTypeTreeDAG_Node

Specify the tree tokens output by the parser.

This option is mandatory.

The tree is output from L<GraphViz2::Marpa>.

Default: ''.

=back

=head1 Methods

=head2 format_node($node, $opts)

$node is an object of type L<Tree::DAG_Node>.

$opts is the same hashref of options as passed in to the call to C<walk_down()> in C<run()>.

C<format_node()> is called to generate a string representation of $node, using $opts.

Examine the default implementation of C<format_node()>, above, for more details.

=head2 log($level, $s)

Calls $self -> logger -> $level($s) if ($self -> logger).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set 'logger' to the empty string (not undef), in the call to L</new()>.

'logger' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if L<GraphViz2::Marpa:::Lexer> or L<GraphViz2::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

'maxlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if L<GraphViz2::Marpa:::Lexer> or L<GraphViz2::Marpa::Parser>
create an object of type L<Log::Handler>. See L<Log::Handler::Levels>.

'minlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 output_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the output file. This will contain the text string of the rendered graph.

If the output file name is not set, use the L</output_string()> method to retrieve the string.

'output_file' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 run()

Renders the tree of parsed tokens as a string and, optionally, writes that string to the output file.

Returns 0 for success and 1 for failure.

=head2 tree()

Gets or sets the tree of tokens to be rendered.

'tree' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head1 FAQ

See L<GraphViz2::Marpa/FAQ>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/GraphViz2-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2::Marpa>.

=head1 Author

L<GraphViz2::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
