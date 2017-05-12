package Imager::ExifOrientation;
use strict;
use warnings;
our $VERSION = '0.07';

use Carp;
use Imager;
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::Exif;

my $orientation_revers = {};
while (my($k, $v) = each %Image::ExifTool::Exif::orientation) {
    $orientation_revers->{$v} = $k;
}

sub rotate {
    my($class, %opts) = @_;

    my $img = Imager->new;
    my $exif;
    if ($opts{data}) {
        $exif = ImageInfo(\$opts{data});
        $img->read( data => $opts{data}, type => 'jpeg' );
    } elsif ($opts{path}) {
        $exif = ImageInfo($opts{path});
        $img->read( file => $opts{path}, type => 'jpeg' );
    } else {
        croak "usage:
    Imager::ExifOrientation->rotate( path => '/foo/bar/baz.jpg' )
    Imager::ExifOrientation->rotate( data => \$jpeg_data )
";
    }

    my $orientation = $class->get_orientation_by_exiftool($exif || {});
    $class->_rotate($img, $orientation);
}

sub get_orientation_by_exiftool {
    my($class, $exif) = @_;
    return 1 unless $exif->{Orientation};
    return $orientation_revers->{$exif->{Orientation}} || 1;
}

my $rotate_maps = {
    1 => { right => 0,   mirror => undef }, # Horizontal (normal)
    2 => { right => 0,   mirror => 'h'   }, # Mirror horizontal
    3 => { right => 0,   mirror => 'hv'  }, # Rotate 180 (rotate is too noisy)
    4 => { right => 0,   mirror => 'v'   }, # Mirror vertical
    5 => { right => 270, mirror => 'h'   }, # Mirror horizontal and rotate 270 CW
    6 => { right => 90,  mirror => undef }, # Rotate 90 CW
    7 => { right => 90,  mirror => 'h'   }, # Mirror horizontal and rotate 90 CW
    8 => { right => 270, mirror => undef }, # Rotate 270 CW
};

sub _rotate {
    my($class, $img, $orientation) = @_;
    my $map = $rotate_maps->{$orientation};

    if ($map->{mirror}) {
        $img->flip( dir => $map->{mirror} );
    }

    if ($map->{right}) {
        return $img->rotate( right => $map->{right} );
    }

    $img;
}

1;
__END__

=head1 NAME

Imager::ExifOrientation - A picture is rotated using Orientation of Exif

=head1 SYNOPSIS

  use Imager::ExifOrientation;

  # rotate by original image
  my $image = Imager::ExifOrientation->rotate(
      file => 'foo.jpg'
  );

  # rotate by original image data
  my $data = do {
      open my $fh, '<', 'foo.jpg';
      local $/;
      <$fh>;
  };
  my $image = Imager::ExifOrientation->rotate(
      data => $data
  );

=head1 DESCRIPTION

Imager::ExifOrientation is a picture is rotated based on the information on Exif.

rotate method rotates based on an original jpeg picture.
It is rotated to L<Imager> object by using Filter.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

L<Imager>,
L<Image::ExifTool>,
L<Imager::Filter::ExifOrientation>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
