#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use MarpaX::Languages::SVG::Parser;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'attribute=s',
	'encoding=s',
	'help',
	'input_file_name=s',
	'maxlevel=s',
	'minlevel=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit MarpaX::Languages::SVG::Parser -> new(%option) -> test;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

test.file.pl - Test parsing of some SVG path/attribute combinations

=head1 SYNOPSIS

test.file.pl [options]

	Options:
	-attribute aString
	-encoding aString
	-help
	-input_file_name aDataFileName
	-maxlevel aString
	-minlevel aString

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -attribute aString

Specifies the name of the attribute (and hence of the BNF) to process:

=over 4

=item o d

This is for a path's 'd' attribute.

=item o points

Use this for a polygon's and a polyline's points.

=item o preserveAspectRatio

Various tags can have a 'preserveAspectRatio' attribute.

=item o transform

Various tags can have a 'transform' attribute.

=item o viewBox

Various tags can have a 'viewBox' attribute.

=back

This option is mandatory.

Default: 'd'.

=item o -encoding aString

aString takes values such as 'utf-8', and the code converts this into '<:encoding(utf-8)'.

This option is rarely needed.

Default: ''.

=item o -help

Print help and exit.

=item o -input_file_name aDataFileName

The name of the file to process.

See data/*.dat for many samples.

This option is mandatory.

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
