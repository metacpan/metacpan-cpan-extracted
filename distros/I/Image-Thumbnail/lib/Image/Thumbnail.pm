package Image::Thumbnail;

use Carp;
use strict;
use warnings;
our $VERSION = '0.66';

=head1 NAME

Image::Thumbnail - Simple thumbnails with various Perl libraries

=head1 SYNOPSIS

	use Image::Thumbnail 0.65;

	# Create a thumbnail from 'test.jpg' as 'test_t.jpg'
	# using ImageMagick, Imager, GD or Image::Epeg.
	my $t = new Image::Thumbnail(
		size       => 55,
		create     => 1,
		input      => 'test.jpg',
		outputpath => 'test_t.jpg',
	);

	# With Image Magick
	my $t = new Image::Thumbnail(
		size       => "55x75",
		create     => 1,
		module	   => "Image::Magick",
		input      => $imageObject,
		outputpath => 'test_t.jpg',
	);

	# Create a thumbnail from 'test.jpg' as 'test_t.jpg'
	# using GD.
	my $t = new Image::Thumbnail(
		module     => 'GD',
		size       => 55,
		create     => 1,
		input      => 'test.jpg',
		outputpath => 'test_t.jpg',
	);

	# Create a thumbnail from 'test.jpg' as 'test_t.jpg'
	# using Imager.
	my $t = new Image::Thumbnail(
		module     => 'Imager',
		size       => 55,
		create     => 1,
		input      => 'test.jpg',
		outputpath => 'test_t.jpg',
	);

	# Create a thumbnail as 'test_t.jpg' from an ImageMagick object
	# using ImageMagick, or GD.
	my $t = new Image::Thumbnail(
		size       => "55x25",
		create     => 1,
		input      => $my_image_magick_object,
		outputpath => 'test_t.jpg',
	);

	# Create four more of ever-larger sizes
	for (1..4){
		$t->{size} = 55+(10*$_);
		$t->create;
	}

	exit;

=head1 DESCRIPTION

This module was created to answer the FAQ, 'How do I simply create a
thumbnail with pearl?' (I<sic>). It allows you to easily make thumbnail images
from files, objects or (in most cases) 'blobs', using either the ImageMagick, 
C<Image::Epeg>, Imager or GD libraries.

Thumbnails created can either be saved as image files or accessed as objects
via the C<object> field: see L</create>.

In the experience of the author, thumbnails are created fastest
with direct use of the L<Image::Epeg> module.

=head1 PREREQUISITES

One of C<Image::Magick>, C<Imager>, L<Image::Epeg>, or C<GD>.

=head1 CONSTRUCTOR new

Parameters are supplied as a hash or hash-like list of name/value pairs:
See the L</SYNOPSIS>.

=head2 REQUIRED PARAMETERS

=over 4

=item size

The size you with the longest side of the thumbnail to be. This may
be provided as a single integer, or as an ImageMagick-style 'geometry'
such as C<100x120>.

=item input

You must the C<input> parameter as one of:

=over 4

=item Input file path

A scalar that is an absolute path to an image to use as the source file.

=item Object

An object-reference created by your chosen package.
Naturally you can't supply this field if you haven't
specified a C<module> field (see above).

=item Blob

A reference to a scalar that is the raw binary image data, perhaps drawn from
a database BLOB column, perhaps from a file.

=back

The formerly required input fields should be considered depricated,
and although they will be kept in the API for this release, they will eventually
be removed.

=back

=head2 OPTIONAL PARAMETERS

=over 4

=item module ( GD | Image::Magick | Imager | Image::JPEG)

If you wish to use a specific module, place its name here.
You must have the module you require already installed!

Supplying no name will allow ImageMagick, then Imager to be tried before GD.

=item create

Put any value in this field if you wish the constructor to
call the C<create> method automatically before returning.

=item inputtype, outputtype

If you are using C<GD>, you can explicitly set the input
and output formats for the image file, provided you use
a string that can be evaluated to a C<GD>-supported image
format (see L<GD>).

Default behaviour is to attempt to ascertin the file type
and to create the thumbnail in the same format. If the
type cannot be defined (you are using C<GD>, have supplied
the C<object> field and not the C<outputtype> field) then
the output file format defaults to C<jpeg>.

