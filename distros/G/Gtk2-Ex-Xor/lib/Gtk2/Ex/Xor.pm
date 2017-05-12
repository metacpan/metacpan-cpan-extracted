# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::Xor;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 22;

my $cache;

# widget/window/colormap/depth
#    - alternate ways of specifying colormap and depth
# foreground/background
#    - color object R/G/B
#    - string to parse
#    - number pixel
#    - undef for style fg/bg
# foreground_xor / background_xor
#    - same but then xored against $widget->Gtk2_Ex_Xor_background
# dash_offset, dash_list
#    - shared, not otherwise handled by Gtk2::GC

sub shared_gc {
  my (%params) = @_;
  ### shared_gc()
  $params{'function'} = 'xor';

  my $widget = delete $params{'widget'};
  my $window = delete $params{'window'} || $widget->Gtk2_Ex_Xor_window;
  my $colormap = delete $params{'colormap'} || $window->get_colormap;
  my $depth = delete $params{'depth'} || $colormap->get_visual->depth;

  {
    my @colors;
    my $xor_color;
    foreach my $fb ('fore','back') {
      my $color;
      ### color: $fb
      if (exists $params{"${fb}ground_xor"}) {
        $color = delete $params{"${fb}ground_xor"};
        ### param xor: $color
        if (! defined $xor_color) {
          $xor_color = $widget->Gtk2_Ex_Xor_background;
          ### xor pixel: $xor_color->pixel
        }
        $color = Gtk2::Gdk::Color->new
          (0,0,0,
           $xor_color->pixel
           ^ _color_lookup($widget,$fb,$colormap,$color)->pixel);
      } else {
        $color = delete $params{"${fb}ground"};
        ### param plain: $color
        $color = _color_lookup ($widget, $fb, $colormap, $color);
      }
      ### resulting color: $color
      ### resulting color: $color->to_string
      push @colors, $color;
    }
    ($params{'foreground'}, $params{'background'}) = @colors;
  }
  ### pixels: sprintf "fg %#x bg %#x", $params{'foreground'}->pixel, $params{'background'}->pixel

  ### dash_offset: $params{'dash_offset'}
  if (! $params{'dash_offset'}) {  # default 0
    delete $params{'dash_offset'};
  }
  ### dash_list: $params{'dash_list'}
  if (_dash_list_is_default ($params{'dash_list'})) {
    delete $params{'dash_list'};
  }

  # use plain Gtk2::GC if no dashes
  if (! $params{'dash_offset'} && ! $params{'dash_list'}) {
    ### use plain Gtk2-GC
    return Gtk2::GC->get ($depth, $colormap, \%params);
  }

  $cache ||= do {
    require Tie::RefHash::Weak;
    tie (my %cache, 'Tie::RefHash::Weak');
    \%cache
  };
  my $key = join (';',
                  "colormap=$colormap;depth=$depth",
                  map { my $value = $params{$_};
                        if (/ground$/) {
                          $value = $value->pixel;
                        } elsif ($_ eq 'dash_list') {
                          $value = join(',',@$value);
                        }
                        "$_=$value"
                      } sort keys %params);
  return ($cache->{$key} ||= do {
    ### Xor new gc: $key
    my $dash_offset = delete $params{'dash_offset'} || 0;
    my $dash_list   = delete $params{'dash_list'} || [4];
    my $gc = Gtk2::Gdk::GC->new ($window, \%params);
    $gc->set_dashes ($dash_offset, @$dash_list);
    $gc
  });
}

sub _color_lookup {
  my ($widget, $fb, $colormap, $color) = @_;
  ### _color_lookup(): $color
  if (! defined $color) {
    my $method = ($fb eq 'fore' ? 'fg' : 'bg');
    ### widget: $fb
    ### is: $widget->get_style->$method ($widget->state)
    return $widget->get_style->$method ($widget->state);
  }
  if (ref $color) {
    # copy so as not to clobber pixel field
    $color = $color->copy;
  } elsif (Scalar::Util::looks_like_number($color)) {
    ### pixel
    return Gtk2::Gdk::Color->new (0,0,0, $color);
  } else {
    ### parse
    my $str = $color;
    $color = Gtk2::Gdk::Color->parse ($str)
      || croak "Cannot parse colour '$str'";
  }
  # a shared colour alloc would be friendlier to pseudo-colour visuals, but
  # if the rest of gtk is using the rgb chunk anyway then may as well do the
  # same
  $colormap->rgb_find_color ($color);
  ### rgb_find_color: $color
  return $color;
}


