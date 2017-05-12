#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use MarpaX::Demo::StringParser;

use Getopt::Long;

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
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit MarpaX::Demo::StringParser -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

parse.pl - Run MarpaX::Demo::StringParser::Parser.

=head1 SYNOPSIS

This program calls MarpaX::Demo::StringParser to parse the DASH file (-description or
-input_file), and optionally displays the parsed tokens as a tree.

Note: Nothing is printed by default. Hence the use of '-max info' below.

parse.pl [options]

	Options:
	-description DASHText
	-help
	-input_file aDASHFileName
	-maxlevel logOption1
	-minlevel logOption2

Exit value: 0 for success, 1 for failure. Die upon error.

Typical usage:

	perl -Ilib scripts/parse.pl -de '[node]{color:blue; label: "Node name"}' -max info

You can use scripts/parse.sh to simplify this process, but it assumes you're input file is in data/:

	scripts/parse.sh node.04 -max info

=head1 OPTIONS

=over 4

=item o -description DASHText

Specify a graph description string to parse.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the -input_file option to read the description from a file.

The -description option takes precedence over the -input_file option.

Default: ''.

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

=back

=cut
