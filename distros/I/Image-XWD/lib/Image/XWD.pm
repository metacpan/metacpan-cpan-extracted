package Image::XWD;

#
# Based on /usr/include/X11/XWDFile.h
#

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = ();
our @EXPORT = ();

our $VERSION = '0.01';

use constant XWD_FILE_VERSION           => 7;
use constant SIZEOF_XWD_HEADER          => 25*4;

use constant XWD_PIXMAP_FORMAT_XYPIXMAP => 1;
use constant XWD_PIXMAP_FORMAT_ZPIXMAP  => 2;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	return $self->init(@_);
}

sub init {
	my $self = shift;
	my %args = @_;

	return $self;
}

sub read_file($$) {
	my $self = shift;
	my ($fname) = @_;

	my ($raw_data);

	my ($header_size);
	my ($file_version);
	my ($pixmap_format);
	my ($pixmap_depth);
	my ($pixmap_width);
	my ($pixmap_heigth);
	my ($xoffset);
	my ($byte_order);
	my ($bitmap_unit);
	my ($bitmap_bit_order);
	my ($bitmap_pad);
	my ($bits_per_pixel);
	my ($bytes_per_line);
	my ($visual_class);
	my ($red_mask);
	my ($green_mask);
	my ($blue_mask);
	my ($bits_per_rgb);
	my ($colormap_entries);
	my ($ncolors);
	my ($window_width);
	my ($window_heigth);
	my ($window_x);
	my ($window_y);
	my ($window_bdrwidth);
	my ($window_name);

	open(F, "<$fname") or return undef;

	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                      $atime,$mtime,$ctime,$blksize,$blocks)
                          = stat(F);

	print("file size is: $size bytes\n");

	# read the first element of the XWDHeader
	read(F, $header_size, 4);
	$header_size = unpack('N', $header_size);
	print("XWDFileHeader.header_size=$header_size\n");

	if ($header_size < SIZEOF_XWD_HEADER) {
		
	}

	# read the rest of the XWDHeader
	read(F, $raw_data, SIZEOF_XWD_HEADER-4);
	
	($file_version,
	 $pixmap_format,
	 $pixmap_depth,
	 $pixmap_width,
	 $pixmap_heigth,
	 $xoffset,
	 $byte_order,
	 $bitmap_unit,
	 $bitmap_bit_order,
	 $bitmap_pad,
	 $bits_per_pixel,
	 $bytes_per_line,
	 $visual_class,
	 $red_mask,
	 $green_mask,
	 $blue_mask,
	 $bits_per_rgb,
	 $colormap_entries,
	 $ncolors,
	 $window_width,
	 $window_heigth,
	 $window_x,
	 $window_y,
	 $window_bdrwidth) = unpack('N'.SIZEOF_XWD_HEADER, $raw_data);

	if ($file_version != XWD_FILE_VERSION) {
		printf(STDERR __PACKAGE__.": Unknown file_version: 0x%8.8X\n", $file_version);
		close(F);
		return undef;
	}
	if ($pixmap_format == XWD_PIXMAP_FORMAT_XYPIXMAP) {
		printf(STDERR __PACKAGE__.": pixmap_format=XYPixmap is not supported, yet. Sorry.\n");
		close(F);
		return undef;

	} elsif ($pixmap_format == XWD_PIXMAP_FORMAT_ZPIXMAP) {
		if ($pixmap_depth != 24) {
			printf(STDERR __PACKAGE__.": Only pixmap_depth=24 is supported, sorry. (pixmap_depth=$pixmap_depth)\n");
			close(F);
			return undef;
		}
		if ($byte_order != 0 && $byte_order != 1) {
			printf(STDERR __PACKAGE__.": Only byte_order=0 is supported, sorry. (byte_order=$byte_order)\n");
			close(F);
			return undef;
		}
		if ($bitmap_unit != 32) {
			printf(STDERR __PACKAGE__.": Only bitmap_unit=32 is supported, sorry. (bitmap_unit=$bitmap_unit)\n");
			close(F);
			return undef;
		}
		if ($bitmap_bit_order != 0 && $bitmap_bit_order != 1) {
			printf(STDERR __PACKAGE__.": Only bitmap_bit_order={0,1} is supported, sorry. (bitmap_bit_order=$bitmap_bit_order)\n");
			close(F);
			return undef;
		}
		if ($bitmap_pad != 32) {
			printf(STDERR __PACKAGE__.": Only bitmap_pad=32 is supported, sorry. (bitmap_pad=$bitmap_pad)\n");
			close(F);
			return undef;
		}
		if ($bits_per_pixel != 24 && $bits_per_pixel != 32) {
			printf(STDERR __PACKAGE__.": Only bits_per_pixel={24,32} is supported, sorry. (bits_per_pixel=$bits_per_pixel)\n");
			close(F);
			return undef;
		}
		if ($visual_class != 4 && $visual_class != 5) {
			printf(STDERR __PACKAGE__.": Only visual_class={4,5} is supported, sorry. (visual_class=$visual_class)\n");
			close(F);
			return undef;
		}
		if ($red_mask != 0x00FF0000) {
			printf(STDERR __PACKAGE__.": Only red_mask=0x00FF0000 is supported, sorry. (red_mask=%8.8X)\n", $red_mask);
			close(F);
			return undef;
		}
		if ($green_mask != 0x0000FF00) {
			printf(STDERR __PACKAGE__.": Only green_mask=0x0000FF00 is supported, sorry. (green_mask=%8.8X)\n", $green_mask);
			close(F);
			return undef;
		}
		if ($blue_mask != 0x000000FF) {
			printf(STDERR __PACKAGE__.": Only blue_mask=0x000000FF is supported, sorry. (blue_mask=%8.8X)\n", $blue_mask);
			close(F);
			return undef;
		}
		if ($bits_per_rgb != 8) {
			printf(STDERR __PACKAGE__.": Only bits_per_rgb=8 is supported, sorry. (bits_per_rgb=$bits_per_rgb)\n");
			close(F);
			return undef;
		}

	} else {
		printf(STDERR __PACKAGE__.": Unknown pixmap_format: 0x%8.8X\n", $pixmap_format);
		close(F);
		return undef; 		
	}

	$self->{'file_version'} = $file_version;
	$self->{'pixmap_format'} = $pixmap_format;
	$self->{'pixmap_depth'} = $pixmap_depth;
	$self->{'pixmap_width'} = $pixmap_width;
	$self->{'pixmap_heigth'} = $pixmap_heigth;
	$self->{'xoffset'} = $xoffset;
	$self->{'byte_order'} = $byte_order;
	$self->{'bitmap_unit'} = $bitmap_unit;
	$self->{'bitmap_bit_order'} = $bitmap_bit_order;
	$self->{'bitmap_pad'} = $bitmap_pad;
	$self->{'bits_per_pixel'} = $bits_per_pixel;
	$self->{'bytes_per_line'} = $bytes_per_line;
	$self->{'visual_class'} = $visual_class;
	$self->{'red_mask'} = $red_mask;
	$self->{'green_mask'} = $green_mask;
	$self->{'blue_mask'} =  $blue_mask;
	$self->{'bits_per_rgb'} = $bits_per_rgb;
	$self->{'colormap_entries'} = $colormap_entries;
	$self->{'ncolors'} = $ncolors;
	$self->{'window_width'} = $window_width;
	$self->{'window_heigth'} = $window_heigth;
	$self->{'window_x'} = $window_x;
	$self->{'window_y'} = $window_y;
	$self->{'window_bdrwidth'} = $window_bdrwidth;

	if (0 < $header_size - SIZEOF_XWD_HEADER) {
		# read window_name
		read(F, $raw_data, $header_size - SIZEOF_XWD_HEADER);
		$window_name = unpack('Z*', $raw_data);
	} else {
		# No window_name
		$window_name = undef;
	}

	$self->{'window_name'} = $window_name;

	my (@colors);
	my ($pixel);
	my ($red);
	my ($green);
	my ($blue);
	my ($flags);
	my ($pad);
	my ($i);

	for ($i=0; $i<$ncolors; $i++) {
		# read one XWDColor structure
		read(F, $raw_data, 12);
		($pixel,
		 $red,
		 $green,
		 $blue,
		 $flags,
		 $pad) = unpack("NnnnCC", $raw_data);

		$self->{"colors[$i]"} = { 'pixel' => $pixel,
		 		 'red' => $red,
				 'green' => $green,
				 'blue' => $blue,
				 'flags' => $flags,
				 'pad' => $pad
			       };
		
	}

	my (@row);
	my ($x, $y);
	my ($r, $g, $b);
	my (%pixel_code);
	for ($y=0; $y<$pixmap_heigth; $y++) {
		# read one complete line at once
		read(F, $raw_data, $bytes_per_line);

		# store the raw data to save memory
		push(@{$self->{"pixel"}}, $raw_data);
	}

	close(F);

	return 1;
}

