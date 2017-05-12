package Image::Tileset;

use strict;
use warnings;
use Image::Magick;
use XML::Simple;
use Data::Dumper;

our $VERSION = '0.01';

=head1 NAME

Image::Tileset - A tileset loader.

=head1 SYNOPSIS

  use Image::Tileset;

  my $ts = new Image::Tileset (
    image => "my-tileset.png",
    xml   => "my-tileset.xml",
  );

  open (OUT, ">grass.png");
  binmode OUT;
  print OUT $ts->tile("grass");
  close (OUT);

=head1 DESCRIPTION

Image::Tileset is a simple tileset image loader. The preferred usage is to have
an XML description file alongside the tileset image that describes how the
tiles are to be sliced up.

The module supports "simple" tilesets (where all tiles have a uniform width and
height, though they don't need to begin at the top left corner of the image)
as well as "fixed" tilesets (where you need to specify the exact pixel coords
of every tile).

It also supports the management of animations for your tiles (but not the means
to display them; this is left up to your front-end code. There is a demo that
uses Perl/Tk to give you an idea how to do this).

=head1 SPECIFICATION FILE

Tileset images are paired with a "specification file," which describes how the
image is to be sliced up into the different tiles.

The spec file is usually an XML document, and it's read with L<XML::Simple|XML::Simple>.
If you wish, you can also send the spec data as a Perl data structure, skipping
the XML part.

An example XML file is as follows, and shows all the capabilities of the
spec file markup:

  <?xml version="1.0" encoding="utf-8"?>
  <tileset>
    <!--
      The simplest form: the uniform tile set. In this case, all the tiles are
      32x32 pixels large and the first tile is in the top left corner of the
      image, at pixel coordinate 0,0
    -->
    <layout type="tiles" size="32x32" x="0" y="0">
      <!--
        Within a "tiles" layout, X and Y refer to the "tile coordinate", not
        the "pixel coordinate". So, the top left tile is 0,0 and the one to
        the right of it is 1,0 (even though its pixel coordinate would be 32,0).
        The module takes care of this all for you!)

        Each tile needs a unique ID, called the "tile id".
      -->
      <tile x="0" y="0" id="grass" />
      <tile x="1" y="0" id="sand"  />
      <tile x="2" y="0" id="dirt"  />

      <!--
        We have three "water" tiles that we intend to animate later, but
        each one still needs its own unique ID!
      -->
      <tile x="0" y="1" id="water-1" />
      <tile x="1" y="1" id="water-2" />
      <tile x="2" y="1" id="water-3" />
    </layout>

    <!--
      In addition to simple grid-based tiles, you can also specify pixel
      coordinates directly. Use the "fixed" layout for this.
    -->
    <layout type="fixed">
      <!--
        In fixed layout, you need to specify 4 pixel coordinates for where
        the tile appears in the image: x1,y1,x2,y2.
      -->
      <tile x1="96" y1="0" x2="128" y2="96" id="avatar" />
    </layout>

    <!--
      For animations, you need to give the animation a unique ID and then
      tell it which tiles (by their IDs) go into the animation. The "speed"
      attribute controls how fast the animation plays by setting the delay
      (in milliseconds) until the next tile should be shown.
    -->
    <layout type="animation" id="water" speed="200">
      <tile>water-1</tile>
      <tile>water-2</tile>
      <tile>water-3</tile>
      <tile>water-2</tile>
    </layout>
  </tileset>

Your application can also provide spec data as a Perl structure instead of as
XML. Here is an example of the above XML as a Perl structure:

  $ts->spec( [
    {
      type => 'tiles',
      size => '32x32',
      x    => 0,
      y    => 0,
      tile => [
        { x => 0, y => 0, id => 'grass'   },
        { x => 1, y => 0, id => 'sand'    },
        { x => 2, y => 0, id => 'dirt'    },
        { x => 0, y => 1, id => 'water-1' },
        { x => 1, y => 1, id => 'water-2' },
        { x => 2, y => 1, id => 'water-3' },
      },
    },
    {
      type => 'fixed',
      tile => [
        { x1 => 96, y1 => 0, x2 => 128, y2 => 96, id => 'avatar' },
      ],
    },
    {
      type  => 'animation',
      id    => 'water',
      speed => 200,
      tile  => [ 'water-1', 'water-2', 'water-3', 'water-2' ],
    },
  ]);

See the examples in the C<demo/> folder for more information.

=head1 METHODS

