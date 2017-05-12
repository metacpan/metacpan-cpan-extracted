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
use 5.008;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 11;

use Glib::Object::Subclass
  'Gtk2::TextView',
  signals => { size_allocate => \&_do_size_allocate,
               # notify        => \&_do_notify,
               destroy       => \&_do_destroy,
             };

sub new_with_buffer {
  my ($class, $textbuf) = @_;
  return $class->Glib::Object::new (buffer => $textbuf);
}

# "notify" is done as a connect to self rather than a class handler.
# A long-standing glib bug causes a $self->signal_chain_from_overridden to
# go to the wrong handler, when a notify is invoked from under another
# handler, or something like that.  Very annoying.
sub INIT_INSTANCE {
  my ($self) = @_;
  $self->signal_connect (notify => \&_do_notify);
}

# 'destroy' class closure
sub _do_destroy {
  my ($self) = @_;
  ### FollowAppend _do_destroy(): "$self"

  # The GtkObjectFlags GTK_IN_DESTRUCTION might do this, if it was exposed
  # at the perl level.  Except gtk_object_dispose() looks like the flag
  # might be set solely while 'destroy' runs, but any notifies during
  # finalize should suppress get_buffer() below too.  Except can finalize
  # emit notify anyway?
  #
  $self->{'destroyed'} = 1;

  $self->signal_chain_from_overridden ();
}

# 'notify' class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  ### FollowAppend _do_notify(): $pspec->get_name

  # my $invocation_hint = $self->signal_get_invocation_hint;
  # require Data::Dumper;
  # print Data::Dumper->Indent(1)->Dump([$invocation_hint],
  #                                     ['invocation_hint']);

#  $self->signal_chain_from_overridden ($pspec);

  # After 'destroy' runs it's important not to call ->get_buffer() since
  # that func creates a new TextBuffer in place of what
  # gtk_text_view_destroy() just destroyed and set to NULL.  If a textbuf is
  # re-created like that it leads to a fatal error in
  # gtk_text_view_finalize().
  #
  if (! $self->{'destroyed'} && $pspec->get_name eq 'buffer') {
    require Glib::Ex::SignalIds;
    require Scalar::Util;

    my $textbuf = $self->get_buffer;
    Scalar::Util::weaken (my $weak_self = $self);
    my $ref_weak_self = \$weak_self;

    $self->{'textbuf_ids'} = $textbuf && Glib::Ex::SignalIds->new
      ($textbuf,
       $textbuf->signal_connect_after ('insert-text',
                                       \&_do_textbuf_insert,
                                       $ref_weak_self),
       $textbuf->signal_connect_after ('insert-pixbuf',
                                       \&_do_textbuf_insert_pixbuf_or_anchor,
                                       $ref_weak_self),
       $textbuf->signal_connect_after ('insert-child-anchor',
                                       \&_do_textbuf_insert_pixbuf_or_anchor,
                                       $ref_weak_self));
  }
}

# 'size-allocate' class closure
sub _do_size_allocate {
  my ($self, $alloc) = @_;
  ### FollowAppend size_allocate: $alloc->x.",".$alloc->y." ".$alloc->width."x".$alloc->height

  my $want_follow = _want_follow ($self);
  ### $want_follow

  $self->signal_chain_from_overridden ($alloc);

  if ($want_follow) {
    ### _do_size_allocate() scroll_to_mark
    $self->scroll_to_mark ($self->get_buffer->get_insert, 0, 0, 0,0);
  }
}

# 'insert-pixbuf' and 'insert-child-anchor' signal handler on textbuf
sub _do_textbuf_insert_pixbuf_or_anchor {
  my ($textbuf, $iter, $pixbuf_or_anchor, $ref_weak_self) = @_;
  _do_textbuf_insert ($textbuf, $iter, undef, 1, $ref_weak_self);
}

