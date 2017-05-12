#!/usr/bin/env perl

use strict;
use warnings;

use MarpaX::Grammar::GraphViz2;

use Getopt::Long;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'format=s',
	'driver=s',
	'help',
	'legend=i',
	'logger=s',
	'marpa_bnf_file=s',
	'maxlevel=s',
	'minlevel=s',
	'output_file=s',
	'user_bnf_file=s',
	'verbose=i',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit MarpaX::Grammar::GraphViz2 -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

bnf2graph.pl - Convert a Marpa grammar into a image using GraphViz2.

=head1 SYNOPSIS

bnf2graph.pl [options]

	Options:
	-format imageFormat
	-driver aGraphvizDriverName
	-help
	-legend Boolean
	-logger aLog::HandlerObject
	-marpa_bnf_file aMarpaSLIF-DSLFileName
	-maxlevel logOption1
	-minlevel logOption2
	-output_file anImageFileName
	-user_bnf_file aUserSLIF-DSLFileName
	-verbose $Boolean

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item o -driver aGraphvizDriverName

The name of the Graphviz program to provide to L<GraphViz2>.

Default: 'dot'.

=item o -format imageFormat

Specify the type of image to be created.

Default: 'svg'.

=item o -help

Print help and exit.

=item o -legend Boolean

Add a legend (1) to the graph, or omit it (0).

Default: 0 (no legend).

=item o -logger aLog::HandlerObject

By default, an object is created which prints to STDOUT.

Set this to '' to stop logging.

Default: undef.

=item o -marpa_bnf_file aMarpaSLIF-DSLFileName

Specify the name of Marpa's own SLIF-DSL file.

This file ships with L<Marpa::R2>, in the meta/ directory. It's name is metag.bnf.

See share/metag.bnf.

This option is mandatory.

Default: ''.

=item o -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

Default: 'info'.

=item o -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=item o -output_file anImageFileName

Specify the name of a file for the driver to write.

If '', the file is not written.

Default: ''.

=item o -user_bnf_file aUserSLIF-DSLFileName

Specify the name of the file containing your Marpa::R2-style grammar.

See share/stringparser.bnf for a sample.

This option is mandatory.

Default: ''.

=item o -verbose $Boolean

Display more or less during debugging.

Default: 0.

=back

=cut
