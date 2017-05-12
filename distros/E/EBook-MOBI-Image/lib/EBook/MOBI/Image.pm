package EBook::MOBI::Image;

our $VERSION = 0.16;

use strict;
use warnings;

use Image::Imlib2;
use File::Temp qw( tempfile );

# Constructor of this class
sub new {
    my $self=shift;
    my $ref={
                # According to
                # http://kindleformatting.com/formatting.php
                # this values are best for images
                max_width => 520,
                max_height => 622,
            };

    bless($ref, $self);

    return $ref;
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_; 

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    
    &{$ref_to_debug_sub}('DEBUG mode on');

    $self->_debug('Tests with PNG on the Kindle-Reader failed. So all pictures get converted to JPG!');
}

sub debug_off {
    my ($self) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}('DEBUG mode off');
        $self->{ref_to_debug_sub} = 0;
    }
}

# Internal debug method
sub _debug {
    my ($self,$msg) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}($msg);
    }   
}

sub rescale_dimensions {
    my ($self, $image_path) = @_;

    # Prepare for work...
    my $image = Image::Imlib2->load($image_path);

    # determine the size of the image
    my $width = $image->width();
    my $height= $image->height();

    # write in tempfile, so that we don't destroy the original image
    my ($fh, $outfilename) = tempfile(UNLINK => 1, SUFFIX => '.jpg');

    # Only resize the image if it is bigger than max
    if ($width > $self->{max_width} or $height > $self->{max_height}) {

        #copy ($image_path, $outfilename);
        $self->_debug(  "Image $image_path is of size $width"."x$height"
                      . " - resizing to $self->{max_width}"
                      . "x$self->{max_height}, renaming to $outfilename"
                      );

        # Resize the image... proportions will stay the same
        my $resized;
        if ($width / $height > 0.8260) { # 520/622=0.8260
            $resized = $image->create_scaled_image($self->{max_width}, 0);
        }
        else {
            $resized = $image->create_scaled_image(0, $self->{max_height});
        }

        # Write the file as JPG
        $resized->save($outfilename);

        # this is so that return returns the right value
        $image_path = $outfilename;
    }
    
    # If the file is below max width/height we dont to anything
    # NOPE: We do convert to JPG, because PNG fails on Kindle
    else {
        $self->_debug(
          "Image $image_path is of size $width"."x$height - no resizing."
        );

        # BUG: Seems like Kindle Reader can't display PNG in my tests...
        # SO I CONVERT EVERYTHING TO JPEG
        $image->save($outfilename);

        # this is so that return returns the right value
        $image_path = $outfilename;
    }

    # return path of the picture with the valid size
    return $image_path;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Image - Make sure that pictures cope with the MOBI standards.

This module was separated from the main code to reduce dependencies.
If you need to process images in your ebook data, just install this module additionally to C<EBook::MOBI> (from C<v0.56> or higher) and it should work.

=head1 SYNOPSIS

This example is for developers only.
Normal users just need to install this module, C<EBook::MOBI> will detect automatically that the module is there and use it.
See L<EBook::MOBI> for how to actually add images!

  use EBook::MOBI::Image;
  my $p = EBook::MOBI::Image->new();
    
  my $img_path_small = $p->rescale_dimensions($img_path_big);

=head1 METHODS

=head2 new

The code is meant to be used in object oriented style, so you are asked to create an object before using.

  my $p = EBook::MOBI::Image->new();

=head2 rescale_dimensions

According to my own research at the web, it is a good idea to have a maximum size for images of 520 x 622. And this is what this method does, it ensures that this maximum is kept.

Pass a path to an image as the first argument, you will then get back the path of a rescaled image. The image is only rescaled if necessary. The image is a temporary copy (to protect the original) and will be deleted after your code exits.

Attention: All pictures, no matter what size will be converted to JPG. In my tests, the Kindle-Reader failed to display PNG, that is why I convert everything - to go safe.

=head2 debug_on

You can just ignore this method if you are not interested in debuging!

Pass a reference to a debug subroutine and enable debug messages.

=head2 debug_off

Stop debug messages and erease the reference to the subroutine.

=head1 TODO

A method to change the maximum values would be nice.

=head1 LIMITATIONS

A development version of C<Imlib2> (non-perl) must be installed locally before installing this module.

=head1 COPYRIGHT & LICENSE

Copyright 2013 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut
