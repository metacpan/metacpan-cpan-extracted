package Image::GD::Thumbnail;

our $VERSION = '0.041';
use Carp;
use strict;
use warnings;

=head1 NAME

Image::GD::Thumbnail - produce thumbnail images with GD

=head1 SYNOPSIS

	use GD;
	use Image::GD::Thumbnail;

	# Load your source image
	open IN, 'E:/Images/test.jpg'  or die "Could not open.";
	my $srcImage = GD::Image->newFromJpeg(*IN);
	close IN;

	# Create the thumbnail from it, where the biggest side is 50 px
	my ($thumb,$x,$y) = Image::GD::Thumbnail::create($srcImage,50);


	# Save your thumbnail
	open OUT, ">E:/Images/thumb_test.jpg" or die "Could not save ";
	binmode OUT;
	print OUT $thumb->jpeg;
	close OUT;

  __END__

=head1 DESCRIPTION

This module uses the GD library to create a thumbnail image with no side bigger than you specify.

The subroutine C<create> takes two arguments: the first is a GD image object,
the second is the size, in pixels, you wish the image's longest side to be.
It returns a new GD image object (the thumbnail), as well as the I<x> and I<y>
dimensions, as (integer) scalars.

=head1 PREREQUISITES

	GD

=cut

sub create { my ($orig,$max) = (shift,shift);
	confess "No image supplied" unless $orig;
	confess "No scale factor or geometry" unless $max;

	my ($ox,$oy) = $orig->getBounds();
	my ($maxx, $maxy);
	if (($maxx, $maxy) = $max =~ /^(\d+)x(\d+)$/i){
		$max = ($ox>$oy)? $maxx : $maxy;
	} else {
		$maxx = $maxy = $max;
	}

	# my $r = ($ox>$oy) ? ($ox/$maxx) : ($oy/$maxy);
	  my $r = ($ox/$maxx) > ($oy/$maxy) ? ($ox/$maxx) : ($oy/$maxy);

	my $thumb = GD::Image->new($ox/$r,$oy/$r);
	$thumb->copyResized($orig,0,0,0,0,$ox/$r,$oy/$r,$ox,$oy);
	return $thumb, sprintf("%.0f",$ox/$r), sprintf("%.0f",$oy/$r);
}

1;

__END__

=head2 EXPORT

None by default.

=head1 AUTHOR

Lee Goddard <cpan -at- leegoddard -dot- net>

=head1 SEE ALSO

L<perl>, L<GD>.

=head1 COPYRIGHT

Copyright (C) Lee Godadrd 2001 ff, all rights reserved.
Available under the same terms as Perl itself.

=cut

__END__
