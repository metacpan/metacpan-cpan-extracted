# stay at end when resize ...
#
# size-allocate is run-first, so for a shrink would have to keep track of
# whether the end of the text was previously visible



# Copyright 2009, 2010, 2011, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::TextView::FollowAppend;
use strict;
use warnings;
use Gtk2;
use Glib::Ex::SignalIds;

our $VERSION = 11

use constant DEBUG => 0;

sub new {
  my ($class, $textview) = @_;

  require Scalar::Util;

  my $self = bless { textview => $textview }, $class;
  Scalar::Util::weaken ($self->{'textview'});

  my $weak_self = $self;
  Scalar::Util::weaken ($weak_self);

  $self->{'textview_ids'} = Glib::Ex::SignalIds->new
    ($textview,
     $textview->signal_connect ('notify::buffer', \&_connect_textbuf,
                                \$weak_self));
  # initial textbuf connection
  _connect_textbuf ($textview, undef, \$weak_self);

  return $self;
}
sub _connect_textbuf {
  my ($textview, $pspec, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my $textbuf = $textview->get_buffer;
  $self->{'textbuf_ids'} = $textbuf && Glib::Ex::SignalIds->new
    ($textbuf,
     $textbuf->signal_connect_after ('insert-text',
                                     \&_textbuf_insert,
                                     $ref_weak_self),
     $textbuf->signal_connect_after ('insert-pixbuf',
                                     \&_textbuf_insert_pixbuf_or_anchor,
                                     $ref_weak_self),
     $textbuf->signal_connect_after ('insert-child-anchor',
                                     \&_textbuf_insert_pixbuf_or_anchor,
                                     $ref_weak_self));
}

# 'insert-pixbuf' and 'insert-child-anchor' on textbuf
sub _textbuf_insert_pixbuf_or_anchor {
  my ($textbuf, $iter, $pixbuf_or_anchor, $ref_weak_self) = @_;
  _textbuf_insert ($textbuf, $iter, undef, 1, $ref_weak_self);
}

# 'insert' handler on textbuf
sub _textbuf_insert {
  my ($textbuf, $iter, $text, $textlen, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my $end_iter = $textbuf->get_end_iter;

  if (DEBUG) {
    my $cursor_mark = $textbuf->get_insert;
    my $cursor_iter = $textbuf->get_iter_at_mark ($cursor_mark);
    my $insert_iter = $textbuf->get_iter_at_offset
      ($iter->get_offset - $textlen);
    print "FollowAppend ",
      " insert=", $insert_iter->get_offset, " len=$textlen,",
        " iter=", $iter->get_offset,
          " cursor=", $cursor_iter->get_offset,
            " end=", $end_iter->get_offset,
              " charcount=", $textbuf->get_char_count,
                "\n";
    print "  text=",(defined $text ? "'$text'" : "undef"),"\n",
  }

  $iter->equal($end_iter) or return;

  my $cursor_mark = $textbuf->get_insert;
  my $cursor_iter = $textbuf->get_iter_at_mark ($cursor_mark);
  $cursor_iter->equal($end_iter) or return;

  my $insert_iter = $textbuf->get_iter_at_offset
    ($iter->get_offset - $textlen);
  my $textview = $self->{'textview'};
  _iter_is_visible ($textview, $insert_iter) or return;

  $textview->scroll_to_mark ($cursor_mark, 0, 0, 0,0);
}

# return true if $iter is visible in $textview
sub _iter_is_visible {
  my ($textview, $iter) = @_;
  my $visible_rect = $textview->get_visible_rect;
  my $iter_rect = $textview->get_iter_location ($iter);
  if (DEBUG) { print "  visible rect ",
                 $visible_rect->x,",",$visible_rect->y," ",
                   $visible_rect->width,"x",$visible_rect->height,
                     " height to ",$visible_rect->y+$visible_rect->height,"\n";
               print "  iter rect ",
                 $iter_rect->x,",",$iter_rect->y," ",
                   $iter_rect->width,"x",$iter_rect->height,
                     " height to ",$iter_rect->y+$iter_rect->height,"\n";
             }

  # if y1+h1 < y2 then rect1 is entirely above rect2, or if y2+h2 < y1 then
  # rect2 is entirely above rect1; if neither then there's overlap
  return ! ($visible_rect->y + $visible_rect->height < $iter_rect->y
            || $iter_rect->y + $iter_rect->height < $visible_rect->y);
}

1;
__END__

=head1 NAME

Gtk2::Ex::TextView::FollowAppend -- make a TextView follow appended text

=head1 SYNOPSIS

 use Gtk2::Ex::TextView::FollowAppend;
 Gtk2::Ex::TextView::FollowAppend->new ($textview);

=head1 DESCRIPTION

B<Caution!  This is preliminary.  It will probably move to the WidgetBits
dist and might get a rename, so don't use it yet, or only give it a try at
your own peril!  :-)>

FollowAppend sets up a TextView so it automatically scrolls to follow text
added at the end of the TextBuffer.  The effect is like Emacs
C<compilation-scroll-output> and it's good for following text progressively
added by a background task or subprocess, yet still allow the user to scroll
to see earlier output.

A scroll is done when

=over

=item *

Text, pixbuf or child anchor is inserted at the end of the TextBuffer.
Insertions elsewhere are ignored.

=item *

The cursor mark is at end of the TextBuffer.  So if you've moved the cursor
up to look at or copy something else then the view is not scrolled away from
there.

=item *

The previous end position, from before the insert, is visible.  So if you've
scrolled up just with the scroll bar to see earlier parts of the buffer it's
not forcibly moved to the end.

=back

=head1 FUNCTIONS

=head2 Creation

=over 4

=item C<< $follow = Gtk2::Ex::TextView::FollowAppend->new ($textview) >>

Create and return a FollowAppend object which makes C<$textview> follow
output appended to its TextBuffer.

The FollowAppend works with whatever TextBuffer, if any, is set in
C<$textview> at a given time.  It doesn't need a textbuf set initially, and
any textbuf can be changed or unset later.

C<$follow> only keeps a weak reference to C<$textview> so the mere
FollowAppend feature doesn't keep C<$textview> alive if nobody else cares if
it lives or dies.  On that basis it's safe to hold C<$follow> in the hash of
C<$textview> itself,

    $textview->{'follow'} = Gtk2::Ex::TextView::FollowAppend->new($textview);

If the C<$follow> object is destroyed it removes its setups from the
C<$textview>, so be sure to save C<$follow> somewhere.

=back

=head1 SEE ALSO

L<Gtk2::TextView>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-errortextdialog/index.html>

=head1 LICENSE

Gtk2-Ex-ErrorTextDialog is Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 3, or (at your option) any
later version.

Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with Gtk2-Ex-ErrorTextDialog.  If not, see L<http://www.gnu.org/licenses/>.

=cut
