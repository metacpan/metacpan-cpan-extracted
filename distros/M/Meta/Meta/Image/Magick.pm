#!/bin/echo This is a perl module and should not be run

package Meta::Image::Magick;

use strict qw(vars refs subs);
use Image::Magick qw();

our($VERSION,@ISA);
$VERSION="0.06";
@ISA=qw(Image::Magick);

#sub Thumb($$$);
#sub TEST($);

#__DATA__

sub Thumb($$$) {
	my($self,$maxx,$maxy)=@_;
	my($x,$y)=$self->Get('width','height');
	if($x>$maxx) {
		$y=$y*$maxx/$x;
		$x=$maxx;
	}
	if($y>$maxy) {
		$x=$x*$maxy/$y;
		$y=$maxy;
	}
	my($new_x)=int($x);
	my($new_y)=int($y);
	$self->Scale(height=>$new_y,width=>$new_x);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Image::Magick - Meta extensions to Image::Magick.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Magick.pm
	PROJECT: meta
	VERSION: 0.06

=head1 SYNOPSIS

	package foo;
	use Meta::Image::Magick qw();
	my($image)=Meta::Image::Magick->new();
	my($thumbnail)=$object->thunb(50,50);

=head1 DESCRIPTION

Since I found there were a few methods I wanted that were missing from
Image::Magick I inherited from it and extended it. This is the result.
The original motivation was the creation of well scaled thumbnails.

=head1 FUNCTIONS

	Thumb($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<Thumb($$$)>

This method will create a thumbnail with x and y as the maximum x and
y size. It will make the image the largest possible within that frame
without distorting it. The image that will be returned may be smaller
than x and y dimensions but only in a single dimension.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Image::Magick(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV thumbnail project basics
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV md5 issues

=head1 SEE ALSO

Image::Magick(3), strict(3)

=head1 TODO

-add method which resizes the image to the thumb size exactly.