# Return true if arrayref $dash_list is the same as the Gtk2::Gdk::GC
# default dashes, which is 4,4.  An array of 4 or repetitions of 4 is the
# default, any segment length other than 4 is not the same as the default.
#
sub _dash_list_is_default {
  my ($dash_list) = @_;
  return ! (defined $dash_list
            && List::Util::first {$_ != 4} @$dash_list);
}
# sub _dash_lists_equal {
#   my @pos = (0) x @_;
#   my $maxlen = gcd (map {scalar(@{$_})} @_);
#   foreach (1 .. $maxlen) {
#     $want = $_[0]->[$pos[0]++];
#     if ($pos[0] > @{$_[0]}) { $pos[0] = 0; }
# 
#   foreach (@_) {
#   my ($d1, $d2) = @_;
#   return ! (defined $dash_list
#             && List::Util::first {$_ != 4} @$dash_list);
# }

sub _event_widget_coords {
  my ($widget, $event) = @_;

  # Do a get_pointer() to support 'pointer-motion-hint-mask'.
  # Maybe should use $display->get_state here instead of just get_pointer,
  # but crosshair and lasso at present only work with the mouse, not an
  # arbitrary input device.
  if ($event->can('is_hint') && $event->is_hint) {
    return $widget->get_pointer;
  }

  my $x = $event->x;
  my $y = $event->y;
  my $eventwin = $event->window;
  if ($eventwin != $widget->window) {
    my ($wx, $wy) = $eventwin->get_position;
    ### subwindow offset: "$wx,$wy"
    $x += $wx;
    $y += $wy;
  }
  return ($x, $y);
}

sub _ref_weak {
  my ($weak_self) = @_;
  require Scalar::Util;
  Scalar::Util::weaken ($weak_self);
  return \$weak_self;
}


#------------------------------------------------------------------------------
# background colour hacks

# default is from the widget's Gtk2::Style, but with an undocumented
# 'Gtk2_Ex_Xor_background' as an override
#
sub Gtk2::Widget::Gtk2_Ex_Xor_background {
  my ($widget) = @_;
  if (exists $widget->{'Gtk2_Ex_Xor_background'}) {
    return $widget->{'Gtk2_Ex_Xor_background'};
  }
  return $widget->Gtk2_Ex_Xor_background_from_style;
}

# "bg" is the background for normal widgets
sub Gtk2::Widget::Gtk2_Ex_Xor_background_from_style {
  my ($widget) = @_;
  return $widget->get_style->bg ($widget->state);
}

# "base" is the background for text-oriented widgets like Gtk2::Entry and
# Gtk2::TextView.  TextView has multiple windows, so this is the colour
# meant for the main text window.
#
# GooCanvas uses the "base" colour too.  Dunno if it thinks of itself as
# text oriented or if white in the default style colours seemed better.
#
sub Gtk2::Entry::Gtk2_Ex_Xor_background_from_style {
  my ($widget) = @_;
  return $widget->get_style->base ($widget->state);
}
*Gtk2::TextView::Gtk2_Ex_Xor_background_from_style
  = \&Gtk2::Entry::Gtk2_Ex_Xor_background_from_style;
*Goo::Canvas::Gtk2_Ex_Xor_background_from_style
  = \&Gtk2::Entry::Gtk2_Ex_Xor_background_from_style;

# For Gtk2::Bin subclasses such as Gtk2::EventBox, look at the child's
# background if there's a child and if it's a no-window widget, since that
# child is what will be xored over.
#
# Perhaps this should be only some of the Bin classes, like Gtk2::Window,
# Gtk2::EventBox and Gtk2::Alignment.
{
  package Gtk2::Bin;
  sub Gtk2_Ex_Xor_background {
    my ($widget) = @_;
    # same override as above ...
    if (exists $widget->{'Gtk2_Ex_Xor_background'}) {
      return $widget->{'Gtk2_Ex_Xor_background'};
    }
    if (my $child = $widget->get_child) {
      if ($child->flags & 'no-window') {
        return $child->Gtk2_Ex_Xor_background;
      }
    }
    return $widget->SUPER::Gtk2_Ex_Xor_background;
  }
}


