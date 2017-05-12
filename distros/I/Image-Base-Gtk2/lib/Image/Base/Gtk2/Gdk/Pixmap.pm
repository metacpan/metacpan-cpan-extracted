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


package Image::Base::Gtk2::Gdk::Pixmap;
use 5.008;
use strict;
use warnings;
use Carp;
use base 'Image::Base::Gtk2::Gdk::Drawable';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 11;

sub new {
  my ($class, %params) = @_;
  ### Gdk-Pixmap new: \%params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    # $class = ref $class;
    if (! defined $params{'-pixmap'}) {
      # $self->get('-gc') creates and retains a gc.  Doing that seems better
      # than letting _drawable_clone_to_pixmap() create and destroy one,
      # though if there was one already in Gtk2::GC with the right depth
      # then could just use that.
      $params{'-pixmap'} = _drawable_clone_to_pixmap ($self->get('-pixmap'),
                                                      $self->get('-gc'));
    }
    # inherit everything else, but don't share gc
    %params = (%$self,
               -gc => undef,
               %params);
  }

  if (exists $params{'-pixmap'}) {
    $params{'-drawable'} = delete $params{'-pixmap'};
  }

  if (! exists $params{'-drawable'}) {
    ### create new pixmap

    my $screen = delete $params{'-screen'};
    my $for_drawable = delete $params{'-for_drawable'};
    my $for_widget = delete $params{'-for_widget'};
    my $depth = delete $params{'-depth'};
    ### for_widget: "$for_widget"

    $screen ||= ($for_widget && $for_widget->get_screen);

    $for_drawable
      ||= ($for_widget && $for_widget->window)
        || ($screen && $screen->get_default_root_window)
          || Gtk2::Gdk->get_default_root_window;

    if (! exists $params{'-colormap'}) {
      if (my $default_colormap
          = ($for_drawable && $for_drawable->get_colormap)
          || ($for_widget && $for_widget->get_colormap)
          || ($screen && $screen->get_default_colormap)) {
        if (! defined $depth
            || $depth == $default_colormap->get_visual->depth) {
          $params{'-colormap'} = $default_colormap;
        }
      }
    }
    if (! defined $params{'-colormap'}) {
      delete $params{'-colormap'};
    }

    if (! defined $depth) {
      if ($params{'-colormap'}) {
        $depth = $params{'-colormap'}->get_visual->depth;
      } elsif ($for_drawable) {
        $depth = $for_drawable->get_depth;
      } else {
        $depth = -1;
      }
    }
    ### $depth

    $params{'-drawable'} = Gtk2::Gdk::Pixmap->new ($for_drawable,
                                                   delete $params{'-width'},
                                                   delete $params{'-height'},
                                                   $depth);
    # -colormap is applied in Drawable new() doing set()
  }

  return $class->SUPER::new (%params);
}

sub new_from_image {
  my $self = shift;
  my $new_class = shift;
  if ($new_class eq __PACKAGE__
      || $new_class eq 'Image::Base::Gtk2::Gdk::Drawable') {
    return bless $self->new(@_), $new_class;
  }
  return $self->SUPER::new_from_image ($new_class, @_);
}

# $pixmap is a Gtk2::Gdk::Pixmap
# create and return a clone of it
# $gc is used to copy the contents, or a temporary gc used if $gc not given
#
sub _drawable_clone_to_pixmap {
  my ($drawable, $gc) = @_;
  my ($width, $height) = $drawable->get_size;
  my $new_pixmap = Gtk2::Gdk::Pixmap->new ($drawable, $drawable->get_size, -1);

  # Perl-Gtk 1.220 set_colormap() doesn't accept undef, so must check
  if (my $colormap = $drawable->get_colormap) {
    $new_pixmap->set_colormap ($colormap);
  }

  # gtk_gc_get() only uses colormap to determine the screen
  # is there any value trying for a shared one?
  # it'd share with someone else using an empty values hash presumably
  # for similar copying
  $gc ||= Gtk2::GC->get ($drawable->get_depth,
                         $drawable->get_screen->get_default_colormap);
  # $gc ||= Gtk2::Gdk::GC->new ($drawable);

  $new_pixmap->draw_drawable ($gc, $drawable, 0,0, 0,0, $width,$height);
  return $new_pixmap;
}

