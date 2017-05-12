package Image::Magick::Tiler;

use strict;
use warnings;

use File::Spec;

use Image::Magick;

use Moo;

use Types::Standard qw/Any ArrayRef Int Str/;

has count =>
(
	default 	=> sub {return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has input_file =>
(
	default		=> sub {return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has geometry =>
(
	default		=> sub {return '2x2+0+0'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has geometry_set =>
(
	default		=> sub {return [2, undef, 2, 0, 0]},
	is			=> 'rw',
	isa			=> ArrayRef,
	required	=> 0,
);

has output_dir =>
(
	default		=> sub {return ''},
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has output_type =>
(
	default		=> sub {return 'png'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has verbose =>
(
	default 	=> sub {return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has write =>
(
	default		=> sub {return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

our $VERSION = '2.00';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	die "Error. You must call new as new(input_file => 'path/to/x.suffix')\n" if (! $self -> input_file);

	my($g)	= $self -> geometry;
	$g		= ($g =~ /^\d+x\d+$/) ? "$g+0+0" : $g;

	my(@g);

	if ($g =~ /^(\d+)(x)(\d)([+-])(\d+)([+-])(\d+)$/)
	{
		@g = ($1, $2, $3, $4, $5, $6, $7);

		$self -> geometry("$g[0]$g[1]$g[2]$g[3]$g[4]$g[5]$g[6]");
		$self -> geometry_set([$g[0], $g[1], $g[2], $g[3], $g[4], $g[5], $g[6] ]);

		if ($self -> verbose)
		{
			print "Image::Magick:        V @{[$Image::Magick::VERSION || 'undef']}\n";
			print "Image::Magick::Tiler: V $Image::Magick::Tiler::VERSION\n";
			print "Geometry:             $g parsed as NxM+x+y = " . $self -> geometry . "\n";
		}
	}
	else
	{
		die "Error. Geometry (NxM+x+y = $g) is not in the correct format. \n";
	}

}	# End of BUILD.

# -----------------------------------------------

sub tile
{
	my($self)	= @_;
	my($image)	= Image::Magick -> new();
	my($result)	= $image -> Read($self -> input_file);

	die "Error. Unable to read file $self -> input_file. Image::Magick error: $result\n" if ($result);

	my(@g)											= @{$self -> geometry_set};
	my($param)										= {};
	$$param{image}									= {};
	($$param{image}{width}, $$param{image}{height})	= $image -> Get('width', 'height');
	$$param{tile}									= {};
	$$param{tile}{width}							= int($$param{image}{width} / $g[0]);
	$$param{tile}{height}							= int($$param{image}{height} / $g[2]);

	if ($self -> verbose)
	{
		print 'Image:                ' . $self -> input_file . "\n";
		print "Image size:           ($$param{image}{width}, $$param{image}{height})\n";
		print "Tile size:            ($$param{tile}{width}, $$param{tile}{height}) (before applying x and y)\n";
	}

	die "Error. Tile width ($$param{tile}{width}) < input x ($g[4]). \n"	if ($$param{tile}{width} < abs($g[4]) );
	die "Error. Tile height ($$param{tile}{height}) < input y ($g[6]). \n"	if ($$param{tile}{height} < abs($g[6]) );

	$$param{tile}{width}	+= $g[4];
	$$param{tile}{height}	+= $g[6];

	if ($self -> verbose)
	{
		print "Tile size:            ($$param{tile}{width}, $$param{tile}{height}) (after applying x and y)\n";
	}

	my($count)	= 0;
	my($output)	= [];
	my($x)		= 0;

	my($y, $tile, $output_file_name);

	for my $xg (1 .. $g[0])
	{
		$y = 0;

		for my $yg (1 .. $g[2])
		{
			$count++;

			$output_file_name	= "$yg-$xg." . $self -> output_type;
			$output_file_name	= File::Spec -> catfile($self -> output_dir, $output_file_name) if ($self -> output_dir);
			$tile				= $image -> Clone();

			die "Error. Unable to clone image $output_file_name\n" if (! ref $tile);

			$result = $tile -> Crop(x => $x, y => $y, width => $$param{tile}{width}, height => $$param{tile}{height});

			die "Error. Unable to crop image $output_file_name. Image::Magick error: $result\n" if ($result);

			push @{$output},
			{
				file_name	=> $output_file_name,
				image		=> $tile,
			};

			if ($self -> write)
			{
				$tile -> Write($output_file_name);

				if ($self -> verbose > 1)
				{
					print 'Wrote tile ' . sprintf('%4d', $count) . "       $output_file_name\n";
				}
			}

			$y += $$param{tile}{height};
		}

		$x += $$param{tile}{width};
	}

	if ($self -> verbose)
	{
		print "Tile count:           $count\n";
	}

	$self -> count($count);

	return $output;

}	# End of tile.

# -----------------------------------------------

1;

__END__

=head1 NAME

Image::Magick::Tiler - Slice an image into NxM tiles

=head1 Synopsis

This program ships as scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use Image::Magick::Tiler;

	# ------------------------

	my($temp_dir) = '/tmp';
	my($tiler)    = Image::Magick::Tiler -> new
	(
		input_file  => File::Spec -> catdir('t', 'sample.png'),
		geometry    => '3x4+5-6',
		output_dir  => $temp_dir,
		output_type => 'png',
		verbose     => 2,
		write       => 1,
	);

	my($tiles) = $tiler -> tile;
	my($count) = $tiler -> count; # Warning: Must go after calling tile().

	print "Tiles written: $count. \n";

	for my $i (0 .. $#$tiles)
	{
		print "Tile: @{[$i + 1]}. File name:   $$tiles[$i]{file_name}\n";
	}

This slices image.png into 3 tiles horizontally and 4 tiles vertically.

Further, the width of each tile is ( (width of sample.png) / 3) + 5 pixels,
and the height of each tile is ( (height of sample.png) / 4) - 6 pixels.

In the geometry option NxM+x+y, the x and y offsets (positive or negative) can be used to change
the size of the tiles.

For example, if you specify 2x3, and a vertical line spliting the image goes through an
interesting part of the image, you could then try 2x3+50, say, to move the vertical line 50 pixels
to the right. This is what I do when printing database schema generated with L<GraphViz2::DBI>.

Aslo, try running: perl scripts/tile.pl -h.

=head1 Description

C<Image::Magick::Tiler> is a pure Perl module.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<Image::Magick::Tiler> object.

This is the class contructor.

Parameters:

=over 4

=item o input_file => $str

This parameter as a whole is mandatory.

=item o geometry => $str

This parameter is optional.

But, from V 2.00 on, no items within the geometry are optional.

The format of $str is 'NxM+x+y'.

N is the default number of tiles in the horizontal direction.

M is the default number of tiles in the verical direction.

Negative or positive values can be used for x and y. Negative values will probably cause extra tiles
to be required to cover the image. That why I used the phrase 'default number of tiles' above.

An example would be '2x3-10-12'.

Default: '2x2+0+0'.

=item o output_dir => $str

This parameter is optional.

Default: ''.

=item o output_type => $str

This parameter is optional.

Default: 'png'.

=item o verbose => $int

This parameter is optional.

It takes the values 0, 1 and 2.

If 0, nothing is written. If 1, various statistics are written. If 2, you get stats plus a line
about every tile written.

Default: 0.

=item o write => $Boolean

This parameter is optional.

It takes the values 0 and 1.

A value OF 0 stops tiles being written to disk.

Setting it to 1 causes the tiles to be written to disk using the automatically generated files names
as discussed in L</tile()>.

Default: 0.

=back

=head1 Methods

=head2 count()

After calling L</tile()>, this returns the number of tiles generated.

=head2 input_file([$str])

Here, [ and ] indicate an optional parameter.

Gets or sets the name of the input file.

C<input_file> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 geometry([$str])

Here, [ and ] indicate an optional parameter.

Gets or sets the geometry to use to cut up the image into tiles.

C<geometry> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 geometry_set()

Returns an arrayref corresponding to the components of the geometry.

Example: '4x5+10-6' is returned as [4, 'x', 5, '+', 10, '-', 6].

=head2 new()

Returns a object of type C<Image::Magick::Tiler>.

See above, in the section called 'Constructor and initialization'.

=head2 output_dir([$str])

Here, [ and ] indicate an optional parameter.

Gets or sets the name of the output directory into which the tiles are written if C<new()> is called
as C<< new(write => 1) >> or if C<write()> is called as C<write(1)>.

C<output_dir> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 output_type([$str])

Here, [ and ] indicate an optional parameter.

Gets or sets the type of tile image generated.

$str takes values such as 'png', 'jpg', etc.

C<output_type> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 tile()

Chops up the input image and returns an arrayref of tile details.

Each element of this arrayref is a hashref with these keys:

=over 4

=item o file_name

This is an automatically generated file name.

When the geometry is '2x3+0+0', say, the file names are of the form 1-1.png, 1-2.png, 2-1.png,
2-2.png, 3-1.png and 3-2.png. Clearly, these are just the corresponding matrix subscripts of the
tiles.

See L</output_type([$str])> to change the output file type.

=item o image

This is the Image::Magick object for one tile.

=back

=head2 verbose([$int])

Here, [ and ] indicate an optional parameter.

Gets or sets the option for how much information is printed to STDOUT.

$int may take the values 0 .. 2.

C<verbose> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 write([$Boolean])

Here, [ and ] indicate an optional parameter.

Gets or sets the option for whether or not the tiles are actaully written to disk.

$Boolean takes the values 0 (do not write tiles) and 1 (write tiles).

C<write> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head1 Repository

L<https://github.com/ronsavage/Image-Magick-Tiler>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image::Magick::Tiler>.

=head1 Author

C<Image::Magick::Tiler> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2005.

L<Homepage|http://savage.net.au/>

=head1 Copyright

Australian copyright (c) 2005, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
