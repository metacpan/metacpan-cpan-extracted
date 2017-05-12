# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::EntryBits;
use 5.008;
use strict;
use warnings;
use List::Util 'max';
use Gtk2;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(select_region_noclip
                    x_to_text_index
                    scroll_number_handler);

our $VERSION = 48;

sub select_region_noclip {
  my ($entry, $start, $end) = @_;

  # Gtk2::Entry::select_region won't error out, but a subclassed method
  # might, or $entry might not be a Gtk2::Entry at all, so guard the temp
  # change to the realized() flag
  #
  require Scope::Guard;
  my $save = $entry->realized;
  my $guard = Scope::Guard->new (sub { $entry->realized($save) });

  $entry->realized (0);
  $entry->select_region ($start, $end);
}

sub x_to_text_index {
  my ($entry, $x) = @_;
  my $layout = $entry->get_layout;
  my $layout_line = $layout->get_line(0) || return undef;

  my ($x_offset, $y_offset) = $entry->get_layout_offsets;
  $x -= $x_offset;
  ### $x_offset

  require Gtk2::Pango;
  my ($inside, $index, $trailing)
    = $layout_line->x_to_index($x * Gtk2::Pango::PANGO_SCALE()
                               + int(Gtk2::Pango::PANGO_SCALE()/2));
  ### $inside
  ### $index
  ### $trailing

  # $trailing is set when in the second half of a char (is that right?).
  # Don't want to apply it unless past the end of the string, so not $inside.
  if (! $inside) {
    $index += $trailing;
  }
  return $entry->layout_index_to_text_index($index);
}

my %direction_to_offset = (up => 1,
                           down => -1);
sub scroll_number_handler {
  my ($entry, $event) = @_;
  ### EntryBits scroll_number() ...

  if (my $num_increment = $direction_to_offset{$event->direction}) {
    if ($event->state & 'control-mask') {
      $num_increment *= 10;
    }
    if (defined (my $pos = x_to_text_index($entry,$event->x))) {
      my $text = $entry->get_text;
      my $text_at = substr($text,$pos);
      if ($text_at =~ /^(\d+)/) {
        my $num_len = length($1);
        my $text_before = substr($text,0,$pos);
        $text_before =~ /(\d*)$/;
        $pos -= length($1);
        $num_len += length($1);

        my $old_len = length($text);
        my $num = substr($text, $pos, $num_len);
        $text = substr($text, 0, $pos)
          . max(0, $num+$num_increment)
            . substr($text, $pos+$num_len);

        my $cursor_position = $entry->get_position;
        $entry->set_text ($text);
        $entry->set_position ($cursor_position
                             + length($text)-$old_len);

        $entry->activate;
        return 1; # Gtk2::EVENT_STOP
      }
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

1;
__END__

=for stopwords Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::EntryBits -- misc functions for Gtk2::Entry widgets

=head1 SYNOPSIS

 use Gtk2::Ex::EntryBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::EntryBits::select_region_noclip ($entry, $start, $end) >>

Select text from C<$start> to C<$end> like C<< $entry->select_region >>, but
don't put it on the clipboard.  This is a good way to let the user type over
previous text, without upsetting any cut and paste in progress.

This is implemented with a nasty hack temporarily pretending C<$entry> is
unrealized.

=item C<< $pos = Gtk2::Ex::EntryBits::x_to_text_index ($entry, $x) >>

Convert from C<$x> pixel in C<$entry> widget coordinates to a character
index into the text string in the entry.

If C<$x> is past the beginning of the text the return is 0.  If C<$x> is
past the end of the text the return is length(text).  Any xalign or user
scrolling is accounted for so the character position is as the text appears
on screen.

This is implemented by pango layout offset as described in the GtkEntry
C<gtk_entry_get_layout_offsets()> documentation.

=item C<< $event_ret = Gtk2::Ex::EntryBits::scroll_number_handler ($entry, $event) >>

This function can be used as a handler for the C<scroll-event> signal of a
C<Gtk2::Entry> to have a mouse scroll increment or decrement numbers within
the entry text.

    +-----------------+
    | abc,123+def*56  |
    +-----------------+
           ^      ^
        scroll with mouse over a number to increment/decrement

If C<$event-E<gt>direction()> is "up" or "down" and the mouse
C<$event-E<gt>x()> position is over a number then increment or decrement
that number by 1, or if the control key (C<$event-E<gt>state>) is held down
then by 10.

The return value is C<Gtk2::EVENT_STOP> if a number is scrolled, or
C<Gtk2::EVENT_PROPAGATE> if not (either "left" or "right" scrolls or not
over a number).

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Gtk2::Ex::EntryBits 'x_to_text_index';
    $pos = x_to_text_index ($entry, $x);

The names are probably a bit too generic to want to import most of the time,
but might suit an Entry subclass or something only Entry related.

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 SEE ALSO

L<Gtk2::Entry>, L<Gtk2::Editable>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
