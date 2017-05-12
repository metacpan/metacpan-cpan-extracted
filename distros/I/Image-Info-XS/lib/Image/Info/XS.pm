package Image::Info::XS;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);


my @all = qw/image_info image_type/;

our %EXPORT_TAGS = ( 'all' => \@all );

our @EXPORT_OK = ( @all );

our @EXPORT = qw();

our $VERSION = '0.1.8';

require XSLoader;
XSLoader::load('Image::Info::XS', $VERSION);

1;
__END__

=head1 NAME

Image::Info::XS - Extract meta information from image files. XS implementation of Image::Info.

=head1 SYNOPSIS

  use Image::Info::XS qw(image_info image_type);

  my $info = image_info('image.jpg');
  if (!$info) 
  {
    die "Can't parse image info\n";
  }
  my $color = $info->{'color_type'};
  
  my $type = image_type("image.jpg");
  if (!$type) 
  {
     die "Can't determine file type\n";
  }
  
  die "No gif files allowed!" if $type eq 'GIF';

=head1 DESCRIPTION

This module provide functions to extract various kind of meta information from image files.

=head1 METHODS

image_info( $file )

image_info( \$imgdata )

image_type( $file )

image_type( \$imgdata )


=head1 Supported Image Formats

BMP
GIF
ICO
JPEG
PNG
TIFF
PSD
  

=head1 SEE ALSO

Image::Info

=head1 AUTHOR

Dmitry Kosenkov, C<< <d.kosenkov AT rambler-co.ru> >>, C<< <junker AT front.ru> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry Kosenkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
