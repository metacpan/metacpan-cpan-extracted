# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


package Gtk2::Ex::TextBufferBits;
use 5.008;
use strict;
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;

sub replace_lines {
  my ($textbuf, $str) = @_;

  require Glib::Ex::FreezeNotify;
  my $freezer = Glib::Ex::FreezeNotify->new ($textbuf,
                                             $textbuf->get_insert,
                                             $textbuf->get_selection_bound);

  my ($ins_line, $ins_col) = _mark_to_lineandcol ($textbuf->get_insert);
  my ($sel_line, $sel_col) = _mark_to_lineandcol ($textbuf->get_selection_bound);
  ### ins/sel: "$ins_line,$ins_col $sel_line,$sel_col "

  my $pos = 0;
  my $iter = $textbuf->get_start_iter;
  if (! $iter->is_end) {
    for (;;) {
      ### at: $pos, $iter->get_offset

      my $endpos = index ($str, "\n", $pos);
      if ($endpos < 0) {
        ### str no more newlines, delete through: $textbuf->get_end_iter->get_offset
        $textbuf->delete ($iter, $textbuf->get_end_iter);
        last;
      }
      ### endpos: $endpos

      # forward_to_line_end() goes to next line if already at line end, so test
      if (! $iter->ends_line) {
        my $enditer = $iter->copy;
        $enditer->forward_to_line_end;
        ### delete to enditer: $enditer->get_offset, $textbuf->get_text($iter,$enditer,1)
        $textbuf->delete ($iter, $enditer);
      }

      ### insert: substr($str, $pos, $endpos-$pos)
      $textbuf->insert ($iter, substr($str, $pos, $endpos-$pos));

      $pos = $endpos;
      if ($iter->is_end) {
        ### buffer end, no final newline
        last;
      }
      $pos++;
      if (! $iter->forward_line) {
        ### buffer end, with final newline
        last;
      }
    }
  }

  ### insert final: $pos, substr($str, $pos)
  if ($pos < length($str)) {
    $textbuf->insert ($iter, substr ($str, $pos));
  }

  $textbuf->select_range (_lineandcol_to_iter ($textbuf, $ins_line, $ins_col),
                          _lineandcol_to_iter ($textbuf, $sel_line, $sel_col));
}

# $mark is a Gtk2::TextMark
# return ($line, $column) of its current position
sub _mark_to_lineandcol {
  my ($mark) = @_;
  my $textbuf = $mark->get_buffer || return;
  my $iter = $textbuf->get_iter_at_mark ($mark);
  ### _mark_to_lineandcol(): $iter->get_offset
  if ($iter->is_end) {
    return (-1, -1);
  } else {
    return ($iter->get_line,
            ! $mark->get_left_gravity && $iter->ends_line
            ? -1 : $iter->get_line_offset);
  }
}

# $textbuf is a Gtk2::TextBuffer
# return a Gtk2::TextIter at $line,$column in that buffer
sub _lineandcol_to_iter {
  my ($textbuf, $line, $column) = @_;
  if ($line == -1) {
    return $textbuf->get_end_iter;
  }
  my $iter = $textbuf->get_iter_at_line ($line);
  if ($column == -1 || $column >= $iter->get_chars_in_line) {
    unless ($iter->ends_line) { $iter->forward_to_line_end; }
  } else {
    $iter->forward_chars ($column);
  }
  ### result: "$line,$column -> ".$iter->get_offset
  return $iter;
}


1;
__END__

=for stopwords Ryde Gtk2-Ex-WidgetBits TextView Gtk

=head1 NAME

Gtk2::Ex::TextBufferBits -- helpers for Gtk2::TextBuffer objects

=head1 SYNOPSIS

 use Gtk2::Ex::TextBufferBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::TextBufferBits::replace_lines ($textbuf, $str) >>

Replace the text in C<$textbuf> with C<$str>, line by line.  This is the
same as C<< $textbuf->set_text($str) >>, but preserves marks.

Marks within a line move to the start if they're left-gravity, or the end if
right-gravity.  Marks at the very end of the buffer stay at the new end.  If
there's no newline on the last line then right-gravity marks anywhere in it
end up at the new end too.

The insert and selection marks have their column positions preserved too.
The intention would be to do that for all marks, but as of Gtk 2.20 there's
no fast way to get them all.

C<Gtk2::TextView> keeps its window position as a mark at the start of a
line.  C<replace_lines> preserves that, which means the TextView shows the
same lines of the buffer whereas a plain C<< $textbuf->set_text($str) >>
makes it jump to the start of the buffer.

=back

=head1 SEE ALSO

L<Gtk2::TextBuffer>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

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
