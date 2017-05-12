# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::TickerView;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use POSIX ();
use Time::HiRes;

use Glib;
# version 1.180 for Gtk2::CellLayout as an interface, also 1.180 for
# Gtk2::Buildable overriding superclass interface
use Gtk2 1.180;

use Gtk2::Ex::SyncCall 12; # version 12 for gtk XID workaround
use Gtk2::Ex::CellLayout::Base 4;  # version 4 for _cellinfo_starts()
our @ISA;
push @ISA, 'Gtk2::Ex::CellLayout::Base';

our $VERSION = 15;

# set this to 1 for some diagnostic prints, or 2 for even more prints
use constant DEBUG => 0;

use constant { DEFAULT_FRAME_RATE => 4,     # times per second
               DEFAULT_SPEED      => 30,    # pixels per second
             };

# not wrapped until Gtk2-Perl 1.200
use constant GDK_PRIORITY_REDRAW => (Glib::G_PRIORITY_HIGH_IDLE + 20);

use Glib::Object::Subclass
  'Gtk2::DrawingArea',
  interfaces =>
  [ 'Gtk2::CellLayout',
    # Gtk2::Buildable new in Gtk 2.12, omit if not available
    Gtk2::Widget->isa('Gtk2::Buildable') ? ('Gtk2::Buildable') : ()
  ],

  signals => { expose_event            => \&_do_expose_event,
               size_request            => \&_do_size_request,
               size_allocate           => \&_do_size_allocate,
               button_press_event      => \&_do_button_press_event,
               motion_notify_event     => \&_do_motion_notify_event,
               button_release_event    => \&_do_button_release_event,
               scroll_event            => \&_do_scroll_event,
               visibility_notify_event => \&_do_visibility_notify_event,
               direction_changed       => \&_do_direction_changed,
               map                     => \&_do_map_or_unmap,
               unmap                   => \&_do_map_or_unmap,
               unrealize               => \&_do_unrealize,
               notify                  => \&_do_notify,
               state_changed           => \&_do_state_or_style_changed,
               style_set               => \&_do_state_or_style_changed,
             },
  properties => [ Glib::ParamSpec->object
                  ('model',
                   'Model object',
                   'TreeModel giving the items to display.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('run',
                   'Run ticker',
                   'Whether to run the ticker, ie. scroll across.',
                   1, # default yes
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->double
                  ('speed',
                   'Speed',
                   'Speed to move the items across, in pixels per second.',
                   0, POSIX::DBL_MAX(),
                   DEFAULT_SPEED,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->double
                  ('frame-rate',
                   'Frame rate',
                   'How many times per second to move for scrolling.',
                   0, POSIX::DBL_MAX(),
                   DEFAULT_FRAME_RATE,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('fixed-height-mode',
                   'Fixed height mode',
                   'Assume all cells have the same desired height.',
                   0, # default no
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('orientation',
                   'Orientation', # dgettext('gtk20-properties')
                   'Horizontal or vertical display and scrolling.',
                   'Gtk2::Orientation',
                   'horizontal',
                   Glib::G_PARAM_READWRITE),

                ];

# The private per-object fields are:
#
# vertical  0 or 1
#     0 when horizontal, 1 when vertical.  Presented through GET_PROPERTY
#     and SET_PROPERTY as Gtk2::Orientation 'horizontal' and 'vertical', but
#     internally the number allows computed indexes instead of conditionals.
#
# pixmap  Gtk2::Gdk::Pixmap or undef
#     Established in _pixmap(), undef until then.
#
# pixmap_size
#     The width of pixmap when horizontal, or height when vertical.  This is
#     established by _pixmap_desired_size() and thus may be set before
#     pixmap is actually created.
#
# row_widths   hashref { $index => $width }
#     $index is an integer row number.  $width is the total width of all the
#     renderers' drawing of that row.
#
#     This is a hash instead of an array so as to keep widths for roughly
#     just the rows displayed, which may be a good thing on a big model.
#     Widths are discarded when _pixmap_shift drops rows off the left edge,
#     and when _pixmap_empty purges the whole pixmap.  Widths are stored by
#     _pixmap_extend, so the displayed rows are present, ready for
#     _normalize() to use contemplating an increment of want_index.
#
#     Widths are also saved by normalize actions like a big scroll_pixels()
#     or a get_path_at_pos() of an off-screen position.  Those widths end up
#     remaining until a full redraw or until shifting passes them by.  Which
#     is probably no bad thing if one off-screen position calculation is
#     reasonably likely to be followed by another.  Might be worth thinking
#     more about that though.
#
#     The widths of drawn rows are implicitly in drawn_array as the
#     difference between successive $x values, so having them in
#     'row_widths' is a bit of duplication.  If _normalize() looked at
#     drawn_array the drawn rows could be omitted, but almost certainly the
#     code size would outweigh the data space.
#
# drawn_array   arrayref [ $index, $x, $index, $x, ... ]
#     Each $index is an integer row number.  Each $x is the position in
#     'pixmap' where row $index has been drawn.  There's two things helped
#     by saveing all drawn positions,
#
#     1. _pixmap_shift() is easier.  It can decrement each $x by the shift
#        amount and look for the last $x <= 0 as the drawn rows retained.
#        When the last row has been chopped off at the right edge (which is
#        almost always) the second last position is immediately available to
#        become pixmap_end_x, and the last index is pixmap_end_index to
#        extend from.
#
#        If all positions weren't recorded then _pixmap_shift() would have
#        to reconstruct them to find that $x <= 0 point and the second last
#        row pos, by adding up row widths.
#
#     2. _pixmap_find_want() can contemplate two drawn copies of a given
#        row.  There might be one at the start which starts a bit off screen
#        at the left, and another later in the pixmap.  When want_x allows
#        the first to be used it makes best use of the current pixmap
#        contents.  If not then the second is a fallback and if it's too far
#        to the right then might still be usable if _pixmap_shift() moves it
#        down.
#
#     Point 2 might be covered by retaining two positions for each row: its
#     leftmost and then second leftmost (if any).  _pixmap_shift() would
#     still be tricky though, if it tried to find a new second leftmost for
#     those rows whose leftmost had gone off-screen.
#
#     Rows of zero width are still entered in drawn_array.  This ensures
#     _do_row_changed, _do_row_deleted, etc, notice that those rows are
#     on-screen.  It's possible want_index is a zero width row if an
#     explicit scroll_to_start has gone there (or a hypothetical
#     scroll_to_iter or something like that).  _normalize() normally doesn't
#     leave want_index on a zero width when moving though.
#
# want_x, want_index  integers
#     want_index is the desired row number (counting from 0) to be shown at
#     the start of the ticker window.  want_x is an x position where the
#     left edge of the want_index row should start.  want_x is zero or
#     negative.  Negative means the want_index item is partly off the left
#     edge.
#
#     Scrolling will soon make want_x a larger negative than the width of
#     the want_index row.  Expose (using _normalize()) looks for that and
#     moves up by incrementing want_index and adding the skipped row width
#     to want_x.  It can go across multiple rows that way if necessary.
#
#     Scrolling backwards can make want_x go positive.  _normalize_want()
#     and _normalize() again adjust, this time by decrementing want_index to
#     a preceding row and subtracting that width from want_x, working back
#     to find what row should be at or just before the left edge.
#
# pixmap_end_x
#     The x just after the endmost drawn part of the pixmap.  pixmap_end_x
#     is truncated to pixmap_size when full or when the model is empty or
#     all zero width rows.
#
#     Until pixmap_end_x is faked to pixmap_size it's equal to the last
#     drawn_array entry plus that entry's row_width.  But the fakery to
#     pixmap_size means it's easier to maintain pixmap_end_x separately than
#     to build from drawn_array each time.
#
#     The pixmap starts with only as much content as needed for expose to
#     show the expose region the want_index/want_x position.  As
#     want_x,want_index advance _pixmap_extend() draws more content at
#     pixmap_end_x.
#
#     The "undrawn" area from pixmap_end_x onwards is always cleared to the
#     background colour (in _pixmap_redraw() and _pixmap_shift()), so
#     _pixmap_extend() can just draw.  Some of that area might never be used
#     but the idea is to do a single big XDrawRectangle instead of several
#     small ones.
#
# visibility_state  Gtk2::Gdk::VisibilityState enum string or 'initial'
#     This is maintained from the 'visiblity-notify-event' handler.  If
#     'fully-obscured' then the scroll timer is stopped, to save a bit of
#     work when nothing can be seen.
#
# drag_xy   arrayref [ $root_x, $root_y ]
#     During a drag this is the last position of the mouse, in root window
#     coordinates.  When not in drag 'drag_xy' is not in $self at all.  The
#     timer is stopped while drag_xy is set.  Only one of the two x or y are
#     used, according to 'vertical', but storing not much extra and it
#     smoothly handles the slightly freaky case of a change of orientation
#     in the middle of a drag.
#
# model_empty  boolean
#     True when we believe $self->{'model'} is empty.  Initialized in
#     SET_PROPERTY when the model is first set, then kept up to date in
#     _do_row_inserted() and _do_row_deleted().
#
#     The aim of this is to give _do_row_inserted() a way to be sure when
#     the model transitions from empty to non-empty, which provokes a resize
#     and a possible timer restart.
#
#     Testing for model length == 1 in _do_row_inserted() would be very
#     nearly enough, but not perfect.  If an earlier connected row-inserted
#     handler inserts yet another row in response to the first insertion
#     then by the time _do_row_inserted() runs it sees length==2.  This
#     would be pretty unusual, and probably needs 'iters-persist' on the
#     model for the first iter to remain valid past the extra model change,
#     but it's not completely outrageous.
#
# In RtoL mode all the x positions are measured from the right edge of the
# window or pixmap instead.  Only the expose and the cell renderer drawing
# must mirror those RtoL logical positions into LtoR screen coordinates.
#
# In vertical orientation the "x" values are in fact y positions and the
# "width"s are in fact heights.  Stand by for a search and replace to
# something neutral like "p" and "size" or whatever :-).
#

sub INIT_INSTANCE {
  my ($self) = @_;

  # the offscreen 'pixmap' already works as a form of double buffering, no
  # need for DBE
  $self->set_double_buffered (0);

  $self->{'want_index'}   = 0;
  $self->{'want_x'}       = 0;
  $self->{'row_widths'}   = {};
  $self->{'drawn_array'}  = [];
  $self->{'pixmap_end_x'} = 0;
  $self->{'visibility_state'} = 'initial';
  $self->{'run'}          = 1; # default yes
  $self->{'frame_rate'}   = DEFAULT_FRAME_RATE;
  $self->{'speed'}        = DEFAULT_SPEED;
  $self->{'vertical'}     = 0;
  
  $self->add_events (['visibility-notify-mask',
                      'button-press-mask',
                      'button-motion-mask',
                      'button-release-mask']);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'orientation') {
    return ($self->{'vertical'} ? 'vertical' : 'horizontal');
  } else {
    return $self->{$pname};
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->{$pname};
  ### SET_PROPERTY: $pname, $newval

  if ($pname eq 'orientation') {
    $oldval = $self->{'vertical'};
    $self->{'vertical'} = $newval = ($newval eq 'horizontal' ? 0 : 1);

  } else {
    $self->{$pname} = $newval;

    if ($pname eq 'model') {
      if (($oldval||0) == ($newval||0)) {
        # no change, avoid resize, redraw, etc
        return;
      }
      my $model = $newval;
      $self->{'model_empty'} = ! ($model && $model->get_iter_first);
      $self->{'model_ids'} = $model && do {
        Scalar::Util::weaken (my $weak_self = $self);
        my $ref_weak_self = \$weak_self;

        require Glib::Ex::SignalIds;
        Glib::Ex::SignalIds->new
            ($model,
             $model->signal_connect (row_changed    => \&_do_row_changed,
                                     $ref_weak_self),
             $model->signal_connect (row_inserted   => \&_do_row_inserted,
                                     $ref_weak_self),
             $model->signal_connect (row_deleted    => \&_do_row_deleted,
                                     $ref_weak_self),
             $model->signal_connect (rows_reordered => \&_do_rows_reordered,
                                     $ref_weak_self))
          };
    }
  }

  # updates ...

  # 'fixed_height_mode' turned to false provokes a resize, so as to look at
  # all the rows now, not just the first.  But don't resize when turning
  # fixed_height_mode to true since the size we have is based on all rows
  # and if the first row is truely representative then its size is the same
  # as already in use.
  #
  if ($pname eq 'model'
      || ($pname eq 'orientation' && $oldval != $newval)) {
    ### model or orientation change
    %{$self->{'row_widths'}} = ();
    $self->queue_resize;
    _pixmap_queue_draw ($self); # zap pixmap contents
  }

  if ($pname eq 'fixed_height_mode' && $oldval && ! $newval) {
    $self->queue_resize;
  }

  if ($pname eq 'model' || $pname eq 'run' || $pname eq 'frame_rate') {
    if ($pname eq 'frame_rate') {
      # Discard old timer ready for new rate.  Might like to carry over the
      # elapsed period in the old one, but it should be short enough not to
      # matter, and Glib doesn't seem to have much to help such a
      # calculation.
      delete $self->{'timer'};
    }
    _update_timer ($self);
  }
}


#------------------------------------------------------------------------------
# size desired and allocated

# 'size-request' class closure
sub _do_size_request {
  my ($self, $req) = @_;
  ### TickerView _do_size_request()

  $req->width (0);
  $req->height (0);

  my $model = $self->{'model'} || return;  # no size if no model
  my @cells = $self->GET_CELLS;
  @cells || return;  # no size if no cells

  my $sizefield = 3 - $self->{'vertical'}; # width vert, height horiz
  my $want_size = 0;
  for (my $iter = $model->get_iter_first;
       $iter;
       $iter = $model->iter_next ($iter)) {
    $self->_set_cell_data ($iter);
    foreach my $cell (@cells) {
      $want_size = max ($want_size,
                        ($cell->get_size($self,undef))[$sizefield]);
    }
    if ($self->{'fixed_height_mode'}) {
      ### one row only for fixed-height-mode
      last;
    }
  }

  if ($sizefield == 3) {
    $req->height ($want_size);
  } else {
    $req->width ($want_size);
  }
  ### decide size: $req->width."x".$req->height
}

# 'size_allocate' class closure
#
# This is also reached for cell renderer and attribute changes through
# $self->queue_resize in CellLayout::Base.
#
# For a move without a resize the pixmap at its current size could be
# retained.  Probably moves alone won't occur often enough to make that
# worth worrying about.
#
# Crib: no queue_draw() here, since the default redraw_on_alloc means that's
# done automatically (in gtk_widget_size_allocate()).
#
sub _do_size_allocate {
  my ($self, $alloc) = @_;
  ### TickerView _do_size_allocate()

  $self->signal_chain_from_overridden ($alloc);

  if (my $pixmap = $self->{'pixmap'}) {
    my ($want_width, $want_height) = _pixmap_desired_size ($self, $alloc);
    my ($got_width, $got_height) = $pixmap->get_size;
    if ($want_width != $got_width || $want_height != $got_height) {
      ### want new pixmap size
      $self->{'pixmap'} = undef;
      _pixmap_queue_draw ($self);
      return;
    }
  }
}


#-----------------------------------------------------------------------------
# expose and pixmap

# 'expose-event' class closure, getting Gtk2::Gdk::Event::Expose
sub _do_expose_event {
  my ($self, $event) = @_;
  if (DEBUG >= 2) {
    my $expose_size = ($self->{'vertical'}
                       ? $event->area->y + $event->area->height
                       : $event->area->x + $event->area->width);
    print "TickerView _do_expose_event count=",$event->count,
      " pixmap_redraw=",($self->{'pixmap_redraw'}?"yes":"no"),
        " expose_size=$expose_size\n";
  }

  my $expose_size = do { my $expose_rect = $event->area;
                         ($self->{'vertical'}
                          ? $expose_rect->y + $expose_rect->height
                          : $expose_rect->x + $expose_rect->width) };
  my $pixmap = _pixmap($self);

  my $x;
  if ($self->{'pixmap_redraw'}
      || ! defined ($x = _pixmap_find_want ($self, $expose_size))) {
    # want_index/want_x isn't in the pixmap at all
    _pixmap_empty ($self);
    $x = 0;

  } elsif ($x + $expose_size > $self->{'pixmap_size'}) {
    # want_index/want_x is in the pixmap, but there's not enough space after
    # it for the $expose_size
    if (DEBUG >= 2) { print "expose found $x but +$expose_size =",
                        $x + $expose_size,
                          " is past $self->{'pixmap_size'}, so shift\n"; }
    _pixmap_shift ($self, $x);
    $x = 0;
  }
  _pixmap_extend ($self, $x + $expose_size);

  if ($self->get_direction eq 'rtl') {
    # width when horiz, height when vert
    my $win_size = ($self->allocation->values)[2 + $self->{'vertical'}];
    $x = $self->{'pixmap_size'} - 1 - $win_size - $x;
  }
  my $win = $self->window;
  my $gc = $self->get_style->black_gc; # any gc for an XCopyArea
  $gc->set_clip_region ($event->region);
  $win->draw_drawable ($gc, $pixmap,
                       ($self->{'vertical'} ? (0,$x) : ($x,0)),  # src
                       0,0,                                      # dst
                       $win->get_size);
  $gc->set_clip_region (undef);
  return 0; # Gtk2::EVENT_PROPAGATE
}

sub _pixmap_find_want {
  my ($self, $expose_size) = @_;
  if (DEBUG >= 2) { print "  _pixmap_find_want",
                      " want_index=$self->{'want_index'}",
                        " want_x=$self->{'want_x'}\n"; }

  # the usual case here is _normalize() finding want_index still within its
  # row width and the previously determined drawn_want_at in drawn_array is
  # still wholely in a drawn portion of the pixmap

  my ($want_x, $want_index)
    = _normalize ($self, $self->{'want_x'}, $self->{'want_index'});
  if (! defined $want_x) {
    # no model, or model empty, or all rows zero width
    return ($self->{'want_x'} = 0);
  }
  $self->{'want_x'} = $want_x;
  $self->{'want_index'} = $want_index;

  $want_x = POSIX::floor ($want_x);
  my $drawn = $self->{'drawn_array'};
  my ($i, $x);

  # see if the cached 'drawn_want_at' is still the wanted index and in range
  if (defined ($i = $self->{'drawn_want_at'})
      && defined $drawn->[$i]
      && $drawn->[$i] == $want_index
      && ($x = $drawn->[$i+1] - $want_x) >= 0
      && $x + $expose_size <= $self->{'pixmap_size'}) {
    if (DEBUG >= 2) { print "    drawn_want_at still good\n"; }
    return $x;
  }

  if (DEBUG >= 2) { print "    seeking leftmost $want_index\n"; }
  for ($i = 0; $i < @$drawn; $i+=2) {
    if ($drawn->[$i] == $want_index
        && (($x = $drawn->[$i+1] - $want_x) >= 0)) {
      $self->{'drawn_want_at'} = $i;
      return $x;
    }
  }
  if (DEBUG >= 2) { local $,=' '; print "    not found in",@$drawn,"\n"; }
  return undef;
}

sub _pixmap_empty {
  my ($self) = @_;
  if (DEBUG) { print "_pixmap_empty to",
                 " want_index=$self->{'want_index'},",
                   "want_x=$self->{'want_x'}\n"; }

  $self->{'pixmap_redraw'} = 0;
  my $pixmap = _pixmap($self);
  my ($pixmap_width, $pixmap_height) = $pixmap->get_size;
  my $gc = $self->get_style->bg_gc ($self->state);
  $pixmap->draw_rectangle ($gc, 1, 0,0, $pixmap_width,$pixmap_height);

  @{$self->{'drawn_array'}} = ();
  $self->{'drawn_want_at'} = undef;
  %{$self->{'row_widths'}} = ();  # prune

  $self->{'pixmap_end_x'} = POSIX::floor ($self->{'want_x'});
}

sub _pixmap_shift {
  my ($self, $offset) = @_;
  if (DEBUG >= 2) {
    print "_pixmap_shift offset=$offset, from",
      " pixmap_end_x=",(defined $self->{'pixmap_end_x'} ? $self->{'pixmap_end_x'} : 'undef'),
        "\n";
  }
  my $pixmap_size = $self->{'pixmap_size'};
  my $drawn = $self->{'drawn_array'};

  # if the rightmost drawn goes past the end of the pixmap then discard it
  if (@$drawn
      && $drawn->[-1] + _row_width($self,$drawn->[-2]) > $pixmap_size) {
    if (DEBUG >= 2) { print "  last index=$drawn->[-2] past end, drop it\n"; }
    $self->{'pixmap_end_x'} = pop @$drawn;
    pop @$drawn; # index
    if (! @$drawn) { goto \&_pixmap_empty; }
  }

  my %prune_row_widths;  # keys are the indexes to be discarded
  my $last_nonpositive = 0;
  for (my $i = 0; $i < @$drawn; $i+=2) {
    if (($drawn->[$i+1] -= $offset) <= 0) {
      $last_nonpositive = $i;
      $prune_row_widths{$drawn->[$i]} = 1;
    } else {
      delete $prune_row_widths{$drawn->[$i]};
    }
  }
  my $end_x = ($self->{'pixmap_end_x'} -= $offset);
  splice @$drawn, 0, $last_nonpositive;

  # row_widths for rows shifted off at the left are dropped, unless they
  # also occur later in the drawn contents
  delete $prune_row_widths{$drawn->[0]};
  delete @{$self->{'row_widths'}} {keys %prune_row_widths}; # hash slice
  if (DEBUG >= 2) {
    local $,=' '; print "  prune row widths:", keys %prune_row_widths,"\n";
  }
  # CHECK-ME: probably not supposed to shift down to nothing ...
  if (! @$drawn) { goto \&_pixmap_empty; }

  if (DEBUG >= 2) { local $,=' '; print "  now drawn",@$drawn,"\n"; }

  my $pixmap = $self->{'pixmap'};
  my ($pixmap_width, $pixmap_height) = $pixmap->get_size;
  my $gc = $self->get_style->bg_gc ($self->state);

  # $end_x shouldn't be negative, but apply clamp $copy_size just in case.
  # Won't have $offset==0, thus won't have $src_x==$dst_x, so no sort circuits.
  #
  my $copy_size = max ($end_x, 0);
  my $clear_size = $pixmap_size - $copy_size;
  my ($src_x, $dst_x, $clear_x);
  if ($self->get_direction eq 'ltr') {
    #                              $pixmap_size
    # +------+----------------+----+
    # |      |   $copy_size   |    |
    # +------+----------------+----+
    #       $offset         $end_x    --> measuring rightwards
    #    /                /
    # +----------------+-----------+
    # |   $copy_size   |$clear_size|
    # +----------------+-----------+
    #
    $dst_x = 0;
    $src_x = $offset;
    $clear_x = $copy_size;
  } else {
    #                              $pixmap_size
    # +----+----------------+------+
    # |    |  $copy_size    |      |
    # +----+----------------+------+
    #      $end_x           $offset    <-- measuring leftwards
    #           \               \
    # +-----------+----------------+
    # |$clear_size|   $copy_size   |
    # +-----------+----------------+
    #
    $dst_x = $clear_size;
    $src_x = $dst_x - $offset;
    $clear_x = 0;
  }
  if (DEBUG >= 2) { print "  copy $src_x to $dst_x size=$copy_size\n";
                    print "  clear $clear_x size=$clear_size\n"; }

  if ($self->{'vertical'}) {
    $pixmap->draw_drawable ($gc, $pixmap,
                            0,$src_x,  # src
                            0,$dst_x,  # dst
                            $pixmap_width, $copy_size);  # width,height
    # clear the remainder
    $pixmap->draw_rectangle ($gc, 1,
                             0,$clear_x,
                             $pixmap_width, $clear_size);
  } else {
    # horizontal
    $pixmap->draw_drawable ($gc, $pixmap,
                            $src_x,0,  # src
                            $dst_x,0,  # dst
                            $copy_size, $pixmap_height);  # width,height
    # clear the remainder
    $pixmap->draw_rectangle ($gc, 1,
                             $clear_x,0,
                             $clear_size, $pixmap_height);
  }
}

# draw more at 'pixmap_end_x' to ensure it's not less than $target_x
sub _pixmap_extend {
  my ($self, $target_x) = @_;
  if (DEBUG >= 2) {
    my $last_index = $self->{'drawn'}->[-2];
    my $pixmap_size = $self->{'pixmap_size'};
    print "_pixmap_extend target_x=$target_x",
      " got last index=",(defined $last_index?$last_index:'undef'),
        ",x=$self->{'pixmap_end_x'}",
          ", pixmap_size=",(defined $pixmap_size ? $pixmap_size : '[undef]'),
            "\n";
  }
  if (DEBUG) {
    if ($target_x > $self->{'pixmap_size'}) {
      die "oops, target_x=$target_x bigger than pixmap ",
        $self->{'pixmap_size'};
    }
  }

  my $x = $self->{'pixmap_end_x'};
  if ($x >= $target_x) { return; } # if target already covered

  my $pixmap = _pixmap($self);
  my ($pixmap_width, $pixmap_height) = $pixmap->get_size;
  my $pixmap_size = $self->{'pixmap_size'};

  my $model = $self->{'model'};
  if (! $model) {
    ### no model set
  EMPTY:
    $self->{'pixmap_end_x'} = $pixmap_size;
    return;
  }

  # "pack_start"s first then "pack_end"s
  my @cellinfo_list = ($self->_cellinfo_starts,
                       reverse $self->_cellinfo_ends);
  if (! @cellinfo_list) {
    ### no cell renderers to draw with
    goto EMPTY;
  }

  my $all_zeros = _make_all_zeros_proc();
  my $ltor = ($self->get_direction eq 'ltr');
  my $row_widths = $self->{'row_widths'};
  my $drawn = $self->{'drawn_array'};
  my $vertical = $self->{'vertical'};

  my $index = $drawn->[-2];
  if (defined $index) {
    $index++;
  } else {
    $index = $self->{'want_index'};
  }
  my $iter = $model->iter_nth_child (undef, $index);

  for (;;) {
    if (! $iter) {
      # initial $index was past the end, or stepped iter_next() past the
      # end, either way wrap around
      $index = 0;
      $iter = $model->get_iter_first;
      if (! $iter) {
        ### model has no rows
        $x = $pixmap_size;
        last;
      }
    }

    push @$drawn, $index, $x;
    $self->_set_cell_data ($iter);

    my $row_size = 0;
    foreach my $cellinfo (@cellinfo_list) {
      my $cell = $cellinfo->{'cell'};
      if (! $cell->get('visible')) { next; }

      my (undef, undef, $width, $height) = $cell->get_size ($self, undef);
      my $rect;
      if ($vertical) {
        $rect = Gtk2::Gdk::Rectangle->new
          (0,  $ltor ? $x : $pixmap_height - 1 - $x - $height,
           $pixmap_width,  $height);
        $x += $height;
        $row_size += $height;
      } else {
        $rect = Gtk2::Gdk::Rectangle->new
          ($ltor ? $x : $pixmap_width - 1 - $x - $width,  0,
           $width,  $pixmap_height);
        $x += $width;
        $row_size += $width;
      }
      $cell->render ($pixmap, $self, $rect, $rect, $rect, []);
    }

    $row_widths->{$index} = $row_size;
    if (DEBUG >= 2) { print "  draw $index at x=",$x-$row_size,
                        " width $row_size\n"; }

    if ($all_zeros->($index, $row_size)) {
      ### all cell widths on all rows are zero
      $self->{'want_x'} = 0;
      $x = $pixmap_size;
      last;
    }

    $index++;
    if ($x >= $target_x) { last; }  # stop when target covered
    $iter = $model->iter_next ($iter);
  }

  $self->{'pixmap_end_x'} = min ($x, $pixmap_size);
  ### extended to pixmap_end_x: $self->{'pixmap_end_x'}
}

# _pixmap() returns 'pixmap', creating it if it doesn't already exist.
# The height is the same as the window height.
# The width is 1.5 * the window width, or half the screen width, whichever
# is bigger.
#
# The pixmap is designed to avoid drawing the same row repeatedly as it
# scrolls across.  The wider the pixmap the less often a full redraw will be
# needed.  The width used is therefore a compromise between the memory taken
# by a wide pixmap, versus redraws caused by a narrow pixmap.
#
# Twice the window width gives a reasonable amount of hidden pixmap
# buffering off the window ends.  However if the window is unusually narrow
# it could be much less than a typical row, so impose a minimum of half the
# screen width.
#
# (Maybe a maximum of say twice the screen width could be imposed too, so
# that a hugely wide window doesn't result in a massive pixmap.  But for a
# pixmap smaller than the window we'd have to notice what portion of the
# window is on-screen.  Probably that's much more trouble than it's worth.
# If you ask for a stupidly wide window then expect to have your pixmap
# memory used up. :-)
#
sub _pixmap {
  my ($self) = @_;
  return ($self->{'pixmap'} ||= do {
    ### _pixmap() create
    my ($pixmap_width, $pixmap_height)
      = _pixmap_desired_size ($self, $self->allocation);
    ### create size: "${pixmap_width}x${pixmap_height}"
    Gtk2::Gdk::Pixmap->new ($self->window, $pixmap_width, $pixmap_height, -1);
  });
}
use constant _PIXMAP_ALLOCATION_FACTOR => 1.5;
use constant _SCREEN_SIZE_FACTOR => 0.5;
sub _pixmap_desired_size {
  my ($self, $alloc) = @_;
  ### _pixmap_desired_size()
  my @pixmap_dims = ($alloc->width, $alloc->height);
  my $i = $self->{'vertical'}; # width for horiz, height for vert
  my $screen = $self->get_screen; # gtk 2.4 for celllayout, so have 2.2 screen
  my @screen_dims = ($screen->get_width, $screen->get_height);

  ### max: "alloc*"._PIXMAP_ALLOCATION_FACTOR." = ".($pixmap_dims[$i] * _PIXMAP_ALLOCATION_FACTOR)
  ### max: "screen*"._SCREEN_SIZE_FACTOR." = ".($screen_dims[$i] * _SCREEN_SIZE_FACTOR)
  $pixmap_dims[$i] = $self->{'pixmap_size'}
    = int (max ($pixmap_dims[$i] * _PIXMAP_ALLOCATION_FACTOR,
                $screen_dims[$i] * _SCREEN_SIZE_FACTOR));
  ### desire: "$pixmap_dims[0]x$pixmap_dims[1]"
  return @pixmap_dims;
}

sub _pixmap_queue_draw {
  my ($self) = @_;
  ### _pixmap_queue_draw()
  # zap 'drawn_array' to save work in _apply_remap
  $self->{'pixmap_redraw'} = 1;
  @{$self->{'drawn_array'}} = ();
  $self->queue_draw;
}

#-----------------------------------------------------------------------------
# row index widths and normalization

# Normalize $x,$index so that $x<=0 and $x+$row_width >= 0.
# The return is two new values ($x,$index).
# If $x==0 then $x,$index are returned unchanged.
# If there's no model, or the model is empty, the return is empty ().
# If all rows are zero width the return is $x==undef and $index unchanged.
#
sub _normalize {
  my ($self, $x, $index) = @_;

  my $model = $self->{'model'} || return;
  my $all_zeros = _make_all_zeros_proc();
  my $len = $model->iter_n_children(undef) || return;  # if model empty

  if ($x < 0) {
    # Here we're looking to see if the want_index row is entirely
    # off-screen, ie. if want_x + row_width (of that row) would still be
    # want_x <= 0.
    #
    # If _row_width() gives us a $iter, because it used it to get a row
    # width, then we keep it going for further rows.  If _row_width()
    # operates out of its cache then there's no iter.
    #
    ### forward from: "$index,$x"
    my $iter;

    for (;;) {
      my $row_width = _row_width ($self, $index, $iter);
      if ($x + $row_width > 0) {
        last;
      }
      if ($all_zeros->($index, $row_width)) {
        ### all cell widths on all rows are zero
        return (undef, $_[2]);  # with original $index
      }
      $x += $row_width;
      $index++;
      if ($index >= $len) {
        $index = 0;
        $iter = undef;
      } else {
        if ($iter) {
          $iter = $model->iter_next ($iter);
        }
      }
    }

  } else {
    # Here we're trying to bring $x back to <= 0, usually because a backward
    # scroll has pushed our want_x position to the right and we have to see
    # what the preceding row is and want position to draw it.
    #
    # Because there's no "iter_prev" there's no use of iters here, it ends
    # up a new iter_nth_child in _row_width() for every row not already
    # cached.  For a user scroll back just a short distance the previous row
    # is probably already cached (and even probably in the pixmap).
    #
    ### backward from: "$x,$index"

    while ($x > 0) {
      $index--;
      if ($index < 0) {
        $index = max (0, $len-1);
      }
      my $row_width = _row_width ($self, $index);
      if ($all_zeros->($index, $row_width)) {
        ### all cell widths on all rows are zero
        return (undef, $_[2]);  # with original $index
      }
      $x -= $row_width;
    }
  }
  #### now at "$index,$x"
  return ($x, $index);
}

# Return the width in pixels of row $index, or height when vertical.
# $iter is an iterator for $index, or undef to make one here if necessary.
# If an iterator is made then it's stored back to $_[2], as call-by-reference.
#
sub _row_width {
  my ($self, $index, $iter) = @_;

  my $row_widths = $self->{'row_widths'};
  my $row_width = $row_widths->{$index};
  if (defined $row_width) { return $row_width; }

  if (DEBUG) { print "  _row_width on $index, iter=",
                 (defined $iter ? $iter : 'undef'), "\n"; }
  if (! defined $iter) {
    my $model = $self->{'model'};
    $iter = $_[2] = $model && $model->iter_nth_child (undef, $index);
    if (! defined $iter) {
      if (DEBUG) { print "  _row_width index $index out of range\n"; }
      return 0;
    }
  }
  $self->_set_cell_data ($iter);

  my $sizefield = 2 + $self->{'vertical'}; # width horiz, height vert
  $row_width = 0;
  foreach my $cellinfo (@{$self->{'cellinfo_list'}}) {
    my $cell = $cellinfo->{'cell'};
    if (! $cell->get('visible')) { next; }
    $row_width += ($cell->get_size ($self,undef)) [$sizefield];
  }
  ### _row_width() calc: "$index is $row_width"
  return ($row_widths->{$index} = $row_width);
}

#------------------------------------------------------------------------------
# programmatic scrolling

sub scroll_to_start {
  my ($self) = @_;
  _scroll_to_pos ($self, 0, 0);
}

sub scroll_pixels {
  my ($self, $pixels) = @_;
  _scroll_to_pos ($self, $self->{'want_x'} - $pixels, $self->{'want_index'});
}

sub _scroll_to_pos {
  my ($self, $x, $index) = @_;
  #### _scroll_to_pos(): "x=$x index=$index"

  $self->{'want_index'} = $index;
  $self->{'want_x'} = $x;

  # If drawable(), ie. GTK_WIDGET_DRAWABLE(), is true, meaning widget
  # show()ed and window mapped, then draw after a server sync.  If unmapped
  # then programmatic scrolls just move the position around and the eventual
  # map will get an expose to draw.
  #
  if ($self->drawable) {
    $self->{'sync_call'} ||= do {
      my $weak_self = $self;
      Scalar::Util::weaken ($weak_self);
      Gtk2::Ex::SyncCall->sync ($self, \&_sync_call_handler, \$weak_self);
    };
  }
}
sub _sync_call_handler {
  my ($ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  #### TickerView _sync_call_handler()

  $self->{'sync_call'} = undef;

  # Recheck drawable(), GTK_WIDGET_DRAWABLE(), in case unmapped in between
  # the last scroll and the server sync reply.  If still mapped then do an
  # immediate draw via queue_draw and forced update.
  #
  # process_updates() normally runs under an idle at GDK_PRIORITY_REDRAW,
  # but don't wait to get down there.  Currently at GDK_PRIORITY_EVENTS from
  # the sync and the sync means now is a good time for a forced draw.
  #
  if ($self->drawable) {
    $self->queue_draw;
    $self->window->process_updates (1);
  }
}


#------------------------------------------------------------------------------
# drawing style changes

# 'direction_changed' class closure
sub _do_direction_changed {
  my ($self, $prev_dir) = @_;
  _pixmap_queue_draw ($self);

  # As of Gtk 2.18 the GtkWidget code in gtk_widget_real_direction_changed()
  # (previously called gtk_widget_direction_changed()) does a queue_resize(),
  # which is neither needed or wanted here.  But a direction change should
  # be infrequent and better make sure anything GtkWidget does in the future
  # gets run.
  $self->signal_chain_from_overridden ($prev_dir);
}

# 'notify' class closure
# SET_PROPERTY() is called only for own class properties, this default
# handler sees changes to those defined by the GtkWidget superclass (and all
# other sub and super classes)
sub _do_notify {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### TickerView _do_notify(): $pname

  if ($pname eq 'sensitive') {
    # gtk_widget_set_sensitive does $self->queue_draw, so just need to
    # invalidate pixmap contents here for a redraw
    ### redraw
    _pixmap_queue_draw ($self);
  }
  $self->signal_chain_from_overridden ($pspec);
}

# 'state_changed' class closure ($self, $state)
# 'style_set' class closure ($self, $prev_style)
sub _do_state_or_style_changed {
  my ($self, $arg) = @_;
  if (DEBUG) { print "TickerView state-changed or style-set '",
                 (defined $arg ? $arg : 'undef'),"'\n"; }
  _pixmap_queue_draw ($self);
  $self->signal_chain_from_overridden ($arg);
}


#------------------------------------------------------------------------------
# scroll timer
#
# _update_timer() starts or stops the timer according to the numerous
# conditions set out in that func.  In general the idea is not to run the
# timer when there's nothing to see and/or move: eg. the window is not
# visible, or there's nothing in the model+renderers.  Care must be taken to
# call _update_timer() when any of the conditions may have changed.
#
# The timer action itself is pretty simple, it just calls the public
# $self->scroll_pixels() to make the move, by an amount based on elapsed
# real time, per "OTHER NOTES" in the pod below.  The hairy stuff in
# scroll_pixels() collapsing multiple motions and drawing works just as well
# from the timer as it does from application uses of that func.  In fact the
# collapsing exists mainly to help if the timer runs a touch too fast for
# the server's drawing.
#

# _TIMER_PRIORITY is below the drawing priority GDK_PRIORITY_EVENTS in
# _sync_call_handler(), so drawing of the current position goes out before
# making a scroll to a new position.
#
# Try _TIMER_PRIORITY below GDK_PRIORITY_REDRAW too, to hopefully cooperate
# with redrawing of other widgets, letting their drawing go out before
# scrolling the ticker.
#
use constant _TIMER_PRIORITY => (GDK_PRIORITY_REDRAW + 10);

# _gettime() returns a floating point count of seconds since some fixed but
# unspecified origin time.
#
# clock_gettime(CLOCK_REALTIME) is preferred.  clock_gettime() always
# exists, but it croaks if there's no such C library func.  In that case
# fall back on the hires time(), which is whatever best thing Time::HiRes
# can do, probably gettimeofday() normally.
#
# Maybe it'd be worth checking clock_getres() to see it's a decent
# resolution.  It's conceivable some old implementations might do
# CLOCK_REALTIME just from the CLK_TCK times() counter, giving only 10
# millisecond resolution.  That's enough for a modest 10 or 20 frames/sec,
# but if attempting say 100 frames on a fast computer for ultra smoothness
# then higher resolution would be needed.
#
sub _gettime {
  return Time::HiRes::clock_gettime (Time::HiRes::CLOCK_REALTIME());
}
unless (eval { _gettime(); 1 }) {
  ### TickerView fallback to Time HiRes time() due to clock_gettime() error: $@
  no warnings;
  *_gettime = \&Time::HiRes::time;
}

# start or stop the scroll timer according to the various settings
sub _update_timer {
  my ($self) = @_;

  my $want_timer = $self->{'run'}
    && ! $self->{'paused_count'}
    && $self->mapped
    && $self->{'visibility_state'} ne 'fully-obscured'
    && $self->{'cellinfo_list'}
    && @{$self->{'cellinfo_list'}}  # renderer list not empty
    && $self->{'frame_rate'} > 0
    && ! defined $self->{'drag_xy'} # not in a drag
    && $self->{'model'}
    && ! $self->{'model_empty'};

  if (DEBUG) {
    print "  _update_timer run=", $self->{'run'},
      " paused=",      ($self->{'paused_count'}||'no'),
      " mapped=",      $self->mapped ? 1 : 0,
      " visibility=",  $self->{'visibility_state'},
      " model=",       ($self->{'model'} ? 'yes' : 'none'),
      " model_empty=", $self->{'model_empty'} || '0',
      " (iter_first=",  (! defined $self->{'model'} ? 'n/a)'
                          : $self->{'model'}->get_iter_first ? 'yes)' : 'no)'),
      " --> want ", ($want_timer ? 'yes' : 'no'), "\n";
  }

  $self->{'timer'} = $want_timer &&
    ($self->{'timer'}  # existing timer if already running
     || do {           # otherwise a new one
       my $period = POSIX::ceil (1000.0 / $self->{'frame_rate'});
       if (DEBUG) { print "TickerView start timer, $period ms\n"; }
       
       my $weak_self = $self;
       Scalar::Util::weaken ($weak_self);
       $self->{'prev_time'} = _gettime();
       require Glib::Ex::SourceIds;
       Glib::Ex::SourceIds->new
           (Glib::Timeout->add ($period, \&_do_timer, \$weak_self,
                                _TIMER_PRIORITY));
    });
}

sub _do_timer {
  my ($ref_weak_self) = @_;
  # shouldn't see an undef in $$ref_weak_self because the timer should be
  # stopped already by _do_unrealize in the course of widget destruction,
  # but if for some reason that hasn't happened then stop it now
  my $self = $$ref_weak_self || return 0; # Glib::SOURCE_REMOVE

  my $t = _gettime();
  my $delta = $t - $self->{'prev_time'};
  $self->{'prev_time'} = $t;

  # Watch out for the clock going backwards, don't want to scroll back.
  # Watch out for jumping wildly forwards too due to the process blocked for
  # a while, don't want to churn through some massive pixel count forwards.
  $delta = min (5, max (0, $delta));

  my $step = $self->{'speed'} * $delta;
  $self->scroll_pixels ($step);
  if (DEBUG >= 2) { print "_do_timer scroll $delta seconds, $step pixels,",
                      " to $self->{'want_x'}\n"; }
  return 1; # Glib::SOURCE_CONTINUE
}

# 'map' class closure ($self)
# 'unmap' class closure ($self)
#
# This is asking the widget to map or unmap itself, not map-event or
# unmap-event back from the server.
#
sub _do_map_or_unmap {
  my ($self) = @_;
  ### TickerView _do_map_or_unmap()

  # chain before _update_timer(), so the GtkWidget code sets or unsets the
  # mapped flag which _update_timer() will look at
  $self->signal_chain_from_overridden;
  _update_timer ($self);
}

# 'unrealize' class closure
# (asking the widget to unrealize itself)
#
# When a ticker is removed from a container only unrealize is called, not
# unmap then unrealize, hence an _update_timer() check here as well as
# _do_map_or_unmap() above.
#
sub _do_unrealize {
  my ($self) = @_;
  ### TickerView _do_unrealize()

  # chain before _update_timer(), so the GtkWidget code clears the mapped flag
  $self->signal_chain_from_overridden;

  @{$self->{'drawn_array'}} = ();  # full redraw if realized again later
  $self->{'pixmap'} = undef; # possible different depth if realized again later
  _update_timer ($self);
}

# 'visibility_notify_event' class closure
sub _do_visibility_notify_event {
  my ($self, $event) = @_;
  ### TickerView _do_visibility_notify_event(): $event->state
  $self->{'visibility_state'} = $event->state;
  _update_timer ($self);
  return $self->signal_chain_from_overridden ($event);
}


#------------------------------------------------------------------------------
# dragging
#
# The basic operation here is pretty simple, it's just a matter of calling
# the public $self->scroll_pixels() with each mouse move amount as reported
# by motion-notify.  The hairy stuff in scroll_pixels() to collapse moving
# and drawing works just as well for moves here as for application calls.
#
# If someone does a grab_pointer, either within the program or another
# client, then we'll no longer get motion notifies.  Should timer based
# scrolling resume immediately, or only on button release?  If the new grab
# is some unrelated action taking over then immediately might be best.  But
# only on button release may be more consistent, in having the timer
# scrolling resume only on button release.  The latter is done for now.
#
# If the window is moved during the drag, either repositioned by application
# code, or repositioned by the window manager etc, then it's possible to
# either
#
# 1. Let the displayed contents stay with the left edge of the window.
# 2. Let the displayed contents stay with the mouse, so it's like the
#    window move reveals a different portion.
#
# Neither is too difficult, but 1 is adopted since in 2 there's a bit of
# flashing when the server copies the contents with the move and they then
# have to be redrawn.  (Redrawn under size-allocate, since there's only
# configure-notify for a window move, no mouse motion-notify event.)
#
# Perhaps the double-buffering extension could help with the flashing, but
# it'd have to be applied to the parent window, and could only work when the
# move originates client-side, not say from the window manager.  For now 1
# is easier, and window moves during a drag should be fairly unusual anyway.
#
# To implement 1 the mouse position for dragging is maintained in root
# window coordinates.  This means it's independent of the ticker window
# position.  On that basis don't need to pay any attention to the window
# position, simply apply root window based mouse motion to scroll_pixels().
# Both x and y are maintained so that you can actually change the
# "orientation" property in the middle of a drag and still get the right
# result!
#

# if (0) {
#   my $bindings = Gtk2::BindingSet->new ('Gtk2__Ex__TickerView');
#   $bindings->entry_add_signal
#     (Gtk2::Gdk->keyval_from_name('Pointer_Button1'),[],
#      'start-drag');
#   $bindings->entry_add_signal
#     (Gtk2::Gdk->keyval_from_name('Pointer_Button1'),['release-mask'],
#      'end-drag');
#   # priority level "gtk" treating this as widget level default, for
#   # overriding by application or user RC
#   $bindings->add_path ('class', 'Gtk2__Ex__TickerView', 'gtk');
# }     

sub is_drag_active {
  my ($self) = @_;
  return (defined $self->{'drag_xy'});
}

# 'button_press_event' class closure, getting Gtk2::Gdk::Event::Button
sub _do_button_press_event {
  my ($self, $event) = @_;
  #### TickerView button_press: $event->button
  if ($event->button == 1) {
    $self->{'drag_xy'} = [ $event->root_coords ];
    _update_timer ($self); # stop timer
  }
  return $self->signal_chain_from_overridden ($event);
}

# 'motion_notify_event' class closure, getting Gtk2::Gdk::Event::Motion
#
# Use of is_hint() supports 'pointer-motion-hint-mask' perhaps set by the
# application or some add-on feature.  Dragging only runs from a mouse
# button so for now it's enough to use get_pointer() rather than
# $display->get_state().
#
sub _do_motion_notify_event {
  my ($self, $event) = @_;
  #### TickerView _do_motion_notify_event()
  if (defined $self->{'drag_xy'}) { # ignore motion/drags of other buttons
    _drag_scroll ($self, $event);
  }
  return $self->signal_chain_from_overridden ($event);
}

# 'button_release_event' class closure, getting Gtk2::Gdk::Event::Button
#
sub _do_button_release_event {
  my ($self, $event) = @_;
  #### TickerView _do_button_release_event(): $event->button

  if (defined $self->{'drag_xy'} && $event->button == 1) {
    _drag_scroll ($self, $event); # final dragged position from this event
    delete $self->{'drag_xy'};
    _update_timer ($self); # restart timer
  }
  return $self->signal_chain_from_overridden ($event);
}

# $event is either Gtk2::Gdk::Event::Motion or Gtk2::Gdk::Event::Button
sub _drag_scroll {
  my ($self, $event) = @_;
  if (DEBUG >= 2) { print "  _drag_scroll ",
                      ($event->can('is_hint') && $event->is_hint
                       ? 'hint' : 'not-hint'), "\n"; }

  my @xy = ($event->can('is_hint') && $event->is_hint
            ? $self->get_root_window->get_pointer
            : $event->root_coords);

  # step is simply how much the new position has moved from the old one
  my $i = $self->{'vertical'};
  my $step = $self->{'drag_xy'}->[$i] - $xy[$i];
  @{$self->{'drag_xy'}} = @xy;

  if ($self->get_direction eq 'rtl') { $step = -$step; }
  if (DEBUG >= 2) { print "    step $step\n"; }
  $self->scroll_pixels ($step);
}

#------------------------------------------------------------------------------
# mouse wheel scroll

my %direction_sign = (up => -1,
                      down => 1,
                      left => -1,
                      right => 1);
my %direction_is_vertical = (up => 1,
                             down => 1,
                             left => 0,
                             right => 0);
# 'scroll-event' class closure, getting Gtk2::Gdk::Event::Scroll
sub _do_scroll_event {
  my ($self, $event) = @_;
  #### TickerView scroll-event: $event->direction
  my $dir = $event->direction;
  my $vertical = $self->{'vertical'};

  # width when horiz, height when vert
  my $step = ($self->allocation->values)[2 + $vertical]
    * ($event->state & 'control-mask' ? 0.9 : 0.1)
      * $direction_sign{$dir};
  unless ($direction_is_vertical{$dir} ^ $vertical) {
    if ($self->get_direction eq 'rtl') { $step = - $step; }
  }
  $self->scroll_pixels ($step);
  return $self->signal_chain_from_overridden ($event);
}

#------------------------------------------------------------------------------
# renderer changes

sub _cellinfo_list_changed {
  my ($self) = @_;
  ### TickerView _cellinfo_list_changed()
  %{$self->{'row_widths'}} = ();
  _pixmap_queue_draw ($self);
  _update_timer ($self);    # possible newly empty or non-empty cellinfo list
  $self->SUPER::_cellinfo_list_changed;
}

sub _cellinfo_attributes_changed {
  my ($self) = @_;
  ### TickerView _cellinfo_attributes_changed()
  %{$self->{'row_widths'}} = ();
  _pixmap_queue_draw ($self);
  $self->SUPER::_cellinfo_attributes_changed;
}


#------------------------------------------------------------------------------
# model changes
#
# The main optimization attempted here is to do nothing when changed rows
# are off-screen, or rather off-pixmap, with the aim of doing no drawing
# when undisplayed parts of the model change.
#
# In practice you have to be in fixed-height-mode for off-screen updates to
# do nothing at all since in the default "all rows sized" mode any change or
# insert or delete has to re-examine all rows.  The insert could check only
# for an increase, but doesn't do that currently.
#

# 'row-changed' on the model
sub _do_row_changed {
  my ($model, $path, $iter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### _do_row_changed() path: $path->to_string
  $path->get_depth == 1 || return;  # only top rows of the model
  my ($index) = $path->get_indices;

  # recalculate width
  delete $self->{'row_widths'}->{$index};

  # fixed-height-mode means every row is the same height so a change to any
  # one of them doesn't affect the previously calculated size -- even when
  # it's a change to the representative row 0.  Believe that's how
  # GtkTreeView interprets its fixed-height-mode, and it has the happy
  # effect of not provoking repeated rechecks if row 0 changes a lot.
  #
  # In non fixed-height-mode, however, every row change potentially
  # increases or decreases the height.  (Or at least a change to the highest
  # could decrease, or a change to any of the equal highest could increase.)
  #
  if (! $self->{'fixed_height_mode'}) {
    $self->queue_resize;
  }

  # if changed row is in pixmap then redraw
  _pixmap_queue_draw_if_index ($self, $index);
}

# 'row-inserted' on the model
sub _do_row_inserted {
  my ($model, $path, $iter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### _do_row_inserted() path: $path->to_string
  $path->get_depth == 1 || return;  # only top rows
  my ($index) = $path->get_indices;

  if ($self->{'model_empty'}) {
    # empty -> non-empty restarts timer if stopped due to empty
    _update_timer ($self);
  }
  if ($self->{'model_empty'} || ! $self->{'fixed_height_mode'}) {
    # empty -> non-empty changes size from zero to something;
    # and any new row insertion resizes when non fixed-height-mode
    # (could just see if this new row bigger than already calculated)
    $self->queue_resize;
  }
  $self->{'model_empty'} = 0;

  _pixmap_queue_draw_if_index ($self, $index);
  _apply_remap ($self,
                # called as $new_index = $remap->($old_index)
                sub { $_[0] >= $index ? $_[0] + 1 : $_[0] });
}

# 'row-deleted' on the model
sub _do_row_deleted {
  my ($model, $path, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### _do_row_deleted() path: $path->to_string
  $path->get_depth == 1 || return;  # only top rows
  my ($index) = $path->get_indices;

  delete $self->{'row_widths'}->{$index};

  my $model_empty = $self->{'model_empty'} = ! $model->get_iter_first;
  if ($model_empty) {
    # becoming empty, stop timer while empty
    _update_timer ($self);
  }
  if ($model_empty || ! $self->{'fixed_height_mode'}) {
    # becoming empty will become zero size;
    # or if ever row checked then any delete affects height
    # (actually only a delete of the highest row affects it, if wanted to
    # record which was the biggest)
    $self->queue_resize;
  }

  # want_index and row_widths move down.
  # If want_index itself is deleted then leave it unchanged to show from the
  # next following, and if it was the last row then it'll wrap around in the
  # draw.
  #
  _pixmap_queue_draw_if_index ($self, $index);
  _apply_remap ($self,
                # called as $new_index = $remap->($old_index)
                sub { $_[0] > $index ? $_[0] - 1 : $_[0] });
}

# 'rows-reordered' signal on the model
sub _do_rows_reordered {
  my ($model, $reordered_path, $reordered_iter, $aref, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### _do_rows_reordered()
  if (defined $reordered_iter) { return; }   # top rows only

  # $oldpos == $aref->[$newpos], ie. aref says where the row used to be.
  # $remap{$oldpos} == $newpos, ie. where the old has been sent
  # Building a hash might be a bit unnecessary if not much to remap, but
  # it's less code than a linear search or similar.
  #
  my %remap;
  @remap{@$aref} = (0 .. $#$aref);
  if (DEBUG) { require Data::Dumper;
               print " remap ",
                 Data::Dumper->new([\%remap],['remap'])->Sortkeys(1)->Dump; }
  # want_index and row_widths permute
  # allow for indexes out of range in case want_index yet unnormalized
  # called as $new_index = $remap->($old_index)
  my $remap = sub { defined $remap{$_[0]} ? $remap{$_[0]} : $_[0] };

  # Set the pixmap to redraw if the drawn rows are no longer a contiguous
  # run, modulo the model length.  This is a bit of work to check, but the
  # pixmap contents can be retained nicely under rotations or shuffle ups or
  # downs that don't affect the displayed portion.
  my $len = scalar @$aref;
  my $delta_func = sub { ($_[0] - $remap->($_[0]) + $len) % $len };
  my $drawn = $self->{'drawn_array'};
  if (@$drawn) {
    my $want_delta = $delta_func->($drawn->[0]);
    for (my $i = 2; $i < @$drawn; $i += 2) {
      if ($delta_func->($drawn->[$i]) != $want_delta) {
        _pixmap_queue_draw ($self);  # shuffled about, must redraw
        last;
      }
    }
  }
  _apply_remap ($self, $remap);
}

# set the pixmap to redraw if $index is drawn in it
sub _pixmap_queue_draw_if_index {
  my ($self, $index) = @_;
  my $drawn = $self->{'drawn_array'};
  for (my $i = 0; $i < @$drawn; $i += 2) {
    if ($drawn->[$i] == $index) {
      _pixmap_queue_draw ($self);
      return 1;
    }
  }
  return 0;
}

# Remap indexes in want_index, drawn_array, and row_widths.  drawn_array is
# empty at this point if it's going to be redrawn
sub _apply_remap {
  my ($self, $remap) = @_;
  ### _apply_remap(): $remap

  if (defined (my $want_index = $self->{'want_index'})) {
    if (DEBUG) { print "  want_index $want_index to ",
                   $remap->($want_index),"\n"; }
    $self->{'want_index'} = $remap->($want_index);
  }
  my $drawn = $self->{'drawn_array'};
  if (@$drawn) {
    for (my $i = 0; $i < @$drawn; $i += 2) {
      $drawn->[$i] = $remap->($drawn->[$i]);
    }
  }
  _hash_keys_remap ($self->{'row_widths'}, $remap);
}

# modify the keys in %$href by $newkey = $func->($oldkey)
# the value associated with $oldkey moves to $newkey
#
sub _hash_keys_remap {
  my ($href, $func) = @_;
  %$href = map { ($func->($_), $href->{$_}) } keys %$href;
}


#------------------------------------------------------------------------------
# generic helpers

# _make_all_zeros_proc() returns a procedure to be called
# $func->($index,$width) designed to protect against every $index having a
# zero $width.
#
# $func returns true until it sees an $index==0 and then a second $index==0,
# with all calls having $width==0.  The idea is that if the drawing,
# scrolling or whatever loop has gone from $index zero all the way up and
# around back to $index zero again, and all the $width's seen are zero, then
# it should bail out.
#
# Any non-zero $width seen makes the returned procedure always return true.
# It might be only a single index position out of thousands, but that's
# enough.
#
sub _make_all_zeros_proc {
  my $seen_nonzero = 0;
  my $count_index_zero = 0;
  return sub {
    my ($index, $width) = @_;
    if ($width != 0) { $seen_nonzero = 1; }
    if ($index == 0) { $count_index_zero++; }
    return (! $seen_nonzero) && ($count_index_zero >= 2);
  }
}


#------------------------------------------------------------------------------
# other method funcs

sub get_path_at_pos {
  my ($self, $x, $y) = @_;
  ### get_path_at_pos(): "$x,$y"

  # Go from the want_x/want_index desired position, even if the drawing
  # isn't yet actually displaying that.  This makes most sense after a
  # programmatic scroll, and if it's a user button press then the display
  # will only be a moment away from showing that want_x/want_index position.
  #
  my $index = $self->{'want_index'};
  $x -= $self->{'want_x'};
  if (DEBUG) { print "  adj for want_x=",$self->{'want_x'},", to x=$x\n"; }

  ($x, $index) = _normalize ($self, -$x, $index);
  if (DEBUG) { print "  got ", (defined $x ? $x : 'undef'),
                 ",",(defined $index ? $index : 'undef'),"\n"; }
  if (defined $x) {
    return Gtk2::TreePath->new_from_indices ($index);
  } else {
    return undef;
  }
}

1;
__END__

=head1 NAME

Gtk2::Ex::TickerView -- scrolling ticker display widget

=for test_synopsis my ($model)

=head1 SYNOPSIS

 use Gtk2::Ex::TickerView;
 my $ticker = Gtk2::Ex::TickerView->new (model => $model);
 my $renderer = Gtk2::CellRendererText->new;
 $ticker->pack_start ($renderer, 0);
 $ticker->set_attributes ($renderer, text => 0); # column

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::TickerView> is a subclass of C<Gtk2::DrawingArea>, but that
might change so it's recommended you only rely on C<Gtk2::Widget>.

    Gtk2::Widget
      Gtk2::DrawingArea
        Gtk2::Ex::TickerView

The interfaces implemented are:

    Gtk2::Buildable (Gtk 2.12 and up)
    Gtk2::CellLayout

The C<orientation> property is compatible with the Gtk2::Orientable
interface, but that interface can't be added as of Perl-Gtk 1.222.

=head1 DESCRIPTION

A C<Gtk2::Ex::TickerView> widget displays items from a C<Gtk2::TreeModel>
scrolling across the window, like a news bar or stock ticker.

    +----------------------------------------------------------+
    | st item  * The second item  * The third item   * The fou |
    +----------------------------------------------------------+
        <---- scrolling

Or in C<vertical> orientation it scrolls upwards.

    +-------+
    | Two   |  ^
    | Three |  |
    | Four  |  | scrolling
    | Five  |  |
    | Six   |  |
    | ...   |
    +-------+

Items are drawn with one or more C<Gtk2::CellRenderer> objects set into the
TickerView as per the CellLayout interface (see L<Gtk2::CellLayout>).  For
example to scroll text you can use C<Gtk2::CellRendererText> as a renderer.

=head2 Dragging

Mouse button 1 is setup for the user to drag the display back and forwards.
This is good to go back and see something that's just moved off the edge, or
to skip past boring bits.  Perhaps in the future the button used will be
customizable.

Mouse wheel scrolling moves the display back and forwards by 10% of the
window, or a page 90% if the control key is held down.  An up/down scroll
will act on a horizontal ticker too, advancing or reversing, which is handy
for a mouse with only an up/down wheel.  Similarly a left/right scroll on a
vertical ticker.  But this is a bit experimental and might change or become
customizable.

=head2 Layout

If two or more renderers are set then they're drawn one after the other for
each item, ie. row of the model.  For example you could have a
C<Gtk2::CellRendererPixbuf> to draw an icon then a C<Gtk2::CellRendererText>
to draw some text and they scroll across together (or upwards above each
other when vertical).  The icon could use the row data, or just be a fixed
image to go before every item.

     +-----------------------------------------------+
     |    +--------++--------++--------++--------+   |
     | ...| Pixbuf || Text   || Pixbuf || Text   |...|
     |    | row 35 || row 35 || row 36 || row 36 |   |
     |    +--------++--------++--------++--------+   |
     +-----------------------------------------------+

The display and scrolling direction follow the left-to-right or
right-to-left of C<set_direction> (see L<Gtk2::Widget>).  For C<ltr> mode
item 0 starts at the left of the window and items scroll off to the left.
For C<rtl> item 0 starts at the right of the window and items scroll to the
right.

    +----------------------------------------------------------+
    | m five  * item four  * item three  * item two  * item on |
    +----------------------------------------------------------+
                        rtl mode, scrolling ----->

In vertical mode C<ltr> scrolls upwards and C<rtl> scrolls downwards.  This
doesn't make as much sense as it does horizontally.  (Perhaps it should
change, though if you have to set vertical orientation it's not too terrible
that C<set_direction> is the slightly unusual case of a downwards scroll.)

Within each renderer cell any text or drawing direction is a matter for that
renderer.  For example in C<Gtk2::CellRendererText> Pango recognises
right-to-left scripts such as Arabic based on the characters and shouldn't
need any special setups.  (But if you want to rotate 90 degrees for
something vertical it might be much trickier.  Just setting text "gravity"
doesn't work.  See F<examples/vertical-rottext.pl> in the TickerView sources
for one way to do it.)

Currently only a list style model is expected, meaning only a single level,
and only that topmost level of the model is drawn.  For example a
C<Gtk2::ListStore> suits.  Perhaps in the future something will be done to
descend into and draw subrows too.

The whole Gtk model/view/layout/renderer/attributes as used here is
ridiculously complicated.  Its power comes when showing a big updating list
or wanting customized drawing, but the amount of code to get something on
the screen is not nice.  Have a look at "Tree and List Widget Overview" in
the Gtk reference manual if you haven't already.  Then F<examples/simple.pl>
in the TickerView sources is more or less the minimum to actually display
something.

=head1 FUNCTIONS

=over 4

=item C<< $ticker = Gtk2::Ex::TickerView->new (key => value, ...) >>

Create and return a new C<Gtk2::Ex::TickerView> widget.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new >> (see
L<Glib::Object>).

=item C<< $ticker->scroll_pixels ($n) >>

Scroll the ticker contents across by C<$n> pixels.  Postive C<$n> moves in
the normal scrolled direction or negative goes backwards.

The display position is maintained as a floating point value so fractional
C<$n> amounts accumulate until a whole pixel step is reached.

=item C<< $ticker->scroll_to_start () >>

Scroll the ticker contents back to the start, ie. to show the first row of
the model at the left end of the window (or upper end for vertical, or right
end for C<rtl>, or bottom end for vertical plus C<rtl>!).

=item C<< $path = $ticker->get_path_at_pos ($x, $y) >>

Return a C<Gtk2::TreePath> which is the model row displayed at C<$x>,C<$y>,
or return C<undef> if there's nothing displayed there.  There can be nothing
if no C<model> is set, or it has no rows, or all rows are zero width or not
visible (the renderer C<visible> property).

C<$x> can be outside the window, in which case the item which would be shown
at that point is still returned.  C<$y> is currently ignored, since all
items simply use the full window height.  Perhaps in the future a C<$y>
outside the window height will cause an C<undef> return.

=back

=head1 OBJECT PROPERTIES

=over 4

=item C<model> (object implementing C<Gtk2::TreeModel>, default undef)

This is any C<Glib::Object> implementing the C<Gtk2::TreeModel> interface,
for example a C<Gtk2::ListStore>.  It supplies the data to be displayed.
Until this is set the ticker is blank.

=item C<run> (boolean, default true)

Whether to run the ticker, ie. to scroll it across under a timer.  If false
then the ticker just draws the items at its current position without moving
(except by the programatic scroll functions above, or user dragging with
mouse button 1).

=item C<speed> (floating point pixels per second, default 25)

The speed the items scroll across, in pixels per second.

=item C<frame-rate> (floating point frames per second, default 4)

The number of times each second the ticker moves and redraws.  Each move
will be C<speed> divided by C<frame-rate> many pixels.

The current current code uses the Glib main loop timer so the frame rate
becomes integer milliseconds for actual use.  A minimum 1 millisecond is
imposed, meaning frame rates more than 1000 are treated as 1000.  Of course
1000 frames a second is pointlessly high.

=item C<orientation> (C<Gtk2::Orientation> enum, default C<"horizontal">)

If set to C<"vertical"> the ticker items are drawn vertically from the top
of the window downwards, and scroll up the screen.  Or with C<set_direction>
of C<rtl> mode the direction reverses so they're drawn from the bottom of
the window upwards, and scroll down the screen.

(The name C<rtl> doesn't make a great deal of sense in vertical mode.
Something to reverse the direction is certainly desired, but perhaps it
shouldn't be the LtoR/RtoL setting ...)

=item C<fixed-height-mode> (boolean, default false)

If true then assume all rows in the model have the same height and that it
doesn't change.  This allows the ticker to get its desired height by asking
the renderers about just one row of the model, instead of going through them
all and resizing on every insert, delete or change.  If the model is big
this is a significant speedup.

If you force a height with C<set_size_request> in the usual widget fashion
then you should turn on C<fixed-height-mode> too because even with
C<set_size_request> the sizing mechanism ends up running the widget size
code even though it then overrides the result.

=back

The C<visible> property in each cell renderer is recognised and a renderer
that's not visible is skipped and takes no space.  C<visible> can be set
permanently in the renderer to suppress it entirely, or controlled with the
attributes mechanism or data setup function to suppress have it just for
selected rows of the model.

Suppressing lots of rows using C<visible> might be a bit slow since
TickerView must setup the renderers for each row to see the state.
A C<Gtk2::TreeModelFilter> may be a better way to pick out a small number of
desired rows from a very big model.

=head1 BUILDABLE

TickerView implements the C<Gtk2::Buildable> interface of Gtk 2.12 and up,
allowing C<Gtk2::Builder> to construct a ticker.  The class name is
C<Gtk2__Ex__TickerView> and renderers and attributes are added as children
per C<Gtk2::CellLayout>.  Here's a sample, or see F<examples/builder.pl> in
the TickerView sources for a complete program,

    <object class="Gtk2__Ex__TickerView" id="myticker">
      <property name="model">myliststore</property>
      <child>
        <object class="GtkCellRendererText" id="myrenderer">
          <property name="xpad">10</property>
        </object>
        <attributes>
          <attribute name="text">0</attribute>
        </attributes>
      </child>
    </object>

But see L<Gtk2::Ex::CellLayout::Base/BUILDABLE INTERFACE> for caveats about
widget superclass tags (like the "accessibility" settings) which end up
unavailable (as of Gtk2-Perl 1.222 at least).

=head1 OTHER NOTES

The Gtk reference documentation for C<GtkCellLayout> doesn't really describe
how C<pack_start> and C<pack_end> order the cells, but it's the same as
C<GtkBox> and a description can be found there.  Basically each cell is
noted as "start" or "end", with "starts" drawn from the left and "ends" from
the right (vice versa in RtoL mode).  In a TickerView the ends immediately
follow the starts, there's no gap in between, unlike say in a C<Gtk2::HBox>.
(Which means the "expand" parameter is ignored currently.)  See
F<examples/order.pl> in the sources for a demonstration.

When the model has no rows the TickerView's desired height from
C<size_request> is zero.  This is bad if you want a visible but blank area
when there's nothing to display.  But there's no way TickerView can work out
a height when it's got no data at all to set into the renderers.  You can
try calculating a fixed height from a sample model and C<set_size_request>
to force that, or alternately have a "no data" row displaying in the model
instead of letting it go empty, or even switch to a dummy model with a "no
data" row when the real one is empty.

=head2 Drawing

Cells are drawn into an off-screen pixmap which is copied to the window at
successively advancing X positions as the ticker scrolls across.  The aim is
to run the model fetching and cell rendering just once for each row as it
appears on screen.  This is important because the model+renderer mechanism
is generally much too slow and bloated to call at frame-rate times per
second.

The drawing for scroll movement goes through a SyncCall (see
L<Gtk2::Ex::SyncCall>) so that after drawing one frame the next doesn't go
out until hearing back from the server that it finished the previous.  This
ensures a high frame rate doesn't flood the server with more drawing than it
can keep up with, but instead dynamically caps at client+server capability.

Scroll movements are calculated from elapsed time using
C<clock_gettime(CLOCK_REALTIME)> when available or high-res system time
otherwise (see C<Time::HiRes>).  This means the display moves at the
C<speed> setting even if drawing is not keeping up with the requested
C<frame-rate>.  Slow frame rates can occur on the client side if the main
loop is busy doing other things (or momentarily blocked completely), or can
be on the X server side if it's busy with other drawing etc.

=head1 SEE ALSO

L<Gtk2::CellLayout>, L<Gtk2::TreeModel>, L<Gtk2::CellRenderer>,
L<Gtk2::Ex::CellLayout::Base>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-tickerview/index.html>

=head1 COPYRIGHT

Copyright 2007, 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-TickerView.  If not, see L<http://www.gnu.org/licenses/>.

=cut
