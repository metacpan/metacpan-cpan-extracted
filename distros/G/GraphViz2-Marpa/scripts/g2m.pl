#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Getopt::Long;

use GraphViz2::Marpa;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'description=s',
	'help',
	'input_file=s',
	'maxlevel=s',
	'minlevel=s',
	'output_file=s',
	'renderer=s',
	'trace_terminals=i',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit GraphViz2::Marpa -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

g2m.pl - Run GraphViz2::Marpa.

=head1 SYNOPSIS

g2m.pl [options]

	Options:
	-description graphDescription
	-help
	-input_file aDotInputFileName
	-maxlevel logOption1
	-minlevel logOption2
	-output_file aRenderedDotInputFileName
	-renderer aGraphViz2::Marpa::Renderer::GraphViz2-compatible object
	-trace_terminals anInteger

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item -description graphDescription

Read the DOT-style graph definition from the command line.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the -input_file option to read the description from a file.

The -description option takes precedence over the -input_file option.

Default: ''.

=item -help

Print help and exit.

=item -input_file aDotInputFileName

Read the DOT-style graph definition from a file.

See also the -description option to read the graph definition from the command line.

The -description option takes precedence over the -input_file option.

Default: ''.

See the distro for data/*.gv.

=item -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

Default: 'notice'.

=item -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=item -output_file aRenderedDotInputFileName

Specify the name of a file for the renderer to write.

That is, write the DOT-style graph definition to a file.

When this file and the input file are both run thru 'dot', they should produce identical *.svg files.

If an output file name is specified, an object of type L<GraphViz2::Marpa::Renderer::GraphViz2> is
created and called after the input file has been successfully parsed.

Default: ''.

The default means the file is not written.

=item o -renderer => aGraphViz2::Marpa::Renderer::GraphViz2-compatible object

Specify a renderer for the parser to use.

See also C<output_file> just above.

Default: ''.

If an output file is specified, then an object of type L<GraphViz2::Marpa::Renderer::GraphViz2>
is created and its C<run()> method is called.

=item o -trace_terminals anInteger

See the trace level in Marpa::R2::Scanless::R.

Typical values: 0, 1, 99.

Default: 0 (No tracing).

=back

=cut
