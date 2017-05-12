package Image::Imlib2::Thumbnail::S3;
use strict;
use warnings;
use File::Temp;
use Image::Imlib2::Thumbnail;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(bucket key_prefix thumbnail));
our $VERSION = '0.31';

sub generate {
    my ( $self, $filename, $key_prefix ) = @_;
    my $thumbnail  = $self->thumbnail;
    my $bucket     = $self->bucket;
    my $s3         = $bucket->account;
    my $temp_dir   = File::Temp->newdir();
    my @thumbnails = $thumbnail->generate( $filename, $temp_dir );
    foreach my $thumbnail (@thumbnails) {
        my $filename = $thumbnail->{filename};
        my $key      = $key_prefix . '/' . $thumbnail->{name} . '.jpg';
        $thumbnail->{key} = $key;
        $thumbnail->{url}
            = 'http://s3.amazonaws.com/' . $bucket->bucket . '/' . $key;
        $bucket->add_key_filename( $key, $filename,
            { content_type => 'image/jpeg', },
        ) or die $s3->err . ": " . $s3->errstr;
        if ( $thumbnail->{name} ne 'original' ) {
            $bucket->set_acl(
                {   key       => $key,
                    acl_short => 'public-read',
                }
            ) || die $s3->err . ": " . $s3->errstr;
            delete $thumbnail->{filename};
        }
    }
    return @thumbnails;
}

1;

__END__

=head1 NAME

Image::Imlib2::Thumbnail::S3 - Generate thumbnails of an image into S3

=head1 SYNOPSIS

  use Image::Imlib2::Thumbnail;
  use Image::Imlib2::Thumbnail::S3;
  use Net::Amazon::S3;

  my $thumbnail = Image::Imlib2::Thumbnail->new;
  # add extra sizes if necessary
  $thumbnail->add_size(
      {   type   => 'landscape',
          name   => 'header',
          width  => 350,
          height => 200
      }
  );

  my $aws_access_key_id     = 'fill me in ';
  my $aws_secret_access_key = 'fill me in too';

  my $s3 = Net::Amazon::S3->new(
      {   aws_access_key_id     => $aws_access_key_id,
          aws_secret_access_key => $aws_secret_access_key,
      }
  );
  
  # create a bucket...
  my $bucket = $s3->add_bucket( { bucket => 'image_imlib2_thumbnail_s3' } )
      or die $s3->err . ": " . $s3->errstr;
  # ... or use an existing one:
  my $bucket = $s3->bucket('image_imlib2_thumbnail_s3');
  
  my $thumbnail_s3 = Image::Imlib2::Thumbnail::S3->new(
      {   thumbnail => $thumbnail,
          bucket    => $bucket,
      }
  );

  my @thumbnails = $thumbnail_s3->generate( 'photo.jpg', 'thumbnails/4' );
  foreach my $thumbnail (@thumbnails) {
      my $name   = $thumbnail->{name};
      my $width  = $thumbnail->{width};
      my $height = $thumbnail->{height};
      my $type   = $thumbnail->{type};
      my $key    = $thumbnail->{key};
      my $url    = $thumbnail->{url};
      print "$name/$type is $width x $height at $url ($key)\n";
  }

=head1 DESCRIPTION

This module generates a set of thumbnails of an image and stores them
in Amazon S3.
    
Digital cameras take photos in many different sizes and aspect
ratios. Photo websites need to display thumbnails of different
sizes of these photos. This module makes it easy to generate
a series of thumbnails of an image of the right sizes. It 
resizes and crops images to match the requires size and uploads
them to Amazon's Simple Storage Service.
    
What sizes does it generate? By default it generates thumbnails
of the same dimension that Flickr generates. See 
L<Image::Imlib2::Thumbnail>.

It makes the thumbnails publically-readable and uploads the 
original photo but keeps that private.
    
=head1 METHODS

=head1 new

The constructor. Takes an L<Image::Imlib2::Thumbnail> object and a
L<Net::Amazon::S3::Bucket> object.

  my $thumbnail_s3 = Image::Imlib2::Thumbnail::S3->new(
      {   thumbnail => $thumbnail,
          bucket    => $bucket,
      }
  );

=head2 generate

Generates a set of thumbnails for the image and stores them in S3.
It makes the thumbnails publically-readable and uploads the 
original photo but keeps that private. You pass in a filename and 
a key prefix. For example, with the code below the URLs will be:

  http://s3.amazonaws.com/image_imlib2_thumbnail_s3/thumbnails/4/original.jpg
  http://s3.amazonaws.com/image_imlib2_thumbnail_s3/thumbnails/4/square.jpg
  http://s3.amazonaws.com/image_imlib2_thumbnail_s3/thumbnails/4/thumbnail.jpg
  http://s3.amazonaws.com/image_imlib2_thumbnail_s3/thumbnails/4/small.jpg
  http://s3.amazonaws.com/image_imlib2_thumbnail_s3/thumbnails/4/medium.jpg
  http://s3.amazonaws.com/image_imlib2_thumbnail_s3/thumbnails/4/large.jpg
  http://s3.amazonaws.com/image_imlib2_thumbnail_s3/thumbnails/4/header.jpg

  my @thumbnails = $thumbnail_s3->generate( 'photo.jpg', 'thumbnails/4' );
  foreach my $thumbnail (@thumbnails) {
      my $name   = $thumbnail->{name};
      my $width  = $thumbnail->{width};
      my $height = $thumbnail->{height};
      my $type   = $thumbnail->{type};
      my $key    = $thumbnail->{key};
      my $url    = $thumbnail->{url};
      print "$name/$type is $width x $height at $url ($key)\n";
  }

=head1 AUTHOR

Leon Brocard, acme@astray.com

=head1 COPYRIGHT

Copyright (c) 2007 Leon Brocard. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

