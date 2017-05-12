package Geo::GD::Image;

use 5.008005;
use strict;
use warnings;
our $VERSION = '0.02';
use GD;
use GD::Image;
our @ISA=qw(GD::Image);
require XSLoader;
XSLoader::load('Geo::GD::Image', $VERSION);

# GD::Image->newXXXX methods don't bless the right class...


for my $m (qw(new newTrueColor newFromGd newFromGd2 newFromGd2Part newFromGif newFromJpeg newFromPng)) {
  no strict 'refs';
  *$m = sub { my $c = shift; my $s = "SUPER::$m"; bless $c->$s(@_),$c; };
}


1;
__END__

=head1 NAME

Geo::GD::Image - Perl extension to draw Well Known Binary (WKB) blobs directly into a GD::Image

=head1 SYNOPSIS

  use Geo::GD::Image;
  
  my $img = Geo::GD::Image->newTrueColor();  # same as GD::Image
  
  # set up colors etc
  
  $img->draw_wkb( $wkb_blob, $gd_color, $offsetx, $offsety, $ratiox, $ratioy);

=head1 METHODS

Geo::GD::Image is a subclass of L<GD::Image|GD::Image> and currently only adds
2 methods. You should read L<GD>

=head2 draw_wkb

 $img->draw_wkb($wkb_blob, $gd_color, $offsetx, $offsety, $ratiox, $ratioy);

Draw a well known binary shape into the image. Polygons are inserted as filled polygons,
linestrings are inserted as open polygons or lines and points are inserted as single pixels.

Combined types (multipolygon, multilinestring and geometrycolection) are also supported.

Arguments: $wkb_blob: a Well Know Binary string, $gd_color: a GD color number.

$offsetx, $offsety, $ratiox, $ratioy are used to calculate pixel coordinates (0,0 = top-left) from
WKB coordinates:

 $pixelx = $ratiox * ( $wkb_x - $offsetx )
 $pixely = $ratioy * ( $wkb_y - $offsetx )

=head2 alpha

 my $alpha = $img->alpha($gd_color);

Get the alpha channel value of a gd color. The method should arguably be part of L<GD|GD>.

=head1 SEE ALSO

L<GD>.

OpenGIS® Implementation Specification for Geographic information - Simple feature access - Part 2: SQL option:
http://www.opengeospatial.org/standards/sfs

=head1 AUTHOR

Joost Diepenmaat, Zeekat Softwareontwikkeling. http://zeekat.nl/ - C<joost@zeekat.nl>

=head1 COPYRIGHT & LICENSE

Copyright 2006, Toutatis Internet Publishing Software. All rights reserved. http://toutatis.com/

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See the "Artistic License" in the Perl source code distribution for licensing terms.

Portions of the WKB parsing code have been taken from mapserver, Copyright (c) 1996-2005 Regents of the University of Minnesota.

=cut
