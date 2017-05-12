package Image::Imlib2::Thumbnail;
use strict;
use warnings;
use File::Basename qw(fileparse);
use Image::Imlib2;
use MIME::Types;
use Path::Class;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(sizes));
our $VERSION = '0.40';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->sizes(
        [   {   type   => 'landscape',
                name   => 'square',
                width  => 75,
                height => 75
            },
            {   type   => 'landscape',
                name   => 'thumbnail',
                width  => 100,
                height => 75
            },
            {   type   => 'landscape',
                name   => 'small',
                width  => 240,
                height => 180
            },
            {   type   => 'landscape',
                name   => 'medium',
                width  => 500,
                height => 375
            },
            {   type   => 'landscape',
                name   => 'large',
                width  => 1024,
                height => 768
            },
            {   type   => 'portrait',
                name   => 'square',
                width  => 75,
                height => 75
            },
            {   type   => 'portrait',
                name   => 'thumbnail',
                width  => 75,
                height => 100
            },
            {   type   => 'portrait',
                name   => 'small',
                width  => 180,
                height => 240
            },
            {   type   => 'portrait',
                name   => 'medium',
                width  => 375,
                height => 500
            },
            {   type   => 'portrait',
                name   => 'large',
                width  => 768,
                height => 1024
            },
        ]
    ) unless $self->sizes;
    return $self;
}

sub add_size {
    my ( $self, $size ) = @_;
    push @{ $self->sizes }, $size;
}

sub generate {
    my ( $self, $filename, $directory ) = @_;
    my $image = Image::Imlib2->load($filename);

    my ( $original_width, $original_height )
        = ( $image->width, $image->height );
    my $original_type
        = $original_width > $original_height ? 'landscape' : 'portrait';
    my $original_extension = [ fileparse( $filename, qr/\.[^.]*?$/ ) ]->[2]
        || '.jpg';
    $original_extension =~ s/^\.//;

    my $mime_type = MIME::Types->new->mimeTypeOf($original_extension);

    my @thumbnails = (
        {   filename => $filename,
            name     => 'original',
            width    => $original_width,
            height   => $original_height,
            type     => $original_type,
        }
    );

    foreach my $size ( @{ $self->sizes } ) {
        my ( $name, $width, $height, $type )
            = ( $size->{name}, $size->{width}, $size->{height},
            $size->{type} );
        next unless $type eq $original_type;

        # add quality from the size definition if provided
        my $quality = $size->{quality} || 75;

        my $scaled_image;

        if ( $width && $height ) {
            my ( $new_width, $new_height );
            my $aspect_ratio = $height / $width;
            $new_width  = $original_width;
            $new_height = $original_width * $aspect_ratio;

            if ( $new_height > $original_height ) {
                $new_width  = $original_height / $aspect_ratio;
                $new_height = $original_height;
            }
            my $x = int( ( $original_width - $new_width ) / 2 );
            my $y = int( ( $original_height - $new_height ) / 2 );

            my $cropped_image
                = $image->crop( $x, $y, $new_width, $new_height );
            $scaled_image
                = $cropped_image->create_scaled_image( $width, $height );

        } elsif ($width) {
            $scaled_image = $image->create_scaled_image( $width, 0 );
            $height = $scaled_image->height;
        } else {
            $scaled_image = $image->create_scaled_image( 0, $height );
            $width = $scaled_image->width;
        }

        my $destination
            = file( $directory, $name . '.' . $original_extension )
            ->stringify;
        $scaled_image->set_quality($quality);
        $scaled_image->save($destination);
        push @thumbnails,
            {
            filename  => $destination,
            name      => $name,
            width     => $width,
            height    => $height,
            type      => $type,
            mime_type => $mime_type,
            };
    }
    return @thumbnails;
}

1;

__END__

=head1 NAME

Image::Imlib2::Thumbnail - Generate a set of thumbnails of an image

=head1 SYNOPSIS

  use Image::Imlib2::Thumbnail;
  my $thumbnail = Image::Imlib2::Thumbnail->new();
  
  # generates a set of thumbnails for $source image in $directory
  my @thumbnails = $thumbnail->generate( $source, $directory );
  foreach my $thumbnail (@thumbnails) {
    my $name = $thumbnail->{name};
    my $width = $thumbnail->{width};
    my $height = $thumbnail->{height};
    my $type = $thumbnail->{type};
    my $filename = $thumbnail->{filename};
    my $mime_type = $thumbnail->{mime_type};
    print "$name/$type/$mime_type is $width x $height at $filename\n";
  }

=head1 DESCRIPTION

This module generates a series of thumbnails of an image using
Image::Imlib2. If you want to generate a single thumbnail, you
should look at Image::Imlib2's create_scaled_image method.
    
Digital cameras take photos in many different sizes and aspect
ratios. Photo websites need to display thumbnails of different
sizes of these photos. This module makes it easy to generate
a series of thumbnails of an image of the right sizes. It 
resizes and crops images to match the requires size.
    
What sizes does it generate? By default it generates thumbnails
of the same dimension that Flickr generates:

  Type       Name       Width  Height
  Landscape  Square     75     75
  Landscape  Thumbnail  100    75
  Landscape  Small      240    180
  Landscape  Medium     500    375
  Landscape  Large      1024   768
  Portrait   Square     75     75
  Portrait   Thumbnail  75     100
  Portrait   Small      180    240
  Portrait   Medium     375    500
  Portrait   Large      768    1024

The test suite contains images of every size mentioned on the
Wikipedia "Digital camera" article:

  http://en.wikipedia.org/wiki/Digital_camera#Image_resolution
  
=head1 METHODS

=head2 new

The constructor:

  my $thumbnail = Image::Imlib2::Thumbnail->new();

=head2 generate

Generates a set of thumbnails for $source image in $directory.
Will also include the original image:

  my @thumbnails = $thumbnail->generate( $source, $directory );
  foreach my $thumbnail (@thumbnails) {
    my $name = $thumbnail->{name};
    my $width = $thumbnail->{width};
    my $height = $thumbnail->{height};
    my $type = $thumbnail->{type};
    my $filename = $thumbnail->{filename};
    my $mime_type = $thumbnail->{mime_type};
    print "$name/$type/$mime_type is $width x $height at $filename\n";
  }

=head2 add_size

Add an extra size:

  $thumbnail->add_size(
      {   type    => 'landscape',
          name    => 'header',
          width   => 350,
          height  => 200,
          quality => 80,
      }
  );
  
If width or height are 0, then this retains the aspect ratio and 
performs no cropping.

The quality is the JPEG quality compression ratio. This defaults
to 75.

=head1 AUTHOR

Leon Brocard, acme@astray.com

=head1 COPYRIGHT

Copyright (c) 2007-8 Leon Brocard. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

