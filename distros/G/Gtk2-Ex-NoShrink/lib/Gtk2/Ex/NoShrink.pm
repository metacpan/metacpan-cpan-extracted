# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NoShrink.
#
# Gtk2-Ex-NoShrink is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NoShrink is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NoShrink.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::NoShrink;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);
use POSIX ();

our $VERSION = 4;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::Bin',
  signals => { size_allocate => \&do_size_allocate,
               size_request  => \&do_size_request,
             },
  properties => [Glib::ParamSpec->int
                 ('minimum-width',
                  'minimum-width',
                  '',
                  0, POSIX::INT_MAX(), # range
                  0,                   # default
                  Glib::G_PARAM_READWRITE),
                 Glib::ParamSpec->int
                 ('minimum-height',
                  'minimum-height',
                  '',
                  0, POSIX::INT_MAX(), # range
                  0,                   # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->double
                 ('shrink-width-factor',
                  'shrink-width-factor',
                  '',
                  0, POSIX::DBL_MAX(), # range
                  0,                   # default
                  Glib::G_PARAM_READWRITE),
                 Glib::ParamSpec->double
                 ('shrink-height-factor',
                  'shrink-height-factor',
                  '',
                  0, POSIX::DBL_MAX(), # range
                  0,                   # default
                  Glib::G_PARAM_READWRITE)
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  # NoShrink doesn't draw into the window
  # (child still gets exposes on any resize though)
  $self->set_redraw_on_allocate(0);

  # per defaults in the ParamSpec's above
  $self->{'minimum_width'}  = 0;
  $self->{'minimum_height'} = 0;
  $self->{'shrink_width_factor'} = 0;
  $self->{'shrink_height_factor'} = 0;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->{$pname};
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($oldval != $newval) {
    $self->queue_resize;
  }
}

# 'size-request' class closure
#
# called by anyone interested in how big we want to be -- ask child and add
# the border width
# 
sub do_size_request {
  my ($self, $req) = @_;

  my $old_min_width  = $self->{'minimum_width'};
  my $old_min_height = $self->{'minimum_height'};
  my $min_width  = $old_min_width;
  my $min_height = $old_min_height;

  my $child = $self->get_child;
  if ($child && $child->visible) {
    my $creq = $child->size_request;

    my $width_factor = $self->{'shrink_width_factor'};
    if ($width_factor > 0 && $creq->width * $width_factor <= $min_width) {
      $min_width = $creq->width;
    } else {
      $min_width = max ($min_width, $creq->width);
    }

    my $height_factor = $self->{'shrink_height_factor'};
    if ($height_factor >0 && $creq->height * $height_factor <= $min_height) {
      $min_height = $creq->height;
    } else {
      $min_height = max ($min_height, $creq->height);
    }
  }

  if (DEBUG) {
    if ($min_width  != $old_min_width || $min_height != $old_min_height) {
      print $self->get_name," request ",$min_width,"x",$min_height,
        ", extending min ",$old_min_width,"x",$old_min_height;
      if ($child) {
        my $creq = $child->size_request;
        print ", for child ", ($child->visible ? '' : '(not visible) '),
          "req ",$creq->width,"x",$creq->height;
      }
      print " border ",$self->get_border_width,"\n";
    }
  }

  # set and notify any new minimum for the width/height from the child
  #
  $self->{'minimum_width'}  = $min_width;
  $self->{'minimum_height'} = $min_height;
  # believe cleanest to notify after both width and height updated
  if ($old_min_width  != $min_width)  { $self->notify ('minimum-width'); }
  if ($old_min_height != $min_height) { $self->notify ('minimum-height'); }

  my $border_width = $self->get_border_width;
  $req->width  ($min_width  + 2*$border_width);
  $req->height ($min_height + 2*$border_width);
}

# 'size-allocate' class closure
#
# called by our parent to give us actual allocated space -- pass this down
# to the child, less the border width
# 
sub do_size_allocate {
  my ($self, $alloc) = @_;
  if (my $child = $self->get_child) {
    my $border_width  = $self->get_border_width;
    my $x = $alloc->x + $border_width;
    my $y = $alloc->y + $border_width;
    my $width = max (1, $alloc->width  - 2*$border_width);
    my $height = max (1, $alloc->height - 2*$border_width);

    my $child_alloc = $child->allocation;

    if (DEBUG) {
      my $creq = $child->size_request;
      print "NoShrink child alloc ${width}x${height} at $x,$y",
        ", vs child req ",$creq->width,"x",$creq->height,
          ", and current child ",
            $child_alloc->x,",",$child_alloc->y,
              " ",$child_alloc->width,"x",$child_alloc->height,
                "\n";
    }
    if ($x != $child_alloc->x
        || $y != $child_alloc->y
        || $width != $child_alloc->width
        || $height != $child_alloc->height) {
      $child->size_allocate (Gtk2::Gdk::Rectangle->new ($x, $y, $width, $height));
    }
  }
}

1;
__END__

=head1 NAME

Gtk2::Ex::NoShrink -- non-shrinking container widget

=for test_synopsis my ($my_child_widget)

=head1 SYNOPSIS

 use Gtk2::Ex::NoShrink;
 my $noshrink = Gtk2::Ex::NoShrink->new;
 $noshrink->add ($my_child_widget);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::NoShrink> is a subclass of C<Gtk2::Bin>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Ex::NoShrink

=head1 DESCRIPTION

A C<Gtk2::Ex::NoShrink> container widget holds a single child widget and
imposes a "no shrink" policy on its size.  The child can grow, but any
request to shrink is ignored.

When the child requests a size the NoShrink sets that as the size it
requests in turn from its parent.  If the child later changes asks to be
smaller, the NoShrink stays at the previous larger size, thus keeping the
child's largest-ever request.  A largest size is maintained separately for
width and for height.

Requested sizes are of course just that: only requests.  It's a matter for
the NoShrink's parent how much space is actually provided.  The NoShink
always sets its child to the full allocated space, less the usual
C<border-width> (see L<Gtk2::Container>) if that's set.  As usual it's then
a matter for the child what it does in a size perhaps bigger or perhaps
smaller than what it said it wanted.

If a child is added but not shown (no C<< $child->show >>) then it's treated
as if there was no child.  This is the same as other container classes do.
For NoShrink it means a size request of the C<minimum-width> by
C<minimum-height>, plus C<border-width>, and nothing drawn.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::NoShrink->new (key=>value,...) >>

Create and return a new C<Gtk2::Ex::NoShrink> container widget.  Optional
key/value pairs set initial properties per C<< Glib::Object->new >>.

    my $noshrink = Gtk2::Ex::NoShrink->new (border_width => 4);

The child widget can be set with the usual container C<add> method,

    $noshrink->add ($my_child_widget);

Or with the usual C<child> pseudo-property, either at creation time or
later,

    my $noshrink = Gtk2::Ex::NoShrink->new
                     (child => $my_child_widget);

=back

=head1 PROPERTIES

=over 4

=item C<minimum-width> (integer, default 0)

=item C<minimum-height> (integer, default 0)

The currently accumulated minimum width and height to impose on the size
request made by the child.  These are maintained as the largest width and
height requested from the child so far, or 0 for no size requested in that
direction so far.

Both sizes are for the child's space.  Any C<border-width> amount is added
on top of these for the size requested in turn by the NoShrink to its
parent.

These minimums can be set initially to begin at a particular size,

    my $noshrink = Gtk2::Ex::NoShrink->new (minimum_width => 30,
                                            minimum_height => 20);

They can also be reduced later to reset the size.  This results in the
greater of the new value or the child's current requested size.  Setting 0
for instance always goes to the child's current requested size.  This is
good if the nature of the child's content has changed,

    $noshrink->set('minimum-width', 0);  # reset to child size

These minimum size properties are unaffected by any removal of the child
widget or re-add of a new child.  If a new widget has a completely different
nature then you may want to reset both dimensions to start again from its
new sizes.

=item C<shrink-width-factor> (float, default 0)

=item C<shrink-height-factor> (float, default 0)

If non-zero then these values are factors representing a point at which the
NoShrink will in fact shrink to match the child's size.

If the child asks for a width which is a factor C<shrink-width-factor> (or
more) smaller than the existing C<minimum-width> imposed, then the
C<NoShrink> will reset the C<minimum-width> to the child's request.
Likewise C<shrink-height-factor> on the height.

Suppose for instance C<shrink-width-factor> is 2.0 and the NoShrink has over
the course of successive child requests grown to 300 pixels wide.  If the
child then asks to be 100 pixels the NoShrink will obey that, because it's a
shrinkage by a factor more than 2.0 times.  The new C<minimum-width> becomes
100.

These factors allow small shrinks to be ignored but large ones obeyed.  This
is good if the child might grow to a silly size when displaying wild data
for a while and you'd like it to shrink back when normality is restored.

=back

The usual C<border-width> property from C<Gtk2::Container> is followed.  It
leaves a border of that many pixels around the child in the C<NoShrink>
container's allocated space.  Currently nothing is drawn in the border.  The
default C<border-width> is 0, giving the child all the allocated space.

=head1 SEE ALSO

L<Gtk2::Container>, L<Gtk2::Bin>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-noshrink/index.html>

=head1 LICENSE

Gtk2-Ex-NoShrink is Copyright 2007, 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-NoShrink is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-NoShrink is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-NoShrink.  If not, see L<http://www.gnu.org/licenses/>.

=cut
