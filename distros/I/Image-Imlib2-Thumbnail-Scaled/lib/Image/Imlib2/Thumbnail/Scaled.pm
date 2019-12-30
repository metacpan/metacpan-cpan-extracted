package Image::Imlib2::Thumbnail::Scaled;

use strict;
use warnings;
use Object::Tiny::RW::XS qw/sizes include_original delete_original original_width original_height move_original/;
use File::Basename qw/fileparse basename dirname/;
use File::Copy qw/move/;
use Image::Imlib2;
use MIME::Types;
use Path::Class;

=head1 NAME

Image::Imlib2::Thumbnail::Scaled - Create scaled thumbnails while keeping the aspect ratio

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

  use Image::Imlib2::Thumbnail::Scaled;
  my $thumbnail = Image::Imlib2::Thumbnail::Scaled->new;

  # generates a set of thumbnails for $source image in $directory
  my $thumbnails = $thumbnail->generate( $source, $directory );

=head1 DESCRIPTION

This module creates a series of thumbnails using L<Image::Imlib2>.

This module is essentially L<Image::Imlib2::Thumbnail>, except it respects the aspect ratio
of the original image when scaling, and there are some minor differences in terms of what
functions take in and return.

It is possible using L<Image::Imlib2::Thumbnail> to keep the aspect ratio of the image, however
you have to decide whether to scale based on height or width, whereas L<Image::Imlib2::Thumbnail::Scaled>
figures this out for you based on the dimensions of the image.

This module by default generates sizes very similar to L<Image::Imlib2::Thumbnail>:

  Name       Width  Height
  Square     75     75
  Thumbnail  100    75
  Small      240    180
  Medium     500    375
  Large      1024   768

=head1 SUBROUTINES/METHODS

=head2 new

  my $thumbnail = Image::Imlib2::Thumbnail::Scaled->new;

Returns a new L<Image::Imlib2::Thumbnail::Scaled> object. Can take in any of the subroutines as options (except L</add_size>). For example:

  my $thumbnail = Image::Imlib2::Thumbnail::Scaled->new(
    sizes => [
               {
                 name => 'my_image',
                 width => 180,
                 height => 180,
               },
               {
                 name => 'my_other_image',
                 width => 240,
                 height => 240,
               }
             ]
  );

  my $thumbnail = Image::Imlib2::Thumbnail::Scaled->new(include_original => 1);

  #or multiple
  my $thumbnail = Image::Imlib2::Thumbnail::Scaled->new(include_original => 1, delete_original => 1);

=cut

sub _set_default_sizes {
	my ($self) = @_;
    $self->sizes(
        [
			{
                name   => 'square',
                width  => 75,
                height => 75
            },
            {
                name   => 'thumbnail',
                width  => 100,
                height => 75
            },
            {
                name   => 'small',
                width  => 240,
                height => 180
            },
            {
                name   => 'medium',
                width  => 500,
                height => 375
            },
            {
                name   => 'large',
                width  => 1024,
                height => 768
            },
        ]
    );
}

=head2 sizes

  my $thumbnail = Image::Imlib2::Thumbnail::Scaled->new(
    sizes => [
               {
                 name => 'my_image',
                 width => 180,
                 height => 180,
               },
               {
                 name => 'my_other_image',
                 width => 240,
                 height => 240,
               }
             ]
  );

L<sizes|/"sizes"> allows you to override the default sizes that are provided.

=head2 include_original

  $thumbnail->include_original(1);

If set to 1, L<generate|/"generate"> will return the original image along with
the created thumbnails in the returned arrayref. Default is false.

=cut

=head2 delete_original

  $thumbnail->delete_original(1);

If set to 1, the original image will be deleted once all resized images are made.
Default is false.

=cut

=head2 move_original

  $thumbnail->move_original(1);

If set to 1, the original image will be moved to the directory that is passed into L</generate> along
with all of the other resized images.
Default is false.

=cut

=head2 add_size

Add an extra size:

  $thumbnail->add_size(
      {
          name    => 'header',
          width   => 350,
          height  => 200,
          quality => 80,
      }
  );

The quality is the JPEG quality compression ratio. This defaults to 75.

=cut

sub add_size {
    my ( $self, $size ) = @_;
    push @{ $self->sizes }, $size;
}

=head2 generate

