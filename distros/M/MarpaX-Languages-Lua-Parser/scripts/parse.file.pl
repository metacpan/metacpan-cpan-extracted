#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Getopt::Long;

use MarpaX::Languages::Lua::Parser;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'attributes=i',
	'help',
	'input_file_name=s',
	'maxlevel=s',
	'minlevel=s',
	'output_file_name=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit MarpaX::Languages::Lua::Parser -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

parse.file.pl - Parsing any Lua source code file

=head1 SYNOPSIS

parser.file.pl [options]

	Options:
	-attributes Boolean
	-help
	-input_file_name aLuaFileName
	-maxlevel aString
	-minlevel aString
	-output_file_name aTextFileName

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -attributes Boolean

Specify whether or not to include tree node attributes when logging the tree output by
decoding the value returned by L<Marpa::R2::Scanless::R>.

Values:

=over 4

=item o 0

Do not include attributes.

=item o 1

Include attributes.

=back

Default: 0.

=item o -help

Print help and exit.

=item o -input_file_name aLuaFileName

The name of an Lua file to process.

See lua.sources/*.lua for some samples.

This option is mandatory.

Default: ''.

=item o -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

By default, nothing is printed. If you use $self -> log(debug => 'Finished') then
nothing will appear until you use new(maxlevel => 'debug'), or use -maxlevel debug
on the command line.

Default: 'notice'.

=item o -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=item o -output_file_name aTextFileName

The name of a text file to write, of parsed tokens.

By default, nothing is written.

See lua.output/*.txt for some samples.

Default: ''.

=back

=cut