sub get_width($) {
	my ($self) = shift;

	return $self->{'pixmap_width'};
}

sub get_heigth($) {
	my ($self) = shift;
	
	return $self->{'pixmap_heigth'};
}

sub get_window_name($) {
	my ($self) = shift;

	return $self->{'window_name'};
}

sub xy_rgb($$$) {
	my ($self) = shift;
	my ($x, $y) = @_;
	my ($pixel);
	my ($r, $g, $b);

	if ($self->{'bitmap_bit_order'} == 1 &&
	    $self->{'bits_per_pixel'} == 24 &&
	    $self->{'red_mask'}   == 0x00FF0000 &&
	    $self->{'green_mask'} == 0x0000FF00 &&
	    $self->{'blue_mask'}  == 0x000000FF
	   ) {
		($r, $g, $b) = unpack('C*',
			substr($self->{"pixel"}->[$y], $x * ($self->{'bits_per_pixel'}/8),
			       $self->{'bits_per_pixel'}/8))

	} elsif ($self->{'bitmap_bit_order'} == 0 &&
	    $self->{'bits_per_pixel'} == 32 &&
	    $self->{'red_mask'}   == 0x00FF0000 &&
	    $self->{'green_mask'} == 0x0000FF00 &&
	    $self->{'blue_mask'}  == 0x000000FF) {

		my ($dummy);

		($r, $g, $b, $dummy) = unpack('C*',
			substr($self->{"pixel"}->[$y], $x * ($self->{'bits_per_pixel'}/8),
			       $self->{'bits_per_pixel'}/8))

	} else {
		print(STDERR __PACKAGE__.": Image format not supported, sorry.\n");
	}

	return ($r, $g, $b);
}