#------------------------------------------------------------------------------
# window choice hacks

# normal "->window" for most widgets
*Gtk2::Widget::Gtk2_Ex_Xor_window = \&Gtk2::Widget::window;

# for Gtk2::Layout must draw into its "bin_window"
*Gtk2::Layout::Gtk2_Ex_Xor_window = \&Gtk2::Layout::bin_window;

sub Gtk2::TextView::Gtk2_Ex_Xor_window {
  my ($textview) = @_;
  return $textview->get_window ('text');
}

# GtkEntry has a window and then within that a subwindow just 4 pixels
# smaller in height.  The latter is what it draws on.
#
# The following code as per Gtk2::Ex::WidgetCursor.  Since the subwindow
# isn't a documented feature check that it does, in fact, exist.
#
# The alternative would be "include inferiors" on the xor gc's.  But that'd
# probably cause problems on windowed widget children, since expose events
# in them wouldn't be seen by the parent's expose to redraw the
# crosshair/lasso/etc.
#
sub Gtk2::Entry::Gtk2_Ex_Xor_window {
  my ($widget) = @_;
  my $win = $widget->window || return undef; # if unrealized
  return ($win->get_children)[0] # first child
    || $win;
}

# GooCanvas draws on a subwindow too, also undocumented it seems
# (there's a tmp_window too, but that's only an overlay suppressing some
# expose events or something at selected times)
*Goo::Canvas::Gtk2_Ex_Xor_window = \&Gtk2::Entry::Gtk2_Ex_Xor_window;

1;
__END__

=for stopwords add-ons natively bg xoring multi-window subwindow subwindows SyncCall Ryde Gtk2-Ex-Xor

=head1 NAME

Gtk2::Ex::Xor -- shared support for drawing with XOR

=head1 DESCRIPTION

This is support code shared by C<Gtk2::Ex::CrossHair> and
C<Gtk2::Ex::Lasso>.

Both those add-ons draw using an "xor" onto the pixels in a widget (hence
the dist name), using a value that flips between the widget background and
the cross or lasso line colour.  Drawing like this is fast and portable,
though doing it as an add-on can potentially clash with what the widget does
natively.

=over 4

=item *

A single dominant background colour is assumed.  Often shades of grey or
similar will end up with a contrasting line but there's no guarantee of
that.

=item *

The background colour is taken from the widget C<Gtk2::Style> "bg" for
normal widgets, or from "base" for text widgets C<Gtk2::Entry> and
C<Gtk2::TextView>.  C<Goo::Canvas> is recognised as using "base" too.

=item *

Expose events are watched and xoring redone, though it assumes the widget
will redraw only the exposed region, as opposed to a full window redraw.
Clipping in a redraw is usually what you want, especially if the display
might not have the X double-buffering extension.

=item *

For multi-window widgets it's necessary to figure out which subwindow is the
one to draw on.  The xoring recognises the "bin" window of C<Gtk2::Layout>
(which includes C<Gnome2::Canvas>), the "text" subwindow of
C<Gtk2::TextView>, and the secret subwindows of C<Gtk2::Entry> and
C<Goo::Canvas>.

=item *

The SyncCall mechanism is used to protect against flooding the server with
more drawing than it can keep up with.  Each motion event would only result
in a few drawing requests, but it's still easy to overload the server if it
sends a lot of motions or if it's not very fast at drawing wide lines.  The
effect of SyncCall is to delay further drawing until hearing back from the
server that the previous has completed.

=back

=head1 SEE ALSO

L<Gtk2::Ex::CrossHair>, L<Gtk2::Ex::Lasso>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-xor/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Xor.  If not, see L<http://www.gnu.org/licenses/>.

=cut

#
# Not sure about describing this yet:
#
# =head1 SYNOPSIS
# 
#  use Gtk2::Ex::Xor;
#  my $colour = $widget->Gtk2_Ex_Xor_background;
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< $widget->Gtk2_Ex_Xor_background() >>
# 
# Return a C<Gtk2::Gdk::Color> object, with an allocated pixel value, which is
# the background to XOR against in C<$widget>.
# 
# =back
# 
# =head1 SEE ALSO
# 
# L<Gtk2::Ex::CrossHair>, L<Gtk2::Ex::Lasso>