=item depth

Sets colour depth in ImageMagick - AFAIK GD only supports 8-bit.

The ImageMagick manpage (see L<http://www.imagemagick.org/www/ImageMagick.html#opti>).
says:

=item density

ImageMagick only: sets the pixel density.
Must be a valid ImageMagick 'geometry' value (that is,
two numbers giving the I<x> and I<y> dimensions, delimited
by a lower-case I<x>.
Default value is C<96x96>.

=item quality

ImageMagick/Imager only: an integer from 1 to 100 to specify
the thumbnail quality. Defaults to 50.

=item attr

If you are using ImageMagick, this field should contain
a hash of ImageMagick attributes to pass to the ImageMagick
C<Set> command when the thumbnail is created. Any errors these
may generate are not yet caught.

=item CHAT

Put any value in this field for real-time process info.

=cut

# If you are using GD, this field should contain a hash where
# keys are GD method names, and values are the arrays of
# paramters for those methods (naturally excluding the object
# reference).

# =over 4

# This is the number of bits in a color sample within
#a pixel. The only acceptable values are 8 or 16. Use this
#option to specify the depth of raw images whose depth is
#unknown such as GRAY, RGB, or CMYK, or to change the
#depth of any image after it has been read.

=head2 PARAMETERS SET

=over 4

=item x,y

The dimension of the thumbnail produced.

=back

=head2 ERRORS

As of version 0.4, any errors are stored in the fields
C<error>, warnings in C<warning>.

Any errors will be printed to C<STDOUT>. If they completely
prevent processing, they will be fatal (C<croak>ed). If
partial processing has taken place by the explicit or implicit
calling of the C<create> method, then the field of the same
name will have value.

Depending on how far processing has proceded, other fields may have useful values:
the C<module> field will contain the name of the module used;
the C<object> field may contain an object of the module used;
the C<thumb> field may contain a thumbnail image.

=cut

sub new { my $class = shift;
    unless (defined $class) {
    	carp "Usage: ".__PACKAGE__."->new( {key=>value} )\n";
    	return undef;
	}
	my %args;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	else {
		carp "Usage: $class->new( { key=>values, } )";
		return undef;
	}
	my $self = bless {}, $class;

	# Fields that have default values which can be over-written:
	$self->{density} = '96x96';
	$self->{quality} = 50;

	# Set/overwrite default fields with user's values:
	foreach (keys %args) {
		$self->{$_} = $args{$_};
	}

	# Fill slots the user may have filled but should not:
	$self->{img}	= '';
	$self->{thumb}	= '';

	# Croak on user errors
	if ($self->{density} !~ /^\d+x\d+$/){
		croak "The 'density' param expects a geometry argument, such as 128x128"
	}
	croak "No 'size' paramter" if not $self->{size};

	my $t = grep( $self->{$_}, qw[object inputpath input]);

	if ($self->{input}){
		if (ref $self->{input}){
			if (ref $self->{input} eq 'SCALAR'){
				$self->{inputblob} = $self->{input};
			} else {
				$self->{object} = $self->{input};
			}
		}
		else {
			$self->{inputpath} = $self->{input}
		}
	}

	croak "You cannot supply both an 'object' field and a 'inputpath' field" if $t>1;
	croak "You must supply either an 'object' field or a 'inputpath' field"  if $t==0;

	# Try not to limit Image::Magick...
	if ($self->{inputpath}
	and $self->{module} and $self->{module} =~ /^(GD|GD::Image)$/
	and not -e $self->{inputpath}){
		croak "The supplied inputpath '$self->{inputpath}' does not exist:\n$!"
	}

	# Correct common user errors
	if ($self->{module} and $self->{module} =~ /^ImageMagick$/i){
		$self->{module} = 'Image::Magick';
		warn "Corrected parameter 'module' from 'ImaegMagick' to 'Image::Magick'" if $self->{CHAT};
	}

	# Sort out the Thumbnail module
	if (not $self->set_mod){
		$self->{error} = "No module found with which to make a thumbnail";
		warn $self->{error};
		return undef;
	}

	# Call 'create' if requested
	$self->create if $self->{create};
	return $self;
}


#
# Sometimes self-recursive
#
sub set_mod { my ($self,$try) = (shift,shift);
	warn "# Set module...".(defined $try? "try $try" : "(not trying)") if $self->{CHAT};

	if (not $self->{module} and $self->{object}){
		$self->{module} = ref $self->{object};
		warn "Set module to match the supplied object: $self->{module}" if $self->{CHAT};
	}

	elsif ($try){
		$self->{module} = $try;
	}

	elsif (not $self->{module} and not $try){
		for (qw( Image::Epeg Image::Magick Imager GD )){
			warn "# Try $_" if $self->{CHAT};
			if (not $self->set_mod($_)){
				next;
				return undef;
			} else {
				warn "# Set $_" if $self->{CHAT};
				last;
			}
		}
		warn "# Using ".$self->{module} if $self->{CHAT};
		return $self->{module};
	}

	if ($self->{module} eq 'Image::Epeg'){
		warn "# Requiring Image::Epeg" if $self->{CHAT};
		eval { require Image::Epeg };
		if ($@){
			$self->{error} = "Error requring Image::Epeg:\n".$@;
			return undef;
		}
		import Image::Epeg;
		warn "# Image::Epeg OK" if $self->{CHAT};
	}

	elsif ($self->{module} =~ /^GD/){
		warn "# Requiring GD" if $self->{CHAT};
		eval { require GD };
		if ($@){
			$self->{error} = "Error requring GD:\n".$@;
			return undef;
		}
		import GD;
		warn "# GD OK" if $self->{CHAT};
	}

	elsif ($self->{module} eq 'Image::Magick'){
		warn "# Requiring Image::Magick" if $self->{CHAT};
		eval { require Image::Magick };
		if ($@){
			$self->{error} = "Error requring Image::Magick:\n".$@;
			return undef;
		}
		import Image::Magick;
		warn "# Image::Magick OK" if $self->{CHAT};
	}

	elsif ($self->{module} eq 'Imager'){
		warn "# Requiring Imager ..." if $self->{CHAT};
		eval { require Imager };
		if ($@){
			$self->{error} = "Error requring Imager:\n".$@;
			return undef;
		}
		if (defined $self->{object}->{ERRSTR} and $self->{object}->{ERRSTR} ne ''){
			$self->{error} = $self->{object}->{ERRSTR};
			return undef;
		}
		import Imager;
		warn "# Imager OK" if $self->{CHAT};
	}

    else {
		$self->{error} = "Unsupported module $self->{module}" if $self->{CHAT};
		return undef;
	}

	return $self->{module};
}


=head1 METHOD create

Creates a thumbnail using the supplied object.
This method is called automatically if you construct with the
C<create> field flagged.

Sets the following fields:

=over 4

=item module

Will contain the name of the module used (set by this module
if not by the user);

=item object

Will contain an instance of the module used;

=item thumb

Will contain the thumbnail image.

=back

Returns c<undef> on failure.

=cut

sub create { my $self = shift;
	my $r;
	warn "# Creating thumbnail" if $self->{CHAT};
	if ($self->{module} eq 'Image::Epeg'){
		$r = $self->create_epeg;
	} 
	elsif ($self->{module} eq 'Image::Magick'){
		$r = $self->create_imagemagick;
	} 
	elsif ($self->{module} eq 'Imager'){
		$r = $self->create_imager;
	} 
	elsif ($self->{module} =~ /^(GD|GD::Image)$/){
		$r = $self->create_gd;
    } 
    else {
		$self->{error} = "User supplied unknown module ".$self->{module};
		warn $self->{error};
		$r = undef;
	}
	return $r;
}


#
# METHOD create_imagemagick
#
sub create_imagemagick { my $self=shift;
	warn "#...with Image::Magick" if $self->{CHAT};
	if (not $self->{object} or ref $self->{object} ne 'Image::Magick'){
		warn "#...from file $self->{inputpath}" if $self->{CHAT};
		$self->{object} = Image::Magick->new;
		if ($self->{inputblob}) {
			$self->{object}->BlobToImage( ${$self->{input}} );
		}
		elsif ($self->{inputpath}){
			$self->{error} = $self->{object}->Read($self->{inputpath});
			if ($self->{error}){
				$self->{error} = $self->{error} if $self->{CHAT};
				return undef;
			}
		}
		else {
			$self->{error} = "No input of any kind!\n";
			return undef;
		}
	}
	return undef unless $self->imagemagick_thumb;

	if ($self->{outputpath}){
		warn "# Writing to $self->{outputpath}" if $self->{CHAT};
		$_ = $self->{object}->Write($self->{outputpath});
		$self->set_errors($_);
	}
	warn "# Done Image::Magick: ",$self->{x}," ",$self->{y} if $self->{CHAT};
	return 1;
}

#
# METHOD create_gd
#
sub create_gd { my $self=shift;
	local (*IN, *OUT);
	warn "# ... with GD" if $self->{CHAT};

	if ($self->{inputblob}){
		# Ascertain image type:
		$self->get_img_type;
		if (not $self->{inputtype}){
			$self->{error} = "Could not ascertain image type for BLOB";
			return undef;
		}
		# Make the object
		$self->{object} = eval ( 'GD::Image->newFrom'.ucfirst($self->{inputtype}).'Data(${$self->{inputblob}})');
		if ($@){
			$self->{error} = "Error in creating GD object from BLOB: $@";
			return undef;
		}
	}

	# Load the source image
	elsif ($self->{inputpath}){
		if (not open IN, $self->{inputpath}){
			$self->{error} = "Could not open source ".$self->{inputpath};
			return undef;
		}
		binmode IN;
		# Ascertain image type:
		$self->get_img_type(*IN);
		if (not $self->{inputtype}){
			close IN;
			$self->{error} = "Could not ascertain image type for $self->{inputpath}";
			return undef;
		}
		# Make the object
		$self->{object} = eval ( 'GD::Image->newFrom'.ucfirst($self->{inputtype}).'(*IN)');
		close IN;
		if ($@){
			$self->{error} = "Error in creating GD object from file: $@";
			return undef;
		}
	}

	# Set output type to input type if not defined already
	$self->{outputtype} = $self->{inputtype} ;
	if (not $self->{outputtype}){
		$self->{outputtype} = $self->{inputtype} || 'png'
	}

	# Call attr: eg. $im->fill(50,50,$red);
#	if ($self->{attr}){
#		foreach my $key (keys %{$self->{attr}}){
#			eval ($self->{object}."->".$key."(@{$self->{attr}->{$key}})");
#			# Catch errors?
#		}
#	}

	# Make thumbnail
	($self->{thumb},$self->{x},$self->{y}) = $self->gd_thumb;

	if ($self->{outputpath}){
		# Save your thumbnail
		if (not open OUT, ">".$self->{outputpath}){
			$self->{error} = " Could not save thumbnail image to $self->{outputpath}:\n$!";
			return undef;
		}
		binmode OUT;
		warn "# Saving as $self->{outputpath}, type $self->{outputtype}" if $self->{CHAT};
		print OUT eval ( '$self->{thumb}->'.lc $self->{outputtype} );
		if ($@){
			$self->{error} = "Error in outputting: $@";
			return undef;
		}
		close OUT;
	}
	warn "# Done GD; ",$self->{x}," ",$self->{y} if $self->{CHAT};
	return 1;
}

#
# METHOD create_imager
#
sub create_imager { my $self=shift;
	warn "# ...with Imager" if $self->{CHAT};
	if (not $self->{object} or ref $self->{object} ne 'Imager'){
		warn "...from file $self->{inputpath}" if $self->{CHAT};
		$self->{object} = Imager->new;
		eval {$self->{object}->read(file => $self->{inputpath})};
		if ($@){
			$self->{error} = $@ if $self->{CHAT};
			return undef;
		}
		if ($self->{object}->errstr){
			$self->{error} = $self->{object}->errstr;
			return undef;
		}
	}

	return undef unless $self->imager_thumb;

	if ($self->{outputpath}){
		warn "Writing to $self->{outputpath}" if $self->{CHAT};
		eval {$self->{object}->write(
            file => $self->{outputpath}, jpegquality=>($self->{quality}||'50')
        )};
		if ($@) {
			$self->{error} = $@ if $self->{CHAT};
			return undef;
        };
	}
	warn "# Done Imager: ",$self->{x}," ",$self->{y} if $self->{CHAT};
	return 1;
}


#
# METHOD create_epeg
#
sub create_epeg { my $self=shift;
	warn "# ...with Image::Epeg" if $self->{CHAT};
	if (not $self->{object} or ref $self->{object} ne 'Image::Epeg'){
		warn "...from file $self->{inputpath}" if $self->{CHAT};
		eval {
			$self->{object} = Image::Epeg->new( $self->{inputpath})
		};
		if ($@){
			$self->{error} = $@ if $self->{CHAT};
			return undef;
		}
	}

	return undef unless $self->epeg_thumb;

	if ($self->{outputpath}){
		warn "Writing to $self->{outputpath}" if $self->{CHAT};
		eval {
			$self->{object}->set_quality( $self->{quality} || 50 );
			$self->{object}->write_file( $self->{outputpath} )
		};
		if ($@) {
			$self->{error} = $@ if $self->{CHAT};
			return undef;
        };
	}
	warn "# Done Image::Epeg: ",$self->{x}," ",$self->{y} if $self->{CHAT};
	return 1;
}

#
# Sets our inputtype field to the file type (jpeg, etc)
# Includes unsupported image types.
#
sub get_img_type { my ($self,$handle)=(shift,shift);
	my $id;
	my $header;			# The first 256 of image
	warn "# Ascertaining file type" if $self->{CHAT};

	if ($self->{inputblob}){
		$header = substr(
			${$self->{inputblob}},
			0,
			length($self->{inputblob})>=255? 255 : length($self->{inputblob})
		);
	} else {
		binmode $handle;
		read IN, $header, 256;
		seek IN,0,0;
	}

	if (not defined $header){
		$self->{error} = "No image header\n";
		return undef;
	}

	my %type_map = (	# Map lifted straight from Image::Size (C) Randy J. Ray, 2002
		'^GIF8[7,9]a'              => "gif",
		"^\xFF\xD8"                => "jpeg",
		"^\x89PNG\x0d\x0a\x1a\x0a" => "png",
		"^P[1-7]"                  => "ppm", # also XVpics
		'\#define\s+\S+\s+\d+'     => "xbm",
		'\/\* XPM \*\/'            => "xpm",
		'^MM\x00\x2a'              => "tiff",
		'^II\x2a\x00'              => "tiff",
		'^BM'                      => "bmp",
		'^8BPS'                    => "psd",
		'^PCD_OPA'                 => "pcd",
		'^FWS'                     => "swf",
		"^\x8aMNG\x0d\x0a\x1a\x0a" => "mng",
	);
	grep {$id=$type_map{$_} if $header=~/$_/  } keys %type_map;

	$self->{inputtype} = $id;
	warn "# File is $id\n" if $self->{CHAT};
	return $id;
}

#
# Thumbnail generation
#
sub gd_thumb { my $self=shift;
	if (not $self->{object}){
		$self->{error} = "No 'object' supplied to make thumbnail from";
		return undef;
	}
	($self->{ox}, $self->{oy}) = $self->{object}->getBounds();
	$self->_size;
	$self->{x} = int( $self->{ox}/$self->{ratio} );
	$self->{y} = int( $self->{oy}/$self->{ratio} );
	my $thumb = GD::Image->new($self->{x}, $self->{y});
	$thumb->copyResized($self->{object},0,0,0,0,
		$self->{x}, $self->{y}, $self->{ox}, $self->{oy});
	return $thumb, sprintf("%.0f",$self->{x}), sprintf("%.0f",$self->{y});
}


sub epeg_thumb { my $self=shift;
	if (not $self->{object}){
		$self->{error} = "No 'object' supplied to make thumbnail from";
		return undef;
	}
	$self->{ox} = $self->{object}->get_width();
	$self->{oy} = $self->{object}->get_height();
	$self->_size;
	$self->{x} = int( $self->{ox}/$self->{ratio} );
	$self->{y} = int( $self->{oy}/$self->{ratio} );
	my $thumb = $self->{object}->resize( $self->{x}, $self->{y});
	return $thumb, sprintf("%.0f",$self->{x}), sprintf("%.0f",$self->{y});
}

sub imagemagick_thumb { my $self=shift;
	if (not $self->{object}){
		$self->{error} = "No 'object' supplied to make thumbnail from";
		return undef;
	}
	($self->{ox}, $self->{oy}) = $self->{object}->Get('width','height');
	if (not $self->{ox} or not $self->{oy}){
		$self->{error} = __PACKAGE__." Could not get width/height from image";
		return undef
	}
	$self->_size;
	$self->{x} = int( $self->{ox}/$self->{ratio} );
	$self->{y} = int( $self->{oy}/$self->{ratio} );

	$self->{object}->Set(type=>'Optimize');
	#$self->{object}->Resize(width=>$self->{x}, height=>$self->{y});
	$self->{object}->Thumbnail(width=>$self->{x}, height=>$self->{y});

	if ($self->{depth}){
		$self->{object}->Set('depth'=>$self->{depth});
	}
	$self->{object}->Comment("http://LeeGoddard.net ".__PACKAGE__." $VERSION");
	$self->{object}->Set('density',$self->{density}||'96x96');
	$self->{object}->Set(quality=>$self->{quality}||'50');
	$self->{object}->Set(type=>'Optimize');
	if ($self->{attr}){
		die "attr must be a hash reference" if ref $self->{attr} ne 'HASH';
		foreach my $key (keys %{$self->{attr}}){
			$self->{object}->Set($key=>$self->{attr}->{$key});
			# Catch errors?
		}
	}
	return 1; # Thanks, Himmy :)
}


sub imager_thumb { 
	my $self=shift;
	if (not $self->{object}){
		$self->{error} = "No 'object' supplied to make thumbnail from";
		return undef;
	}
	$self->{ox} = $self->{object}->getwidth;
    $self->{oy} = $self->{object}->getheight;

	if (not $self->{ox} or not $self->{oy}){
		$self->{error} = __PACKAGE__." Could not get width/height from imager";
		return undef;
	}

	$self->_size;
	$self->{x} = int( $self->{ox}/$self->{ratio} );
	$self->{y} = int( $self->{oy}/$self->{ratio} );

	$self->{object} = $self->{object}->scale(xpixels=>$self->{x},ypixels=>$self->{y},type=>'min');

	return 1;
}


#
# For PerlMagick: Interpret $s for errors and put in warnings/errors field
#
sub set_errors { my ($self,$s) = (shift,shift);
	if ($self->{module} eq 'Image::Magick'){
		if ($s =~ /(\d+)/){
			if ($1 <400){
				$self->{warning}  = $s;
			} else {
				$self->{error} = $s;
			}
		}
	}
}

sub _size { my $self = shift;
	my ($maxx, $maxy);
	if (($maxx, $maxy) = $self->{size} =~ /^(\d+)x(\d+)$/i){
		$self->{size} = ($self->{ox}>$self->{oy})? $maxx : $maxy;
	} else {
		$maxx = $maxy = $self->{size};
	}
	# $self->{ratio} = ($self->{ox} > $self->{oy}) ? ($self->{ox}/$maxx) : ($self->{oy}/$maxy);
	$self->{ratio} = ($self->{ox}/$maxx) > ($self->{oy}/$maxy) ? ($self->{ox}/$maxx) : ($self->{oy}/$maxy);
}

1; # Satisfy 'require'

__END__


=head1 EXPORT

None.

=head1 CHANGES

Please see the file F<CHANGES> included with the distribution.

=head1 SEE ALSO

L<perl>,
L<Image::Epeg>,
L<GD>,
L<Imager>,
L<Image::Magick>,
L<Image::Magick::Thumbnail>,
L<Image::GD::Thumbnail>,
L<Image::Epeg>.

=head1 AUTHOR

Lee Goddard <cpan-at-leegoddard-dot-net>

Thanks to Sam Tregar, Himmy and Chris Laco.

=head1 COPYRIGT

Copyright (C) Lee Godadrd 2001-2005. All rights reserved.
Supplied under the same terms as Perl itself.

=cut

End of File
