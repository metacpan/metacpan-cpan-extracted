#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use GraphViz2::Marpa::PathUtils;

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
	'report_clusters=i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit GraphViz2::Marpa::PathUtils -> new(%option) -> find_clusters;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

find.clusters.pl - Run GraphViz2::Marpa::PathUtils.

=head1 SYNOPSIS

find.clusters.pl [options]

	Options:
	-description graphDescription
	-help
	-input_file aDOTInputFileName
	-maxlevel logOption1
	-minlevel logOption2
	-output_file aDOTInputFileNamePrefix
	-report_clusters $Boolean

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item o -description graphDescription

Read the DOT-style graph definition from the command line.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the -input_file option to read the description from a file.

The -description option takes precedence over the -input_file option.

Default: ''.

=item o -help

Print help and exit.

=item o -input_file aDotInputFileName

Read the DOT-style graph definition from a file.

See also the -description option to read the graph definition from the command line.

The -description option takes precedence over the -input_file option.

Default: ''.

See the distro for data/*.gv.

=item o -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

Default: 'notice'.

=item o -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=item o -output_file aDOTInputFileNamePrefix

Specify the prefix of the DOT files to write for each cluster found.

The prefix has ".$n.gv" attached as a suffix, for clusters 1 .. N.

Default: ''.

The default means the files are not written.

=item o -report_clusters $Boolean

Log the clusters detected.

Default: 0.

=back

=cut
