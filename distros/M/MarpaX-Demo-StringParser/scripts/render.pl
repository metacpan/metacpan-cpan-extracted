#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use MarpaX::Demo::StringParser;
use MarpaX::Demo::StringParser::Renderer;

use Getopt::Long;

use Pod::Usage;

use Try::Tiny;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'description=s',
	'dot_input_file=s',
	'format=s',
	'graphviz_tree=i',
	'help',
	'input_file=s',
	'maxlevel=s',
	'minlevel=s',
	'output_file=s',
	'rankdir=s',
) )
{
	pod2usage(1) if ($option{'help'});

	my(%render_opts);

	$render_opts{dot_input_file} = delete $option{dot_input_file} || '';
	$render_opts{output_file}    = delete $option{output_file}    || '';
	$render_opts{rankdir}        = delete $option{rankdir}        || 'TB';
	$render_opts{graphviz_tree}  = delete $option{graphviz_tree}  || 0;

	# Return 0 for success and 1 for failure.

	my($parser) = MarpaX::Demo::StringParser -> new(%option);
	my($exit)   = $parser -> run;

	if ($exit == 0)
	{
		$render_opts{logger} = $parser -> logger;
		$render_opts{tree}   = $parser -> tree;

		try
		{
			$exit = MarpaX::Demo::StringParser::Renderer -> new(%render_opts) -> run;
		}
		catch
		{
			$exit = 1;

			print "dot died: $_. \n";
		}
	}

	exit $exit;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

render.pl - Run MarpaX::Demo::StringParser::Renderer.

=head1 SYNOPSIS

This program calls MarpaX::Demo::StringParser to parse the DASH file (-description or
-input_file), and then calls MarpaX::Demo::StringParser::Renderer to render the parsed
tokens into an image (-output_file).

render.pl [options]

	Options:
	-description DASHText
	-dot_input_file outFileToBeInputToDot
	-format imageFormat
	-graphviz_tree Boolean
	-help
	-input_file aDASHFileName
	-maxlevel logOption1
	-minlevel logOption2
	-output_file anOutputImageFile
	-rankdir aGraphvizDirection

Exit value: 0 for success, 1 for failure. Die upon error.

Typical usage:

	scripts/render.pl -de '[n]{color:blue; label: "Big N"}' -o x.svg
	scripts/render.pl -i x.dash -max info -o x.svg

You can use scripts/render.sh to simplify this process, but it assumes you're input file is in data/
and your output DOT file is going to data/, and your output SVG (whatever) file is going to html/:

	scripts/render.sh node.04

=head1 OPTIONS

=over 4

=item o -description DASHText

Specify a graph description string to parse.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the -input_file option to read the description from a file.

The -description option takes precedence over the -input_file option.

Default: ''.

=item o -dot_input_file outFileToBeInputToDot

Specify the name of the DOT file to write before the graph is passed to the renderer

See also output_file.

If '', no DOT file will be written.

Default: ''.

=item o -format imageFormat

Specify the type of image to be created.

This value is passed to GraphViz2 and then to dot.

See also output_file.

Default: 'svg'.

=item o -graphviz_tree Boolean

Specify whether (1) or not (0) to display the tree just before it's DOT version is passed
to GraphViz2.

This matters because the renderer may have to fabricate nodes in the tree because the DASH
language allows juxtaposed edges, and Graphviz does not. In these cases, the renderer separates
the edges with an anonymous node.

Likewise, Graphviz does not allow a graph to start or end with an edge. Here, the renderer
also fabricates anonymous nodes to keep it happy.

The setting of maxlevel affects this. By default, maxlevel is notice, so nothing is printed.
See both '-graphviz_tree 1' and '-maxlevel info' to get this augmented tree.

Default: 0 (Do not display).

=item o -help

Print help and exit.

=item o -input_file aDASHFileName

Read the graph description string from a file.

See also the -description option to read the graph description from the command line.

The whole file is slurped in as 1 graph.

Lines of the file can start with m!^(?:#|//)!, and will be discarded as comments.

The -description option takes precedence over the -input_file option.

Default: ''.

=item o -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

Default: 'notice'.

=item o -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=item o -output_file anOutputImageFile

The name of an SVG (or PNG ...) file to be written by L<GraphViz2>.

See also format.

If '', no image file will be written.

Default: ''.

=item o -rankdir aGraphvizDirection

Specify the string to pass to L<GraphViz2> and hence to Graphviz.

Typical values are 'TB' (Top-to-Bottom), 'LR' (Left-to-Right), etc.

This is needed becase the DASH language currently has no such feature.

Default: TB.

=back

=cut