# 'insert-text' signal handler on textbuf,
# plus fakery from 'insert-pixbuf' and 'insert-child-anchor' above
sub _do_textbuf_insert {
  my ($textbuf, $iter, $text, $textlen, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### FollowAppend _do_textbuf_insert() iter: $iter->get_offset
  ### $textlen
  ### $text

  if ($iter->is_end
      && _want_follow ($self,
                       $textbuf->get_iter_at_offset
                       ($iter->get_offset - $textlen))) {
    ### _do_textbuf_insert() scroll_to_mark
    $self->scroll_to_mark ($textbuf->get_insert, 0, 0, 0,0);
  }
}

sub _want_follow {
  my ($self, $insert_iter) = @_;
  my $textbuf = $self->get_buffer;
  my $cursor_iter = $textbuf->get_iter_at_mark ($textbuf->get_insert);

  ### insert at: ($insert_iter||$textbuf->get_end_iter)->get_offset
  ### end: $textbuf->get_end_iter->get_offset
  ### cursor: $cursor_iter->get_offset
  ### charcount: $textbuf->get_char_count
  ### cursor is_end: $cursor_iter->is_end

  return ($cursor_iter->is_end
          && _iter_is_visible ($self, $insert_iter||$textbuf->get_end_iter));
}

# return true if $iter is visible in $textview
# partially visible $iter pos returns true
sub _iter_is_visible {
  my ($textview, $iter) = @_;
  my $visible_rect = $textview->get_visible_rect;

  ###
  ### visible rect: $visible_rect->x.",".$visible_rect->y." ".$visible_rect->width."x".$visible_rect->height." height to ".($visible_rect->y+$visible_rect->height)
  ### iter: $iter->get_offset
  ### start_vis: do { my $start_iter = $textview->get_iter_at_location (0, $visible_rect->y); $start_iter->get_offset }
  ### end vis: do { my $end_iter = $textview->get_iter_at_location (0, $visible_rect->y + $visible_rect->height); $end_iter->get_offset }
  ### end buf: $textview->get_buffer->get_char_count

  my $start_iter = $textview->get_iter_at_location(0, $visible_rect->y);
  if ($iter->compare($start_iter) < 0) {
    # $iter is before start of visible part
    return 0;
  }
  my $end_iter = $textview->get_iter_at_location
    (0, $visible_rect->y + $visible_rect->height - 1);
  $end_iter->forward_visible_line;
  # true if iter is at or before end of visible part
  return ($iter->compare($end_iter) <= 0);
}

# This version based on get_iter_location() for the rectangle of the target
# iter, where the above only asks for the iter extents of the visible
# window.  Will the above help with lazy calculation of lines, or does
# everything have to be calculated anyway for the total size for the
# scrollbar etc?
#
# # return true if $iter is visible in $textview
# sub _iter_is_visible {
#   my ($textview, $iter) = @_;
#   my $visible_rect = $textview->get_visible_rect;
#   my $iter_rect = $textview->get_iter_location ($iter);
#   if (DEBUG) { print "  visible rect ",
#                  $visible_rect->x,",",$visible_rect->y," ",
#                    $visible_rect->width,"x",$visible_rect->height,
#                      " height to ",$visible_rect->y+$visible_rect->height,"\n";
#                print "  iter rect ",
#                  $iter_rect->x,",",$iter_rect->y," ",
#                    $iter_rect->width,"x",$iter_rect->height,
#                      " height to ",$iter_rect->y+$iter_rect->height,"\n";
#              }
# 
#   # if y1+h1 < y2 then rect1 is entirely above rect2, or if y2+h2 < y1 then
#   # rect2 is entirely above rect1; if neither then there's overlap
#   # rect_overlaps_rect() ?
#   return ! ($visible_rect->y + $visible_rect->height < $iter_rect->y
#             || $iter_rect->y + $iter_rect->height < $visible_rect->y);
# }

1;
__END__

=for stopwords TextView TextBuffer subprocess pixbuf resize ErrorTextDialog
Gtk2-Ex-ErrorTextDialog Gtk Ryde

=head1 NAME

Gtk2::Ex::TextView::FollowAppend -- variant of TextView following appended text

=head1 SYNOPSIS

 use Gtk2::Ex::TextView::FollowAppend;
 my $textview = Gtk2::Ex::TextView::FollowAppend->new;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::TextView::FollowAppend> is a subclass of C<Gtk2::TextView>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::TextView
          Gtk2::Ex::TextView::FollowAppend

=head1 DESCRIPTION

B<This is slightly experimental and might move to a different dist.>

TextView::FollowAppend arranges to automatically scroll to follow text
appended in the underlying TextBuffer.  The effect is like Emacs
C<compilation-scroll-output> and is good for following text progressively
added by a background task or subprocess, but still allowing the user to
scroll back to see earlier output.

A scroll is done when the insertion point cursor is at the end of the buffer
and the buffer end is visible.  Any text, pixbuf or child insertion, or
child resize or window resize then gets a scroll to keep the end still
visible.

=head2 Implementation

This is implemented as a subclass of TextView since that seems the easiest
way to catch a C<size-allocate> before the new size has been applied, so as
to see whether the cursor-at-end plus end-visible conditions are met and
thus end-visible should be forced on the new size.  Because C<size-allocate>
is a C<run-first> signal an external signal connection only runs once the
new size is applied.  Maybe it'd be possible to track end-visible all the
time though, ready for a window resize or contents resize.

=head1 FUNCTIONS

=over 4

=item C<< $textview = Gtk2::Ex::TextView::FollowAppend->new (key=>value,...) >>

Create and return a new TextView::FollowAppend object.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new >>.

    $textview = Gtk2::Ex::TextView::FollowAppend->new;

=item C<< $textview = Gtk2::Ex::TextView::FollowAppend->new_with_buffer ($textbuf) >>

Create and return a new TextView::FollowAppend with an initial TextBuffer.
This is as per C<< Gtk2::TextView->new_with_buffer >>, but creating a
TextView::FollowAppend.  It's the same as

    $textview = Gtk2::Ex::TextView::FollowAppend->new (buffer => $textbuf);

=back

=head1 SEE ALSO

L<Gtk2::TextView>, L<Gtk2::TextBuffer>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-errortextdialog/>

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