END {
  # Cleanup code
}

1;
__END__

=head1 NAME

Image::XWD - X Window Dump image reader

=head1 SYNOPSIS

  use Image::XWD;

  my $img = new Image::XWD;
  $img->read_file('foo.xwd');
  my $window_name = $img->get_window_name(); # get the window name saved by xwd(1)
  my ($r,$g,$b) = $img->xy_rgb(100,200);     # get pixel at (100,200)

=head1 DESCRIPTION

Image::XWD can be used to read the screenshot created by xwd(1).

=head1 METHODS

=over

=item $img = new Image::XWD();

Constructs a new C<Image::XWD> object.

=item $img->read_file($filename);

Reads the given filename to the memory. Specify '-' as filename to read from stdin.

=item $img->get_width();

Returns the width of the image in pixels.

=item $img->get_heigth();

Returns the heigth of the image in pixels.

=item $img->get_window_name();

Returns the window name saved by xwd(1). If the image contains no window name
undef is returned. (Note that this differs from emty string as window name.)

=item $img->xy_rgb($x, $y)

Get the color of the pixel in RGB. The upper left corner is (0, 0) and the
lower right corner is ($img->get_width()-1, $img->get_heigth()-1).

=back

=head1 SEE ALSO

xwd(1), xwud(1), gimp(1), /usr/include/X11/XWDFile.h

=head1 AUTHOR

Márton Németh, E<lt>nm127@freemail.huE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Márton Németh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
