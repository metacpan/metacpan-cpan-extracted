package Imager::Filter::ExifOrientation;
use strict;
use warnings;
our $VERSION = '0.01';

use Carp;
use Imager::ExifOrientation;
use Image::ExifTool ();

Imager->register_filter(
    type     => 'exif_orientation',
    callsub  => \&exif_orientation,
    defaults => {
        path        => undef,
        exif        => undef,
        data        => undef,
        orientation => undef,
    },
    callseq  => ['image'],
);

sub exif_orientation {
    my %args = @_;

    my $orientation;

    if ($args{orientation}) {
        $orientation = $args{orientation};
    } else {
        my $exif;
        if ($args{exif}) {
            $exif = $args{exif};
            $orientation = Imager::ExifOrientation->get_orientation_by_exiftool($exif);
        } elsif ($args{data}) {
            $exif = Image::ExifTool::ImageInfo(\$args{data});
            $orientation = Imager::ExifOrientation->get_orientation_by_exiftool($exif);
        } elsif ($args{path}) {
            $exif = Image::ExifTool::ImageInfo($args{path});
            $orientation = Imager::ExifOrientation->get_orientation_by_exiftool($exif);
        } else {
            $orientation = $args{imager}->tags(name => 'exif_orientation');
            return unless defined $orientation; # there is no orientation information
        }
    }

    my $img = Imager::ExifOrientation->_rotate(
        $args{imager}, $orientation
    );

    $args{imager}->{IMG} = $img->{IMG};
}

1;
__END__

=encoding utf8

=head1 NAME

Imager::Filter::ExifOrientation - Imager::ExifOrientation for Imager Filter

=head1 SYNOPSIS

use file path

  use Imager;
  use Imager::Filter::ExifOrientation;

  my $img = Imager->new;
  $img->filter(
      type => 'exif_orientation',
      path => 'foo.jpg',
  );

use jpeg data

  use Imager;
  use Imager::Filter::ExifOrientation;

  my $jpeg_data = do {
      open my $fh, '<', 'foo.jpg';
      local $/;
      <$fh>;
  };
  $img->filter(
      type => 'exif_orientation',
      data => $jpeg_data,
  );

use exif hash

  use Imager;
  use Imager::Filter::ExifOrientation;
  use Image::ExifTool 'ImageInfo';

  my $exif  = ImageInfo('foo.jpg');
  $img->filter(
      type => 'exif_orientation',
      exif => $exif,
  );

use orientation number

  use Imager;
  use Imager::Filter::ExifOrientation;

  $img->filter(
      type        => 'exif_orientation',
      orientation => 1, # or 2..8
  );
  # orientation values
  # 1 => Horizontal (normal)
  # 2 => Mirror horizontal
  # 3 => Rotate 180 (rotate is too noisy)
  # 4 => Mirror vertical
  # 5 => Mirror horizontal and rotate 270 CW
  # 6 => Rotate 90 CW
  # 7 => Mirror horizontal and rotate 90 CW
  # 8 => Rotate 270 CW

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

L<Imager>,
L<Imager::Filter>,
L<Image::ExifTool>,
L<Imager::ExifOrientation>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