=head2 new (hash options)

Create a new C<Image::Tileset> object. Options include:

  bool   debug:  Debug mode (prints stuff to the terminal on STDERR)
  string xml:    Path to an XML spec file that describes the image.
  hash   spec:   Spec data in Perl data structure form (skip XML file).
  string image:  Path to the image file.

If you provide C<xml>, the XML will be parsed and refined immediately. If you
provide C<spec>, it will be refined immediately. If you provide C<image>, the
image will be loaded immediately.

=cut

sub new {
	my $class = shift;

	my $self = {
		debug  => 0,      # Debug mode
		xml    => '',     # XML file
		spec   => [],     # Spec data (XML data in Perl form)
		image  => '',     # Image file
		magick => undef,  # Image::Magick object
		error  => '',     # Last error state
		tiles  => {},     # Tile positions in tileset
		animations => {}, # Animation information
		@_,
	};
	bless ($self,$class);

	$self->{magick} = Image::Magick->new;

	# If given an image, load it.
	if (length $self->{image}) {
		$self->image ($self->{image});
		$self->{image} = '';
	}

	# If given an XML file, load it.
	if (length $self->{xml}) {
		$self->xml ($self->{xml});
		$self->{xml} = '';
	}

	# If given a spec, load it.
	if (ref($self->{spec}) eq "ARRAY" && scalar @{$self->{spec}} > 0) {
		$self->refine ($self->{spec});
		$self->{spec} = [];
	}

	return $self;
}

sub debug {
	my ($self,$line) = @_;
	return unless $self->{debug};
	print STDERR "$line\n";
}

=head2 void error ()

Print the last error message given. Example:

  $tileset->image("myfile.png") or die $tileset->error;

=cut

sub error {
	my ($self,$error) = @_;
	if (defined $error) {
		$self->{error} = $error;
	}
	return $self->{error};
}

=head2 bool image (string filepath)

Load an image file with C<Image::Magick>. The object is just kept in memory for
when you actually want to get a tile from it.

Returns 1 on success, undef on error.

=cut

sub image {
	my ($self,$image) = @_;
	$self->debug("Attempting to load image file from $image");

	# Exists?
	if (!-e $image) {
		$self->error("Can't load image file $image: file not found!");
		return undef;
	}

	# Load it with Image::Magick.
	my $x = $self->{magick}->Read($image);
	if ($x) {
		warn $x;
		return undef;
	}

	return 1;
}

=head2 bool data (bin data)

If your program already has the image's binary data in memory, it can send it
directly to this function. It will create an C<Image::Magick> object based off
the binary data directly, instead of needing to read a file from disk.

Returns 1 on success, undef on error.

=cut

sub data {
	my ($self,$data) = @_;

	# Load it with Image::Magick.
	my $x = $self->{magick}->BlobToImage($data);
	if ($x) {
		warn $x;
		return undef;
	}

	return 1;
}

=head2 void clear ()

Clear the internal C<Image::Magick> object, unloading the tileset.

=cut

sub clear {
	my $self = shift;

	undef $self->{magick};
	$self->{magick} = new Image::Magick();
}

=head2 bool xml (string xmldata | string specfile)

Load a specification file from XML. Pass either XML data or the path to a
file name.

If the data sent to this command begins with a left chevron, E<lt>, or contains
newlines, it is assumed to be XML data; otherwise the filesystem is queried.

Returns 1 on success, undef on error.

=cut

sub xml {
	my ($self,$file) = @_;

	# Load it with XML::Simple.
	my $o_xs = new XML::Simple (
		RootName   => 'tileset',
		ForceArray => 1,
		KeyAttr    => 'id',
	);

	my $xs = {};
	if ($file =~ /^\s*</ || $file =~ /[\x0D\x0A]/) {
		$self->debug("Attempting to load XML data $file!");
		$xs = $o_xs->XMLin($file);
	}
	elsif (-f $file) {
		$self->debug("Attempting to load XML from file $file!");
		$xs = $o_xs->XMLin($file);
	}
	else {
		$self->error("Couldn't load XML data: file not found!");
		return undef;
	}

	# Does it look good?
	if (!exists $xs->{layout}) {
		$self->error("No layout information was found in XML spec file!");
		return undef;
	}

	# Refine it. We want pixel coords of every named tile.
	$self->refine($xs->{layout}) or return undef;

	return 1;
}

=head2 bool refine (array spec)

