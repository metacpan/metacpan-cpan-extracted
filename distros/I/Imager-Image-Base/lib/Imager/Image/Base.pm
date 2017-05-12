# -*- perl -*-

# Copyright (C) 2015 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Imager::Image::Base;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use Imager ();

sub convert {
    my($class, $image_base) = @_;
    my($w, $h) = $image_base->get('-width', '-height');
    my $has_transparency = $class->can('_has_transparency') && $class->_has_transparency($image_base);
    my $imager = Imager->new(xsize => $w, ysize => $h, (channels => 4) x!! $has_transparency);
    for my $x (0 .. $w-1) {
	for my $y (0 .. $h-1) {
	    my $color = $image_base->xy($x, $y);
	    if ($color =~ m{^(#..)..(..)..(..)..$}) { # convert #RRRRGGGGBBBB to #RRGGBB
		$color = "$1$2$3";
	    } elsif ($color =~ m{^none$}i) {
		$color = '#00000000';
	    }
	    $imager->setpixel(x => $x, y => $y, color => $color);
	}
    }
    $imager;
}

1;

__END__

=head1 NAME

Imager::Image::Base - convert Image::Base to Imager

=head1 SYNOPSIS

   $image_base_object = Image::Xpm->new(-file => ...);
   $imager_object = Imager::Image::Base->convert($image_base_object);

=head1 DESCRIPTION

Convert an L<Image::Base> object into a L<Imager> object.

The performance of this module is probably only suitable for small,
icon-ish images.

To do the conversion in the other direction (convert L<Imager> objects
into L<Image::Base>-compatible objects) use L<Image::Base::Imager>.

=head1 AUTHOR

Slaven Rezic

=head1 SEE ALSO

L<Image::Base>, L<Imager>, L<Imager::Image::Xpm>, L<Imager::Image::Xbm>.

=cut