Returns an arrayref a set of thumbnails for $source image in $directory.
Will include the original image if L<include_original|/"include_original">
is set to 1.

  my $thumbnails = $thumbnail->generate( $source, $directory );
  for my $thumbnail (@$thumbnails) {
    my $name = $thumbnail->{name};
    my $width = $thumbnail->{width};
    my $requested_width = $thumbnail->{requested_width};
    my $height = $thumbnail->{height};
    my $requested_height = $thumbnail->{requested_height};
    my $filename = $thumbnail->{filename};
    my $mime_type = $thumbnail->{mime_type};
    print "$name $mime_type is $width x $height at $filename with requested width $requested_width requested height $requested_height\n";
  }

Since the aspect ratio is kept, width and height will hold the resulting width and height after resizing,
while requested_width and requested_height will hold the width and height that the image was
requested to be resized to.

You can also pass in an optional third argument to L</generate>, which if set to true will return a hash of hashes
for all of the resized images, where the key is the name provided in L</sizes>.

  my $thumbnails = $thumbnail->generate( $source, $directory, 1 );
  while(my ($name, $thumbnail) = each %$thumbnails) {
    my $name = $thumbnail->{name};
    my $width = $thumbnail->{width};
    my $requested_width = $thumbnail->{requested_width};
    my $height = $thumbnail->{height};
    my $requested_height = $thumbnail->{requested_height};
    my $filename = $thumbnail->{filename};
    my $mime_type = $thumbnail->{mime_type};
    print "$name $mime_type is $width x $height at $filename with requested width $requested_width requested height $requested_height\n";
  }

=cut

sub generate {
    my ($self, $filename, $directory, $return_hash) = @_;
    my $image = Image::Imlib2->load($filename);
	my $return_obj;

    my ( $o_width, $o_height )
        = ( $image->width, $image->height );
		$self->original_width($o_width);
		$self->original_height($o_height);
    my $original_extension = [ fileparse( $filename, qr/\.[^.]*?$/ ) ]->[2]
        || '.jpg';
    $original_extension =~ s/^\.//;

    my $mime_type = MIME::Types->new->mimeTypeOf($original_extension);

	if($self->include_original) {
		my $orig_file = {
			filename => $filename,
            name     => 'original',
            width    => $o_width,
            height   => $o_height,
			requested_width => $o_width,
			requested_height => $o_height,
        };

		if($return_hash) {
			$return_obj->{original} = $orig_file;
		}
		else { push @$return_obj, $orig_file }
	}

	#set defaults if they do not exist!
	$self->_set_default_sizes unless $self->sizes;

    foreach my $size ( @{ $self->sizes } ) {
        my ( $name, $width, $height) = ( $size->{name}, $size->{width}, $size->{height} );

        # add quality from the size definition if provided
        my $quality = $size->{quality} || 75;

        my $scaled_image;

				#SCALING CODE
				my ($t_width, $t_height) = ($width,$height);

		 		if ( $o_width * $height - $width * $o_height >= 0 ) {
					$t_height = ( $width / $o_width ) * $o_height;
				}
				else {
					$t_width = ( $height / $o_height ) * $o_width;
				}

				$t_width = int($t_width);
				$t_height = int($t_height);
        $scaled_image = $image->create_scaled_image( $t_width, $t_height );
        my $destination
            = file( $directory, $name . '.' . $original_extension )
            ->stringify;
        $scaled_image->set_quality($quality);
        $scaled_image->save($destination);

		my $resized_image = {
            filename  => $destination,
            name      => $name,
			requested_width => $width,
			requested_height => $height,
            width     => $t_width,
            height    => $t_height,
            mime_type => $mime_type,
        };

		if($return_hash) {
			$return_obj->{$name} = $resized_image;
		}
		else { push @$return_obj, $resized_image }
    }

	if($self->move_original) {
		my $base_filename = basename($filename);
		move($filename, file($directory, $base_filename)->stringify);
	}
	unlink $filename if $self->delete_original;

    return $return_obj;
}

=head2 original_width

  my $original_width = $thumbnail->original_width;

This subroutine returns the width of the original image. (Can only be called after L<generate|/"generate">).

=cut

=head2 original_height

  my $original_height = $thumbnail->original_height;

This subroutine returns the height of the original image. (Can only be called after L<generate|/"generate">).

=cut

=head1 AUTHOR

Adam Hopkins, C<< <srchulo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-imlib2-thumbnail-scaled at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-Imlib2-Thumbnail-Scaled>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::Imlib2::Thumbnail::Scaled


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-Imlib2-Thumbnail-Scaled>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-Imlib2-Thumbnail-Scaled>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-Imlib2-Thumbnail-Scaled>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-Imlib2-Thumbnail-Scaled/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Adam Hopkins.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Image::Imlib2::Thumbnail::Scaled
