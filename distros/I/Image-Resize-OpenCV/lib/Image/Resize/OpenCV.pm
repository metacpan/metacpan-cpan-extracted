package Image::Resize::OpenCV;

use 5.008001;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( image_resize );
our @EXPORT = qw();

our $VERSION = '0.11';

require XSLoader;
XSLoader::load('Image::Resize::OpenCV', $VERSION);


sub new
{
	my $class = shift;

	my $self = {};
	bless $self, $class;
	$self -> _init(@_);

	return $self;
}

sub image_resize
{
	my $filename = shift;
	my $width = shift;
	my $height = shift;
	my $out_filename = shift || $filename;
	
	my $img = new Image::Resize::OpenCV($filename);
	$img -> resize($width, $height);
	$img -> save($out_filename);
}



1;
__END__

=head1 NAME

Image::Resize::OpenCV - Simple image resizer using OpenCV

=head1 SYNOPSIS

    use Image::Resize::OpenCV;
    $image = Image::Resize::OpenCV -> new('large.jpg');
    print ("WIDTH:" . $image -> width . " HEIGHT:" . $image -> height);
    $image -> resize(250, 250);
    $image -> save("small.jpg");

    # OR

    use Image::Resize::OpenCV qw(image_resize);
    image_resize('large.jpg', 250, 250);

=head1 DESCRIPTION

  Image::Resize::OpenCV using openCV library for resize images. openCV more faster then GD, ImageMagick, GraphicsMagick etc.
  OpenCV more quality then GD and have 4 interpolation mode for resize images.


=head2 EXPORT

  image_resize($filename, $width, $height, $out_filename = undef);


=head1 METHODS

=head2 new($filename = undef) - Constructor

    Create a new mage::Resize::OpenCV object 

    my $image = new Image::Resize::OpenCV();
    my $image = new Image::Resize::OpenCV($filename);

=head2 load($filename) - Load image file

    $image -> load($filename);

=head2 resize($width, $height, ...) - Resize Image

    $image -> resize(640, 480);
    $image -> resize(640, 480, KEEP_ASPECT => 1);
    $image -> resize(640, 480, INTER => 1);
    $image -> resize(640, 480, KEEP_ASPECT => 1, INTER => 1);
    
    # INTER - Interpolation:
    # 0 - nearest-neigbor
    # 1 - bilinear
    # 2 - pixel area relation
    # 3 - bicubic
    
=head2 save($filename, $compress = 25) - Save image 

    $image -> save('/tmp/11.jpg');
    $image -> save('/tmp/11.jpg', 50);

=head2 width()
 
=head2 height()

=head1 SEE ALSO

L<http://sourceforge.net/projects/opencvlibrary/>

=head1 AUTHOR

Dmitry Kosenkov, E<lt>junker@front.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry Kosenkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
