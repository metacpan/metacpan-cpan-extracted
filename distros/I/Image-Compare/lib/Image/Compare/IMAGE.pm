package Image::Compare::IMAGE;

use warnings;
use strict;

use Imager ':handy';
use Imager::Fountain;

use base qw/Image::Compare::Comparator/;

use constant FILL_IMAGE_CACHE => {};
use constant FILL_IMAGE_WIDTH => 1000;
use constant DEFAULT_COLOR_FOUNTAIN => Imager::Fountain->simple(
	positions => [          0.0,           0.5,           1.0],
	colors    => [NC(255, 0, 0), NC(0, 255, 0), NC(0, 0, 255)],
);
use constant DEFAULT_GREYSCALE_FOUNTAIN => Imager::Fountain->simple(
	positions => [        0.0,               1.0],
	colors    => [NC(0, 0, 0), NC(255, 255, 255)],
);

sub setup {
	my $self = shift;
	$self->SUPER::setup(@_);
	$self->{count} = 0;
	$self->{img} = Imager->new(
		xsize => $_[0]->getwidth(),
		ysize => $_[0]->getheight(),
	);
	# Now we build up our fill image; this is a 1000 x 1 image that is filled
	# using an Imager fountain.  We'll pull pixels from it to put colors into
	# the generated image.
	my $fountain;
	if ($self->{args}) {
		# If there's an argument, it's either a fountain, or it's telling us to use
		# the default color fountain.
		if (ref $self->{args} && $self->{args}->isa('Imager::Fountain')) {
			$fountain = $self->{args};
		}
		else {
			$fountain = DEFAULT_COLOR_FOUNTAIN();
		}
	}
	else {
		# In this case, we use the default greyscale fountain.
		$fountain = DEFAULT_GREYSCALE_FOUNTAIN();
	}
	# Using an object as a hash key stringifies it to its memory location and
	# uses that.  This is suboptimal, but the Imager::Fountain class has no
	# "to_string", so we make do.
	unless (FILL_IMAGE_CACHE()->{$fountain}) {
		my $image = Imager->new(xsize => FILL_IMAGE_WIDTH(), ysize => 1);
		$image->filter(
			type => 'fountain',         segments => $fountain,
			xa   => 0,                  ya       => 0,
			xb   => FILL_IMAGE_WIDTH(), yb       => 0,
		);
		FILL_IMAGE_CACHE()->{$fountain} = $image;
	}
	$self->{fill_image} = FILL_IMAGE_CACHE()->{$fountain};
}

sub accumulate {
	my $self = shift;
	my($pix1, $pix2, $x, $y) = @_;
	my $diff = $self->color_distance($pix1, $pix2);
	# We want to convert from our range of values for $diff (0 .. 441.7) to
	# the range of values of our fill image, which is defined by a constant.
	$diff *= FILL_IMAGE_WIDTH();
	$diff /= 441.7;
	my $color = $self->{fill_image}->getpixel(
		x => $diff,
		y => 0,
	);
	$self->{img}->setpixel(
		x     => $x,
		y     => $y,
		color => $color,
	);
	return undef;
}

sub get_result {
	my $self = shift;
	return $self->{img};
}

1;

__END__

=head1 NAME

Image::Compare::IMAGE - Compares two images and creates a third image
representing their differences.

=head1 OVERVIEW

See the docs for L<Image::Compare> for details on how to use this
module.  Further documentation is meant for those modifying or subclassing
this comparator.  See the documentation in L<Image::Compare::Comparator> for
general information about making your own comparator subclasses.

=head1 METHODS

=over 4

=item setup($image1, $image2)

Sets up the image which will be used to store the differential data.

=item accumulate(\@pixel1, \@pixel2, $x, $y)

This method is called for each pixel in the two images to be compared.  The
difference between each pair of pictures is saved as color data in the
internal picture representation.  This method never short-circuits; when
this comparator is used, all pixels are compared, every time.

=item get_result()

Returns the internal image.

=back

=head1 AUTHOR

Copyright 2008 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