Refines the specification data. The spec describes how the image is cut up;
C<refine()> goes through that and stores the exact pixel coordinates of every
tile named in the spec, for quick extraction when the tile is wanted.

This method is called automatically when an XML spec file is parsed. If you
pass in a C<spec> during the call to C<new()>, this method will be called
automatically for your spec. If you want to load a spec directly after you've
created the object, you can call C<refine()> directly with your new spec.

=cut

sub refine {
	my ($self,$spec) = @_;

	# It must be an array.
	if (ref($spec) ne "ARRAY") {
		$self->error("Spec file must be an array of layouts!");
		return undef;
	}

	# Clear the currently loaded data.
	delete $self->{tiles};
	delete $self->{animations};
	$self->{tiles} = {};
	$self->{animations} = {};

	# Go through the layouts.
	$self->debug("Refining the specification...");
	foreach my $layout (@{$spec}) {
		my $type = lc($layout->{type});

		# Supported layout types:
		# tiles
		# fixed
		# animation
		if ($type eq "tiles") {
			# How big are the tiles?
			if ($layout->{size} !~ /^\d+x\d+$/) {
				$self->error("Syntax error in spec: 'tiles' layout but no valid tile 'size' set!");
				return undef;
			}
			my ($width,$height) = split(/x/, $layout->{size}, 2);
			$self->debug("Looking for 'tiles' layout; tile dimensions are $width x $height");

			# Offset coords.
			my $x = $layout->{x} || 0;
			my $y = $layout->{y} || 0;

			# Collect the tiles.
			foreach my $id (keys %{$layout->{tile}}) {
				# Tile coordinates.
				my $tileX = $layout->{tile}->{$id}->{x};
				my $tileY = $layout->{tile}->{$id}->{y};

				# Pixel coordinates.
				my $x1 = $x + ($width * $tileX);
				my $x2 = $x1 + $width;
				my $y1 = $y + ($height * $tileY);
				my $y2 = $y1 + $height;
				$self->debug("Found tile '$id' at pixel coords $x1,$y1,$x2,$y2");

				# Store it.
				$self->{tiles}->{$id} = [ $x1, $y1, $x2, $y2 ];
			}
		}
		elsif ($type eq "fixed") {
			# Fixed is easy, we already have all the coords we need.
			$self->debug("Looking for 'fixed' tiles");
			foreach my $id (keys %{$layout->{tile}}) {
				# Pixel coordinates.
				my $x1 = $layout->{tile}->{$id}->{x1};
				my $y1 = $layout->{tile}->{$id}->{y1};
				my $x2 = $layout->{tile}->{$id}->{x2};
				my $y2 = $layout->{tile}->{$id}->{y2};
				$self->debug("Found tile '$id' at pixel coords $x1,$y1,$x2,$y2");

				# Store it.
				$self->{tiles}->{$id} = [ $x1, $y1, $x2, $y2 ];
			}
		}
		elsif ($type eq "animation") {
			# Animations just have a list of tiles involved and some meta info.
			my $id = $layout->{id}; # Name of the animation sprite
			my $speed = $layout->{speed} || 500; # Speed of animation, in milliseconds
			$self->{animations}->{$id} = {
				speed => $speed,
				tiles => $layout->{tile},
			};
		}
		else {
			warn "Unknown layout type '$type'!";
		}
	}
}

=head2 data tiles ()

Return the tile coordinate information. In array context, returns a list of the
tile ID's. In scalar context, returns a hash reference in the following format:

  {
    'tile-id' => [
      x1, y1,
      x2, y2
    ],
    ...
  };

=cut

sub tiles {
	my ($self) = @_;
	return wantarray ? sort keys %{$self->{tiles}} : $self->{tiles};
}

=head2 data animations ()

Return the animation information. In array context, returns a list of the
animation ID's. In scalar context, returns a hash reference in the following
format:

  {
    'animation-id' => {
      speed => '...',
      tiles => [
        'tile-id',
        ...
      ],
    },
  };

=cut

sub animations {
	my ($self) = @_;
	return wantarray ? sort keys %{$self->{animations}} : $self->{animations};
}

=head2 bin tile (string id[, hash options])

Get the binary data of one of the tiles, named C<id>, from the original
tileset.

