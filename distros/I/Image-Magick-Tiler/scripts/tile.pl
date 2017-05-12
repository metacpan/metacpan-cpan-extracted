#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use Pod::Usage;

use Image::Magick::Tiler;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'input_file=s',
	'geometry=s',
	'output_dir=s',
	'output_type=s',
	'verbose=i',
	'write=i',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit Image::Magick::Tiler -> new(%option) -> tile;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

tile.pl - Use Image::Magick::Tiler to convert an image into NxM tiles

=head1 SYNOPSIS

tile.pl [options]

	Options:
	-help
	-input_file anImageFileName
	-geometry aString
	-output_dir aDirName
	-output_type anOutputImageType
	-verbose anInteger
	-write aBoolean

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item o help

Print help and exit.

=item o input_file anImageFileName

The name of the file to be chopped up.

This option is mandatory.

=item o geometry aString

The shape of the tiles to output.

Must be of the form '4x5+6-7', meaning 4 tiles across and 5 tiles down,
with the given offsets - 6, -7 - in pixels. See docs for details.

Default: '2x2+0+0'.

=item o output_dir aDirName

The name of the directory into which the tiles are written.

They will have names based on matrix co-ords, such as 1-1.png, 1-2.png, 2-1.png and 2-2.png.

Default: '/tmp'.

No lower levels are used.

=item o output_type anOutputImageType

The image type to use when creating the tile files.

Default: 'png'.

=item o verbose anInteger

Specify how many progress messages to write to STDOUT.

It takes the values 0, 1 and 2.

If 0, nothing is written. If 1, various statistics are written. If 2, you gets stats plus a line
about every tile written.

Default: 0.

=item o write aBoolean

Specify whether or not to write any tiles.

Default: 0.

=back

=cut
