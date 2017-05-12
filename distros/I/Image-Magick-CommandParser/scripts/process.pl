#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Getopt::Long;

use Image::Magick::CommandParser;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'command=s',
	'help',
	'logger=s',
	'maxlevel=s',
	'minlevel=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Image::Magick::CommandParser -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

process.pl - Test Image::Magick::CommandParser

=head1 SYNOPSIS

process.pl [options]

	Options:
	-command aString
	-help
	-logger aString
	-maxlevel aString
	-minlevel aString

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -command aString

Specify the command to process as a string.

This option is mandatory.

Default: ''.

=item o -help

Print help and exit.

=item o -logger aString

Specify the empty string to disable logging.

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