You can optionally pass in a hash of named options. The following options are
supported:

  int scale:   Scale the tile before returning its data. This is a number to
               scale it by, for example '2' returns it at 200% its original size,
               while '0.5' returns it at 50% its original size.
  str size:    Resize the tile to this exact size before returning it, for
               example '64x64'.
  bool magick: If true, returns the Image::Magick object instead of the binary
               data. If you want to make additional modifications to the image
               (i.e. edit its colors, apply special effects), use the 'magick'
               option and then apply the effects yourself.

The options C<scale> and C<size> are mutually exclusive.

Examples:

  # The tiles are 32x32, but lets scale it 2X so we get back a 64x64 tile
  my $tile = $ts->tile("grass", scale => 2);

  # Get it at 1/2 its original size, or 16x16
  my $tile = $ts->tile("grass", scale => 0.5);

  # Get it at 24x24 pixels
  my $tile = $ts->tile("grass", size => "24x24");

Returns undef on error.

=cut

sub tile {
	my ($self,$id,%opts) = @_;

	# Tile exists?
	if (!exists $self->{tiles}->{$id}) {
		$self->error("No tile named '$id' in tileset!");
		return undef;
	}

	# Slice the image.
	my $slice = $self->slice ($id);

	# Are they transforming the image?
	if (exists $opts{scale} || exists $opts{size}) {
		# Get the tile's size.
		my $width  = $self->{tiles}->{$id}->[2] - $self->{tiles}->{$id}->[0];
		my $height = $self->{tiles}->{$id}->[3] - $self->{tiles}->{$id}->[1];

		if (exists $opts{scale}) {
			if ($opts{scale} !~ /^[0-9\.]+$/) {
				$self->error("Invalid scale factor: $opts{scale}");
				return undef;
			}

			$width = int($width * $opts{scale});
			$height = int($height * $opts{scale});
		}
		elsif (exists $opts{size}) {
			if ($opts{size} !~ /^\d+x\d+$/) {
				$self->error("Invalid scale size: $opts{size}");
				return undef;
			}

			($width,$height) = split(/x/, $opts{size}, 2);
		}

		# Scale it.
		$self->debug("Resizing tile down to $width x $height");
		$slice->Scale (width => $width, height => $height);
	}

	# Do they want the magick object?
	if (exists $opts{magick} && $opts{magick}) {
		return $slice;
	}

	my $png = $slice->ImageToBlob();
	return $png;
}

=head2 data animation (string id)

Get the animation information about a specific animation ID.

Returns data in the format:

  {
    speed => '...',
    tiles => [ ... ],
  };

Returns undef on error.

=cut

sub animation {
	my ($self,$id) = @_;

	# Animation exists?
	if (!exists $self->{animations}->{$id}) {
		$self->error("No animation named '$id' in tileset!");
		return undef;
	}

	return $self->{animations}->{$id};
}

=head2 ImageMagick slice (string id)

Returns an C<Image::Magick> object that contains the sliced tile from the
original tileset. This is mostly for internal use only.

=cut

sub slice {
	my ($self,$id) = @_;

	# Tile exists?
	if (!exists $self->{tiles}->{$id}) {
		$self->error("No tile named '$id' in tileset!");
		return undef;
	}

	# Get the dimensions of the tile.
	my $width  = $self->{tiles}->{$id}->[2] - $self->{tiles}->{$id}->[0]; # x2 - x1
	my $height = $self->{tiles}->{$id}->[3] - $self->{tiles}->{$id}->[1]; # y2 - y1
	if ($width < 1 || $height < 1) {
		$self->error("Tile '$id' has impossible dimensions: $width x $height");
		return undef;
	}

	my $dims = $width . 'x' . $height;

	# Make a new ImageMagick object.
	my $slice = $self->{magick}->Clone();

	# Crop it.
	my $x = $self->{tiles}->{$id}->[0];
	my $y = $self->{tiles}->{$id}->[1];
	my $crop = $dims . "+$x+$y";
	$self->debug("Cropping image clone to $crop for tile $id");
	$slice->Crop($crop);

	return $slice;
}

=head1 SEE ALSO

L<Image::Magick|Image::Magick>, which powers this module's graphics handling.

L<XML::Simple|XML::Simple>, which powers this module's XML parsing.

=head1 CHANGES

  0.01  Fri Jan 15 2010
  - Initial release.

=head1 COPYRIGHT

The tileset graphics included for demonstration purposes are from RPG Maker
2003 and are copyright (C) Enterbrain.

Code written by Noah Petherbridge, http://www.kirsle.net/

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10.0 or, at your option,
any later version of Perl 5 you may have available.

=cut

1;
