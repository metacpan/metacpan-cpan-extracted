package Image::Magick::PolyText;

use strict;
use warnings;

use Math::Bezier;
use Math::Interpolate;

use Moo;

use Readonly;

use Types::Standard qw/Any ArrayRef Bool Int Num Str/;

has debug =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

has fill =>
(
	default  => sub{return 'Red'},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has image =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 1,
);

has pointsize =>
(
	default  => sub{return 16},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has rotate =>
(
	default  => sub{return 1},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

has slide =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Num,
	required => 0,
);

has stroke =>
(
	default  => sub{return 'Red'},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has strokewidth =>
(
	default  => sub{return 1},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has text =>
(
	default  => sub{return 'text'},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has x =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 1,
);

has y =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 1,
);

our $VERSION = '2.00';

# ------------------------------------------------
# Constants.

Readonly::Scalar my $pi => 3.14159265;

# ------------------------------------------------
# Methods.

sub annotate
{
	my($self) = @_;

	$self -> dump if ($self -> debug);

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
		$result   = $self -> image -> Annotate
		(
			fill        => $self -> fill,
			pointsize   => $self -> pointsize,
			rotate      => $rotation,
			stroke      => $self -> stroke,
			strokewidth => $self -> strokewidth,
			text        => $text[$i],
			x           => $x,
			'y'         => $y, # y eq tr, so syntax highlighting stuffed without ''.
		);

		die $result if $result;

		$x += $self -> pointsize;
	}

}	# End of annotate.

# ------------------------------------------------

sub draw
{
	my($self, %arg) = @_;

	my $i;
	my $s = '';

	for $i (0 .. $#{$self -> x})
	{
		$s .= "${$self -> x}[$i],${$self -> y}[$i] ";
	}

	my %option =
	(
		fill        => 'None',
	 	points      => $s,
		primitive   => 'polyline',
		stroke      => 'Green',
		strokewidth => 1,
		map{(lc $_, $arg{$_})} keys %arg,
	);

	my $result = $self -> image -> Draw(%option);

	die $result if $result;

}	# End of draw.

# ------------------------------------------------

sub dump
{
	my($self) = @_;

	$self -> dump_font_metrics;
	$self -> highlight_data_points;

}	# End of dump.

# ------------------------------------------------

sub dump_font_metrics
{
	my($self)			= @_;
	my(%metric_name)	=
	(
		 0  => 'character width',
		 1  => 'character height',
		 2  => 'ascender',
		 3  => 'descender',
		 4  => 'text width',
		 5  => 'text height',
		 6  => 'maximum horizontal advance',
		 7  => 'bounds.x1',
		 8  => 'bounds.y1',
		 9  => 'bounds.x2',
		10 => 'bounds.y2',
		11 => 'origin.x',
		12 => 'origin.y',
	);

	my @metric = $self -> image -> QueryFontMetrics
	(
		pointsize   => $self -> pointsize,
		strokewidth => $self -> strokewidth,
		text        => 'W',
	);

	print map{"$metric_name{$_}: $metric[$_]. \n"} 0 .. $#metric;
	print "\n";

	my $i;
	my $left_x;
	my $left_y;
	my $result;
	my $right_x;
	my $right_y;

	for ($i = 0; $i <= $#{$self -> x}; $i++)
	{
		$left_x  = ${$self -> x}[$i] - $metric[7];
		$left_y  = ${$self -> y}[$i] - $metric[8];
		$right_x = ${$self -> x}[$i] + $metric[9];
		$right_y = ${$self -> y}[$i] + $metric[10];
		$result  = $self -> image -> Draw
		(
			fill        => 'None',
			points      => "$left_x,$left_y $right_x,$right_y",
			primitive   => 'rectangle',
			stroke      => 'Blue',
			strokewidth => 1,
		);

		die $result if $result;
	}

}	# End of dump_font_metrics.

# ------------------------------------------------

sub highlight_data_points
{
	my($self, %arg)	= @_;
	my(%option)		=
	(
		fill        => 'None',
		primitive   => 'rectangle',
		stroke      => 'Red',
		strokewidth => 1,
		map{(lc $_, $arg{$_})} keys %arg,
	);

	my $i;
	my $left_x;
	my $left_y;
	my $result;
	my $right_x;
	my $right_y;

	for ($i = 0; $i <= $#{$self -> x}; $i++)
	{
		$left_x           = ${$self -> x}[$i] - 2;
		$left_y           = ${$self -> y}[$i] - 2;
		$right_x          = ${$self -> x}[$i] + 2;
		$right_y          = ${$self -> y}[$i] + 2;
		$option{'points'} = "$left_x,$left_y $right_x,$right_y";
		$result           = $self -> image -> Draw(%option);

		die $result if $result;
	}

}	# End of highlight_data_points.

# ------------------------------------------------

1;

=head1 NAME

Image::Magick::PolyText - Draw text along a polyline

=head1 Synopsis

	my $polytext = Image::Magick::PolyText -> new
	(
		debug        => 0,
		fill         => 'Red',
		image        => $image,
		pointsize    => 16,
		rotate       => 1,
		slide        => 0.1,
		stroke       => 'Red',
		strokewidth  => 1,
		text         => 'Draw text along a polyline',
		x            => [0, 1, 2, 3, 4],
		y            => [0, 1, 2, 3, 4],
	);

	$polytext -> annotate;

=head1 Description

C<Image::Magick::PolyText> is a pure Perl module.

It is a convenient wrapper around the C<Image::Magick Annotate()> method, for drawing text along a polyline.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns an C<Image::Magick::PolyText> object.

This is the class contructor.

Usage: Image::Magick::PolyText -> new({...}).

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

=item o pointsize

Takes an integer as its value.

The default value is 16.

The value is passed to the C<Image::Magick Annotate()> method.

This parameter is optional.

=item o rotate

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

Takes an arrayref of x (co-ordinate) values as its value.

There is no default value.

These co-ordinates are the x-axis values of the known points along the polyline.

This parameter is mandatory.

=item o y

Takes an arrayref of y (abcissa) values as its value.

There is no default value.

These abcissae are the y-axis values of the known points along the polyline.

This parameter is mandatory.

=back

=head1 Methods

=head2 annotate()

This method writes the text on to your image.

=head2 draw(%options)

%options is an optional hash of (key => value) pairs.

This method draws straight lines from data point to data point.

The default line color is Green.

The options are a hash ref which is passed to the C<Image::Magick Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> draw({stroke => 'Blue'});

=head2 highlight_data_points(%options)

%options is an optional hash of (key => value) pairs.

This method draws little (5x5 pixel) rectangles centered on the data points.

The default rectangle color is Red.

The options are a hash ref which is passed to the C<Image::Magick Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> highlight_data_points({stroke => 'Black'});

=head1 Example code

See the file examples/pt.pl in the distro.

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

C<Image::Magick::PolyText> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2007.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2007, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
