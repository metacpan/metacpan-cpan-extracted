# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::Gtk2::Gdk::Window;
use 5.008;
use strict;
use warnings;

use vars '$VERSION','@ISA';
$VERSION = 11;

use Image::Base::Gtk2::Gdk::Drawable;
@ISA = ('Image::Base::Gtk2::Gdk::Drawable');

1;
__END__

# sub xy {
#   my ($self, $x, $y, $colour) = @_;
#   if (@_ >= 4 && $colour eq 'None') {
#     my ($bitmap, $bitmap_gc) = _make_bitmap_and_gc ($self);
#     $bitmap->draw_point ($bitmap_gc, $x,$y);
#     $self->{'-drawable'}->shape_combine_mask ($bitmap, $x,$y);
#   } else {
#     shift->SUPER::xy (@_);
#   }
# }
# 
# sub line {
#   my ($self, $x1,$y1, $x2,$y2, $colour) = @_;
#   ### X11-Protocol-Window line(): $x1,$y1, $x2,$y2, $colour
#   if ($colour eq 'None') {
#     my ($bitmap, $bitmap_gc) = _make_bitmap_and_gc ($self);
#     $bitmap->draw_line ($bitmap_gc, $x1,$y1, $x2,$y2);
#     $self->{'-drawable'}->shape_combine_mask ($bitmap, 0,0);
#   } else {
#     shift->SUPER::line (@_);
#   }
# }
# 
# sub rectangle {
#   my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
#   if ($colour eq 'None') {
#     my ($bitmap, $bitmap_gc) = _make_bitmap_and_gc ($self);
#     Gtk2::Ex::GdkBits::draw_rectangle_corners ($bitmap, $bitmap_gc, 1, $x1,$y1, $x2,$y2);
#     $self->{'-drawable'}->shape_combine_mask ($bitmap, 0,0);
#   } else {
#     $self->SUPER::rectangle ($x1, $y1, $x2, $y2, $colour, $fill);
#   }
# }
# 
# sub ellipse {
#   my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
#   if ($colour eq 'None') {
#     my ($bitmap, $bitmap_gc) = _make_bitmap_and_gc ($self);
#     $bitmap->draw_arc ($bitmap_gc, $fill,
#                        $x1, $y1,
#                        $x2-$x1+1, $y2-$y1+1,
#                        0, 360*64);
#     # and outer 0.5 extra separately when filled
#     $self->{'-drawable'}->shape_combine_mask ($bitmap, 0,0);
#   } else {
#     shift->SUPER::xy (@_);
#   }
# }
# 
# sub _make_bitmap_and_gc {
#   my ($self) = @_;
#   my $win = $self->{'-drawable'};
#   my ($width, $height) = $self->{'-drawable'}->get_size;
#   my $bitmap = Gtk2::Gdk::Pixmap->new ($win, $width,$height, 1);
#   my $bitmap_gc = Gtk2::Gdk::GC->new
#     ($bitmap, { foreground => Gtk2::Gdk::Color->new(0,0,0,1) });
#   $bitmap->draw_rectangle ($bitmap_gc, 1, 0,0, $width,$height);
#   $bitmap_gc->set_foreground (Gtk2::Gdk::Color->new(0,0,0,0));
#   return ($bitmap, $bitmap_gc);
# }



=for stopwords resizes Gdk filename undef Ryde Image-Base-Gtk2

=head1 NAME

Image::Base::Gtk2::Gdk::Window -- draw into a Gdk window

=for test_synopsis my $win

=head1 SYNOPSIS

 use Image::Base::Gtk2::Gdk::Window;
 my $image = Image::Base::Gtk2::Gdk::Window->new (-window => $win);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Gtk2::Gdk::Window> is a subclass of
C<Image::Base::Gtk2::Gdk::Drawable>,

    Image::Base
      Image::Base::Gtk2::Gdk::Drawable
        Image::Base::Gtk2::Gdk::Window

=head1 DESCRIPTION

C<Image::Base::Gtk2::Gdk::Window> extends C<Image::Base> to draw into Gdk
windows.  There's no file load or save, just drawing operations.

This is a placeholder at the moment, it doesn't add anything to what
C<Image::Base::Gtk2::Gdk::Drawable> does.

=head1 FUNCTIONS

See L<Image::Base::Gtk2::Gdk::Drawable/FUNCTIONS> and
L<Image::Base/FUNCTIONS> for the behaviour inherited from the superclasses.

=over 4

=item C<$image = Image::Base::Gtk2::Gdk::Window-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  C<-window> must be a
C<Gtk2::Gdk::Window> object,

    $image = Image::Base::Gtk2::Gdk::Window->new (-window => $win);

There's nothing to create a new C<Gtk2::Gdk::Window> since there's so many
attributes when creating which seem outside the scope of this C<Image::Base>
wrapper.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

The size of the window.  Changing these resizes the window.

=item C<-window> (Gtk2::Gdk::Window object)

The target window.  C<-drawable> and C<-window> access the same attribute.

=back

=head1 FUTURE

It might be possible for colour "None" to mean transparent so drawing it
would make holes in windows per C<< $window->shape_combine_mask >>.  But is
there a shape "Subtract"?  Or how to get the current shape to modify?

=head1 HOME PAGE

L<http://user42.tuxfamily.org/image-base-gtk2/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Gtk2 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Gtk2.  If not, see L<http://www.gnu.org/licenses/>.

=cut
