package Image::Magick::Square;
use Carp;
use vars qw($VERSION);
use strict;
use warnings;
$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;


sub import {
   *{Image::Magick::Trim2Square} = \&create;
}


# Image Magick Square
# square an image, chop as needed
sub create {
	my $img = shift; # takes image magick object read into
	if (not $img) {
		warn "no image defined..".__PACKAGE__;
		return undef;
	} 

	my ($x,$y) = $img->Get('width','height');

	# if width and height are same, then this image is already square.
	if ($x == $y) { return $img, $x; }  

	# what is the smallest side of the image?
	# we take that to be the height and width
	# of the largest square we can fit in the image.
	# save that value as $cropby
	
	my $cropby= undef; 
	if ($x > $y) { 
		$cropby = $y;
		$x =int(($x - $cropby )/2);
		$y = 0;		
	} 

	else { 
		$cropby = $x ;
		$y =int(($y - $cropby )/2);
		$x = 0;	
	}
	
	$img->Crop( width=>$cropby, height=>$cropby, x=>$x, y => $y);

	return $img, $cropby;

}

1;

__END__

=pod

=head1 NAME

Image::Magick::Square - Takes image and crops trims to a square shape

=head1 SYNOPSIS

   use Image::Magick;
	use Image::Magick::Square;	

   # instance and read in image
	my $src = new Image::Magick;
	$src->Read('source.jpg');

   # square it
	my $square = Image::Magick::Square::create($src);

	# Save it 
	$square->Write('square.jpg');


   use Image::Magick;
   use Image::Magick::Square;

   my $i = new Image::Magick;
   $i->Read('./my.jpg');
   $i->Trim2Square;
   $i->Write('./squared.jpg');

=head1 EXAMPLE

To make a square thumbnail:

	use Image::Magick::Square;
	
	# Load your source image
	my $src = new Image::Magick;
	$src->Read('source.jpg');

	# resize it down some..
	my ($thumb,$x,$y) = Image::Magick::Thumbnail::create($src,50);

	# crop to biggest square that will fit inside image.
	my ($square_thumb,$side) = Image::Magick::Square::create($thumb);

	# Save it 
	$square_thumb->Write('square_thumb.jpg');


=head1 DESCRIPTION

The subroutine create() takes as argument an ImageMagick image object.

It returns an ImageMagick image object (the thumbnail), as well as the
number of pixels of the I<side> of the image.

It does not take dimension arguments, because if your image is cropped
according to the dimensions it already posseses.

This module is useful if you want to make square thumbnails. You should
first make the thumbnail, and then call create(), so as to use less of
the computer's resources. 

You can run this conversion on any image magick object. 

The subroutine is not exported.

A method is aliased onto Image::Magick::Trim2Square

=head1 SUBS

=head2 Image::Magick::Square::create()

Argument is Image::Magick object.
Trims top and bottom or sides as needed to make it into a square shape.
Returns object.

=head2 Trim2Square()

Is an alias for Image::Magick::Square::create(), it is placed inside the 
Image::Magick namespace. 

=head1 PREREQUISITES

L<Image::Magick>

=head2 NOTES

Yes, L<Image::Magick::Thumbnail::Fixed> will make a fixed size thumbnail.
It's great, I love it. Except for one thing, it does not take an existing
Image::Magick object to work on. It does too much.  It doesn't return an
image object either.

Image::Magick::Square is more a specialized crop then a 
"thumbnail subroutine".
This way, you can add more effects, like a shadow, a border, annotate- etc, 
I<before> you save or display the image.

=cut

=head2 EXPORT

This basically adds a new method to Image::Magick.

   use Image::Magick;
   use Image::Magick::Square;
   
   my $i = new Image::Magick;
   $i->Read('./my.jpg');
   $i->Trim2Square;

If you wish to avoid importing Trim2Square onto the Image::Magick namespace..

   use Image::Magick::Square();


=head1 SEE ALSO

L<perl>, L<Image::Magick>, L<Image::GD::Thumbnail>, 
L<Image::Magick::Thumbnail>, L<Image::Magick::Thumbnail::Fixed>.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (C) Leo Charre 2006-2008 all rights reserved.
Available under the same terms as Perl itself.

=cut