1;
__END__

=for stopwords Ryde Gtk Gdk Pixmaps pixmap colormap ie toplevel
Image-Base-Gtk2 multi-screen

=head1 NAME

Image::Base::Gtk2::Gdk::Pixmap -- draw into a Gdk pixmap

=for test_synopsis my $win

=head1 SYNOPSIS

 use Image::Base::Gtk2::Gdk::Pixmap;
 my $image = Image::Base::Gtk2::Gdk::Pixmap->new
                 (-width => 10,
                  -height => 10,
                  -for_drawable => $win);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Gtk2::Gdk::Pixmap> is a subclass of
C<Image::Base::Gtk2::Gdk::Drawable>,

    Image::Base
      Image::Base::Gtk2::Gdk::Drawable
        Image::Base::Gtk2::Gdk::Pixmap

=head1 DESCRIPTION

C<Image::Base::Gtk2::Gdk::Pixmap> extends C<Image::Base> to create and draw
into Gdk Pixmaps.  There's no file load or save, just drawing operations.

The drawing is done by the C<Image::Base::Gtk2::Gdk::Drawable> base class.
This class adds some pixmap creation help.

=head1 FUNCTIONS

See L<Image::Base::Gtk2::Gdk::Drawable/FUNCTIONS> and
L<Image::Base/FUNCTIONS> for the behaviour inherited from the superclasses.

=over 4

=item C<$image = Image::Base::Gtk2::Gdk::Pixmap-E<gt>new (key=E<gt>value,...)>

Create and return a new pixmap image object.  It can be pointed at an
existing pixmap,

    $image = Image::Base::Gtk2::Gdk::Pixmap->new
                 (-pixmap => $pixmap);

Or a new pixmap created,

    $image = Image::Base::Gtk2::Gdk::Pixmap->new
                 (-width    => 10,
                  -height   => 10);

A pixmap requires a size, screen, depth (bits per pixel) and usually a
colormap for allocating colours.  The default is the Gtk default screen and
its depth and colormap, or desired settings can be applied with

    -screen   =>  Gtk2::Gdk::Screen object
    -depth    =>  integer bits per pixel
    -colormap =>  Gtk2::Gdk::Colormap object or undef

If just C<-colormap> is given then the screen and depth are taken from it.
If C<-depth> is given and it's not the screen's default depth then there's
no default colormap (as it would be wrong), which happens when creating a
bitmap,

    $image = Image::Base::Gtk2::Gdk::Pixmap->new
                 (-width   => 10,
                  -height  => 10,
                  -depth   => 1);  # bitmap, no colormap

The following further helper options can create a pixmap for use with a
widget, window, or another pixmap,

    -for_drawable  => Gtk2::Gdk::Drawable object (win or pixmap)
    -for_widget    => Gtk2::Widget object

These targets give a screen, colormap and depth.  C<-colormap> and/or
C<-depth> can be given to override if desired though.

In a multi-screen program C<-for_widget> should be used after the widget has
been added somewhere under a toplevel widget, because until then it will
only report the default screen (and colormap).  Also, if a widget plays
tricks with its window colormap or depth then it might only have the right
settings after realized (ie. has created its window).

=item C<$new_image = $image-E<gt>new (key=E<gt>value,...)>

Create and return a copy of C<$image>.  The underlying pixmap is cloned by
creating a new one and copying contents to it.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a pixmap cannot be changed once created.

=item C<-pixmap> (C<Gtk2::Gdk::Pixmap> object)

The target pixmap.  C<-drawable> and C<-pixmap> access the same attribute.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::Gtk2::Gdk::Drawable>,
L<Image::Base::Gtk2::Gdk::Window>,
L<Gtk2::Gdk::Pixmap>

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
