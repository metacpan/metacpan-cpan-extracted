package Image::Seek;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( add_image query_id loaddb savedb cleardb
    add_image_imager add_image_imlib2 remove_id) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Image::Seek', $VERSION);



sub add_image {
    my ($image, $id) = @_;
    if (UNIVERSAL::isa($image, "Imager"))        { goto &add_image_imager }
    if (UNIVERSAL::isa($image, "Image::Imlib2")) { goto &add_image_imlib2 }
    if (UNIVERSAL::isa($image, "GD::Image"))     { goto &add_image_gd }
    if (UNIVERSAL::isa($image, "Image::Magick")) { goto &add_image_magick }
    croak "Don't know what sort of image $image is";
}

sub add_image_magick {
    my ($img, $id) = @_;
    #my ($reds, $blues, $greens);

    my ($width,$height) = $img->Get('width', 'height');
    my $thumb;

    if ($width == 128 && $height == 128) {
      $thumb = $img;
    }
    else {
      $thumb = $img->Clone();
      $thumb->Scale('128x128!');
    }

    my @red = $thumb->GetPixels('map' => 'R', 'height' => 128, 'width' =>128, 'normalize' => 1);
    my $reds = join('',(map { chr($_); } @red));
    my @blue = $thumb->GetPixels('map' => 'B', 'height' => 128, 'width' =>128, 'normalize' => 1);
    my $blues = join('',(map { chr($_); } @blue));
    my @green = $thumb->GetPixels('map' => 'G', 'height' => 128, 'width' =>128, 'normalize' => 1);
    my $greens = join('',(map { chr($_); } @green));
    addImage($id, $reds, $greens, $blues);
}

sub add_image_gd {
    my ($img, $id) = @_;
    my ($reds, $blues, $greens);

    my $thumb = new GD::Image(128,128,1);
    $thumb->copyResized($img,0,0,0,0,128,128,$img->width ,$img->height);

    for my $y (0..127) {
        for my $x (0..127) {
            my ($r, $g, $b) = $thumb->rgb($thumb->getPixel($x,$y));
            $reds .= chr($r); $blues .= chr($b); $greens .= chr($g);
        }
    }
    addImage($id, $reds, $greens, $blues);
}

sub add_image_imager {
    my ($img, $id) = @_;
    my ($reds, $blues, $greens);

    my $thumb = $img->scaleX(pixels => 128)->scaleY(pixels => 128);
    for my $y (0..127) {
        my @cols = $thumb->getscanline('y' => $y);
        for (@cols) {
            my ($r, $g, $b) = $_->rgba;
            $reds .= chr($r); $blues .= chr($b); $greens .= chr($g);
        }
    }
    addImage($id, $reds, $greens, $blues);
}

sub add_image_imlib2 {
    my ($img, $id) = @_;
    my ($reds, $blues, $greens);

    my $thumb = $img->create_scaled_image(128,128);
    for my $y (0..127) {
        for my $x (0..127) {
            my ($r, $g, $b,$a) = $thumb->query_pixel($x,$y);
            $reds .= chr($r); $blues .= chr($b); $greens .= chr($g);
        }
    }
    addImage($id, $reds, $greens, $blues);
}

sub query_id {
    my $id = shift;
    my $results = shift || 10;
    queryImgID($id, $results);
    my @r = results();
    my @rv;
    unshift @rv, [shift @r, shift @r] while @r;
    @rv;
}

sub remove_id {
    my $id = shift;
    removeID($id);
}

1;
__END__

=head1 NAME

Image::Seek - A port of ImgSeek to Perl

=begin html

<a href="https://travis-ci.org/wollmers/Image-Seek"><img src="https://travis-ci.org/wollmers/LCS.png" alt="Image-Seek"></a>
<a href='https://coveralls.io/r/wollmers/Image-Seek?branch=master'><img src='https://coveralls.io/repos/wollmers/Image-Seek/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Image-Seek'><img src='http://cpants.cpanauthors.org/dist/Image-Seek.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Image-Seek"><img src="https://badge.fury.io/pl/Image-Seek.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

    use Image::Seek qw(loaddb add_image query_id savedb);

    loaddb("haar.db");

    # EITHER
    my $img = GD::Image->newFromJpeg("photo-216.jpg", 1);

    # OR
    my $img = Imager->new();
    $img->open(file => "photo-216.jpg");

    # OR
    my $img = Image::Imlib2->load("photo-216.jpg");

    # Then...
    add_image($img, 216);
    savedb("haar.db");

    my @results = query_id(216); # What looks like this photo?

    remove_id(216); # Just remove id from database.

=head1 DESCRIPTION

ImgSeek (http://www.imgseek.net/) is an implementation of Haar wavelet
decomposition techniques to find similar pictures in a library. This
module is port of the ImgSeek library to Perl's XS. It can deal with
image objects produced by the C<Imager>, C<Image::Imlib2> and C<GD> libraries.

=head1 EXPORT

None by default, but the following functions are available:

=head2 savedb($file)

Dumps the state of the norms and image buckets to the file C<$file>.

=head2 loaddb($file)

Loads a database of image norms produced by savedb

=head2 cleardb

Clears the internal database. Note that C<loaddb> will load into memory
a bunch of data that you may already have - it will duplicate rather
than replace this data, so results will be skewed if you load a database
multiple times without clearing it in between.

=head2 add_image($image, $id)

Adds the image object to the database, keyed against the numeric id
C<$id>. This will compute the Haar transformation for a 128x128
thumbnail of the image, and then store its norms into a database in
memory.

=head2 remove_id($id)

remove id from database, and you should C<savedb> to save the changed database.

=head2 query_id($id[, $results))

This queries the internal database for pictures which are "like" number
C<$id>. It returns a list of C<$results> results (by default, 10);
a result is an array reference. The first element is the ID of a
picture, the second is a score. So for example:

    query_id(2481, 5)

returns, in a shoot I have, the following:

          [ 2481, -38.3800003528595 ],
          [ 2480, -37.5519620793145 ],
          [ 2478, -37.39896965962   ],
          [ 2479, -37.2777427507208 ],
          [ 2584, -10.0803730081134 ],
          [ 2795, -7.89326129961427 ]

Notice that the scores go the opposite way to what you might imagine:
lower is better. The results come out sorted, and the first result is
the thing you queried for.

=head2 addImage($id, $reds, $greens, $blues)

Internally used.

=head2 add_image_magick($image, $id)

Internally used.

=head2 add_image_gd($image, $id)

Internally used.

=head2 add_image_imager($image, $id)

Internally used.

=head2 add_image_imlib2($image, $id)

Internally used.

=head2 constant

Internally used.

=head2 queryImgID

Internally used.

=head2 removeID

Internally used.

=head2 results

Internally used.

=head1 SEE ALSO

http://www.imgseek.net/

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Image-Seek>

=head1 MAINTAINER

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.org<gt>
Lilo Huang, E<lt>kenwu@cpan.orgE<gt>
Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

All the clever bits were written by Ricardo Niederberger Cabral; Simon Cozens just
mangled them to wrap Perl around them.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Simon Cozens, 2008 by Lilo Huang, 2015 Helmut Wollmersdorfer

This library is free software; as it is a derivative work of imgseek,
this library is distributed under the same terms (GPL) as imgseek.

=cut
