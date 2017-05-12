package Image::Magick::PolyText::FreeType;

use parent 'Image::Magick::PolyText';
use strict;
use warnings;

use File::Temp;

use Font::FreeType;

use Image::Magick;

use Moo;

use POSIX 'ceil';

our $VERSION = '2.00';

# ------------------------------------------------
# Constants.

Readonly::Scalar my $pi => 3.14159265;

# ------------------------------------------------
# Methods.

sub annotate
{
	my($self)	= @_;
	my($font)	= $self -> image -> Get('font');
	my($face)	= Font::FreeType -> new ->face($font, load_flags => FT_LOAD_NO_HINTING);

	$face -> set_char_size($self -> pointsize, 0, 72, 72);

	$self -> dump if ($self -> debug);

	my $bitmap;
	my $i;
	my $result;
	my $rotation;
	my @text = split //, $self -> text;
	my @value;
	my $x = ${$self -> x}[0];
	my $y;

	if ($self -> slide)
	{
		my $b    = Math::Bezier -> new(map{(${$self -> x}[$_], ${$self -> y}[$_])} 0 .. $#{$self -> x});
		($x, $y) = $b -> point($self -> slide);
	}

	for ($i = 0; $i <= $#text; $i++)
	{
		@value    = Math::Interpolate::robust_interpolate($x, $self -> x, $self -> y);
		$rotation = $self -> rotate ? 180 * $value[1] / $pi : 0; # Convert radians to degrees.
		$y        = $value[0];
		$result   = $self -> image -> Composite
		(
		compose => 'Over',
		image   => $self -> glyph2svg2bitmap($face, $text[$i], $rotation),
		x       => $x,
		'y'     => $y, # y eq tr, so syntax highlighting stuffed without ''.
		);

		die $result if $result;

		$x += $self -> pointsize;
	}

}	# End of annotate.

# ------------------------------------------------

sub glyph2svg2bitmap
{
	my($self, $face, $char, $rotation)	= @_;
	my($glyph)							= $face -> glyph_from_char_code(ord $char);

	if (! (defined $glyph && $glyph -> has_outline() ) )
	{
		$glyph = $face -> glyph_from_char_code('?');
	}

	my($xmin, $ymin, $xmax, $ymax) = $glyph -> outline_bbox;
	$xmax    = ceil $xmax;
	$ymax    = ceil $ymax;
	my $path = $glyph -> svg_path;
	my $fh   = File::Temp -> new;

	print $fh
	"<?xml version='1.0' encoding='UTF-8'?>\n" .
    "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\"\n" .
    "    \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n\n" .
    "<svg xmlns='http://www.w3.org/2000/svg' version='1.0'\n" .
    "     width='$xmax' height='$ymax'>\n\n" .
    # Transformation to flip it upside down and move it back down into
    # the viewport.
    " <g transform='scale(1 -1) translate(0 -$ymax)'>\n" .
    " <path d='$path'\n" .
    " style='fill: #77FFCC; stroke: #000000'/>\n\n" .
    " </g>\n",
    "</svg>\n";
	close $fh;

	my $bitmap = Image::Magick -> new;
	my $result  = $bitmap -> Read($fh -> filename() );

	die $result if $result;

	# We have to set the background to none so when the bitmap is rotated,
	# the areas filled in where the glyph is moved from are left as white.

	$result = $bitmap -> Set(background => 'None');

	die $result if $result;

	# We set white as transparent so this bitmap has no background, so that
	# when it's overlayed on the original image, only the glyph is visible.

	$result = $bitmap -> Transparent(color => 'White');

	die $result if $result;

	$result = $bitmap -> Rotate($rotation);

	die $result if $result;

	return $bitmap;

}	# End of glyph2svg2bitmap.

# ------------------------------------------------

1;

=head1 NAME

C<Image::Magick::PolyText::FreeType> - Draw text along a polyline using FreeType and Image::Magick

=head1 Synopsis

	my $polytext = Image::Magick::PolyText::FreeType -> new
	({
		debug        => 0,
		fill         => 'Red',
		image        => $image,
		pointsize    => 16,
		rotate       => 1,
		slide        => 0.1,
		stroke       => 'Red',
		strokewidth  => 1,
		text         => 'Draw.text.along.a.polyline', # Can't use spaces!
		x            => [0, 1, 2, 3, 4],
		y            => [0, 1, 2, 3, 4],
	});

	$polytext -> annotate;

Warning: Experimental code - Do not use.

=head1 Description

C<Image::Magick::PolyText::FreeType> is a pure Perl module.

It is a convenient wrapper around the C<Image::Magick Annotate()> method, for drawing text along a polyline.

Warning: Experimental code - Do not use.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

Warning: Experimental code - Do not use.

new(...) returns an C<Image::Magick::PolyText::FreeType> object.

This is the class contructor.

Usage: Image::Magick::PolyText::FreeType -> new({...}).

This method takes a hashref of parameters.

For each parameter you wish to use, call new as new({param_1 => value_1, ...}).

=over 4

=item o debug

Takes either 0 or 1 as its value.

The default value is 0.

When set to 1, the module writes to STDOUT, and plots various stuff on your image.

This parameter is optional.

=item o fill

Takes an C<Image::Magick> color as its value.

The default value is 'Red'.

The value is passed to the C<Image::Magick Annotate()> method.

This parameter is optional.

=item o image

Takes an C<Image::Magick> object as its value.

There is no default value.

This parameter is mandatory.

=item vpointsize

Takes an integer as its value.

The default value is 16.

The value is passed to the C<Image::Magick Annotate()> method.

This parameter is optional.

=item vrotate

Takes either 0 or 1 as its value.

The default value is 1.

When set to 0, the module does not rotate any characters in the text.

When set to 1, the module rotates each character in the text to match the tangent of the polyline
at the 'current' (x, y) position.

This parameter is optional.

=item o slide

Takes a real number in the range 0.0 to 1.0 as its value.

The default value is 0.0.

The value represents how far along the polyline (0.0 = 0%, 1.0 = 100%) to slide the first character of the text.

The parameter is optional.

=item o stroke

Takes an C<Image::Magick> color as its value.

The default value is 'Red'.

The value is passed to the C<Image::Magick Annotate()> method.

This parameter is optional.

=item o strokewidth

Takes an integer as its value.

The default value is 1.

The value is passed to the C<Image::Magick Annotate()> method.

This parameter is optional.

=item o text

Takes a string of characters as its value.

There is no default value.

This text is split character by character, and each character is drawn with a separate call to
the C<Image::Magick Annotate()> method. This is a very slow process. You have been warned.

This parameter is mandatory.

=item o x

Takes an array ref of x (co-ordinate) values as its value.

There is no default value.

These co-ordinates are the x-axis values of the polyline.

This parameter is mandatory.

=item o y

Takes an array ref of y (abcissa) values as its value.

There is no default value.

These abcissa are the y-axis values of the polyline.

This parameter is mandatory.

=back

=head1

=head2 annotate()

This method writes the text on to your image.

=head2 draw(%options)

%options is an optional hash of (key => value) pairs.

This method draws a line through the data points.

The default line color is green.

The options are a hash ref which is passed to the C<Image::Magick Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> draw({stroke => 'blue'});

=head2 highlight_data_points(%options)

%options is an optional hash of (key => value) pairs.

This method draws little (5x5 pixel) rectangles centered on the data points.

The default rectangle color is red.

The options are a hash ref which is passed to the C<Image::Magick Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> highlight_data_points({stroke => 'black'});

=head1 Example code

See the file examples/ptf.pl in the distro.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Image-Magick-PolyText>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-Magick-PolyText>.

=head1 Author

C<Image::Magick::PolyText::FreeType> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2007.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2007, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
