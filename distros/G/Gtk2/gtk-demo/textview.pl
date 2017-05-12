#!/usr/bin/perl -w 
#
# Multiple Views
#
# The GtkTextView widget displays a GtkTextBuffer. One GtkTextBuffer
# can be displayed by multiple GtkTextViews. This demo has two views
# displaying a single buffer, and shows off the widget's text
# formatting features.
#

package textview;

use Glib qw(TRUE FALSE);
use Gtk2;
use Carp;

# get the PANGO_WEIGHT_* constants
use Gtk2::Pango;

##static void easter_egg_callback (GtkWidget *button, gpointer data);

use constant gray50_width => 2;
use constant gray50_height => 2;
my $gray50_bits = pack 'CC', 0x02, 0x01;

sub create_tags {
  my $buffer = shift;

  # Create a bunch of tags. Note that it's also possible to
  # create tags with gtk_text_tag_new() then add them to the
  # tag table for the buffer, gtk_text_buffer_create_tag() is
  # just a convenience function. Also note that you don't have
  # to give tags a name; pass NULL for the name to create an
  # anonymous tag.
  #
  # In any real app, another useful optimization would be to create
  # a GtkTextTagTable in advance, and reuse the same tag table for
  # all the buffers with the same tag set, instead of creating
  # new copies of the same tags for every buffer.
  #
  # Tags are assigned default priorities in order of addition to the
  # tag table.	 That is, tags created later that affect the same text
  # property affected by an earlier tag will override the earlier
  # tag.  You can modify tag priorities with
  # gtk_text_tag_set_priority().

  $buffer->create_tag ("heading",
			weight => PANGO_WEIGHT_BOLD,
			size => 15 * PANGO_SCALE,
			);
  
  $buffer->create_tag ("italic", style => 'italic');
  $buffer->create_tag ("bold", weight => PANGO_WEIGHT_BOLD); 
  $buffer->create_tag ("big", size => 20 * PANGO_SCALE);
			      # points times the PANGO_SCALE factor

  $buffer->create_tag ("xx-small", scale => PANGO_SCALE_XX_SMALL); 
  $buffer->create_tag ("x-large", scale => PANGO_SCALE_X_LARGE); 
  $buffer->create_tag ("monospace", family => "monospace"); 
  $buffer->create_tag ("blue_foreground", foreground => "blue");  
  $buffer->create_tag ("red_background", background => "red");

  my $stipple = Gtk2::Gdk::Bitmap->create_from_data (undef,
					 $gray50_bits, gray50_width,
					 gray50_height);
  
  $buffer->create_tag ("background_stipple", background_stipple => $stipple); 
  $buffer->create_tag ("foreground_stipple", foreground_stipple => $stipple); 

  $buffer->create_tag ("big_gap_before_line", pixels_above_lines => 30); 
  $buffer->create_tag ("big_gap_after_line", pixels_below_lines => 30); 
  $buffer->create_tag ("double_spaced_line", pixels_inside_wrap => 10); 
  $buffer->create_tag ("not_editable", editable => FALSE); 
  $buffer->create_tag ("word_wrap", wrap_mode => 'word');
  $buffer->create_tag ("char_wrap", wrap_mode => 'char');
  $buffer->create_tag ("no_wrap", wrap_mode => 'none');
  $buffer->create_tag ("center", justification => 'center');
  $buffer->create_tag ("right_justify", justification => 'right');
  $buffer->create_tag ("wide_margins", left_margin => 50, right_margin => 50); 
  $buffer->create_tag ("strikethrough", strikethrough => TRUE); 
  $buffer->create_tag ("underline", underline => 'single');
  $buffer->create_tag ("double_underline", underline => 'double');

  $buffer->create_tag ("superscript",
			rise => 10 * PANGO_SCALE,	  # 10 pixels
			size => 8 * PANGO_SCALE,	  # 8 points
			);
  
  $buffer->create_tag ("subscript",
			rise => -10 * PANGO_SCALE,   # 10 pixels
			size => 8 * PANGO_SCALE,	   # 8 points
			);

  $buffer->create_tag ("rtl_quote",
			wrap_mode => 'word',
			direction => 'rtl',
			indent => 30,
			left_margin => 20,
			right_margin => 20,
			);
}

sub insert_text {
  my $buffer = shift;

  # demo_find_file() looks in the the current directory first,
  # so you can run gtk-demo without installing GTK, then looks
  # in the location where the file is installed.
  
  # croaks if it can't find the file
  my $filename = "gtk-logo-rgb.gif";
  my $pixbuf;
  eval {
     $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file (
	     	main::demo_find_file ($filename));
  };
  if ($@) {
      die "caught exception from Gtk2::Gdk::Pixbuf->new_from_file --- $@";
  }

  my $scaled = $pixbuf->scale_simple (32, 32, 'bilinear');
  $pixbuf = $scaled;
  
  # get start of buffer; each insertion will revalidate the
  # iterator to point to just after the inserted text.
  
  my $iter = $buffer->get_iter_at_offset (0);

  $buffer->insert ($iter, "The text widget can display text with all kinds of nifty attributes. It also supports multiple views of the same buffer; this demo is showing the same buffer in two places.\n\n");

  $buffer->insert_with_tags_by_name ($iter, "Font styles. ", "heading");
  
  $buffer->insert ($iter, "For example, you can have ");
  $buffer->insert_with_tags_by_name ($iter, "italic", "italic");
  $buffer->insert ($iter, ", ");  
  $buffer->insert_with_tags_by_name ($iter, "bold", "bold");
  $buffer->insert ($iter, ", or ");
  $buffer->insert_with_tags_by_name ($iter, "monospace (typewriter)", "monospace");
  $buffer->insert ($iter, ", or ");
  $buffer->insert_with_tags_by_name ($iter, "big", "big");
  $buffer->insert ($iter, " text. ");
  $buffer->insert ($iter, "It's best not to hardcode specific text sizes; you can use relative sizes as with CSS, such as ");
  $buffer->insert_with_tags_by_name ($iter, "xx-small", "xx-small");
  $buffer->insert ($iter, " or ");
  $buffer->insert_with_tags_by_name ($iter, "x-large", "x-large");
  $buffer->insert ($iter, " to ensure that your program properly adapts if the user changes the default font size.\n\n");
  
  $buffer->insert_with_tags_by_name ($iter, "Colors. ", "heading");
  
  $buffer->insert ($iter, "Colors such as ");  
  $buffer->insert_with_tags_by_name ($iter, "a blue foreground", "blue_foreground");
  $buffer->insert ($iter, " or ");  
  $buffer->insert_with_tags_by_name ($iter, "a red background", "red_background");
  $buffer->insert ($iter, " or even ");  
  $buffer->insert_with_tags_by_name ($iter, "a stippled red background",
					    "red_background",
					    "background_stipple");

  $buffer->insert ($iter, " or ");  
  $buffer->insert_with_tags_by_name ($iter, "a stippled blue foreground on solid red background",
					    "blue_foreground",
					    "red_background",
					    "foreground_stipple");
  $buffer->insert ($iter, " (select that to read it) can be used.\n\n");  

  $buffer->insert_with_tags_by_name ($iter, "Underline, strikethrough, and rise. ",
					    "heading");
  
  $buffer->insert_with_tags_by_name ($iter, "Strikethrough", "strikethrough");
  $buffer->insert ($iter, ", ");
  $buffer->insert_with_tags_by_name ($iter, "underline", "underline");
  $buffer->insert ($iter, ", ");
  $buffer->insert_with_tags_by_name ($iter, "double underline", "double_underline");
  $buffer->insert ($iter, ", ");
  $buffer->insert_with_tags_by_name ($iter, "superscript", "superscript");
  $buffer->insert ($iter, ", and ");
  $buffer->insert_with_tags_by_name ($iter, "subscript", "subscript");
  $buffer->insert ($iter, " are all supported.\n\n");

  $buffer->insert_with_tags_by_name ($iter, "Images. ", "heading");
  
  $buffer->insert ($iter, "The buffer can have images in it: ");
  $buffer->insert_pixbuf ($iter, $pixbuf);
  $buffer->insert_pixbuf ($iter, $pixbuf);
  $buffer->insert_pixbuf ($iter, $pixbuf);
  $buffer->insert ($iter, " for example.\n\n");

  $buffer->insert_with_tags_by_name ($iter, "Spacing. ", "heading");

  $buffer->insert ($iter, "You can adjust the amount of space before each line.\n");
  
  $buffer->insert_with_tags_by_name ($iter, "This line has a whole lot of space before it.\n", 
					    "big_gap_before_line", "wide_margins");
  $buffer->insert_with_tags_by_name ($iter, "You can also adjust the amount of space after each line; this line has a whole lot of space after it.\n",
					    "big_gap_after_line", "wide_margins");
  
  $buffer->insert_with_tags_by_name ($iter,
					    "You can also adjust the amount of space between wrapped lines; this line has extra space between each wrapped line in the same paragraph. To show off wrapping, some filler text: the quick brown fox jumped over the lazy dog. Blah blah blah blah blah blah blah blah blah.\n",
					    "double_spaced_line", "wide_margins");

  $buffer->insert ($iter, "Also note that those lines have extra-wide margins.\n\n");

  $buffer->insert_with_tags_by_name ($iter, "Editability. ", "heading");
  
  $buffer->insert_with_tags_by_name ($iter, "This line is 'locked down' and can't be edited by the user - just try it! You can't delete this line.\n\n",
					    "not_editable");

  $buffer->insert_with_tags_by_name ($iter, "Wrapping. ", "heading");

  $buffer->insert ($iter, "This line (and most of the others in this buffer) is word-wrapped, using the proper Unicode algorithm. Word wrap should work in all scripts and languages that GTK+ supports. Let's make this a long paragraph to demonstrate: blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah\n\n");  
  
  $buffer->insert_with_tags_by_name ($iter, "This line has character-based wrapping, and can wrap between any two character glyphs. Let's make this a long paragraph to demonstrate: blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah\n\n",
					    "char_wrap");
  
  $buffer->insert_with_tags_by_name ($iter, "This line has all wrapping turned off, so it makes the horizontal scrollbar appear.\n\n\n",
					    "no_wrap");

  $buffer->insert_with_tags_by_name ($iter, "Justification. ", "heading");  
  
  $buffer->insert_with_tags_by_name ($iter, "\nThis line has center justification.\n", "center");

  $buffer->insert_with_tags_by_name ($iter, "This line has right justification.\n", 
					    "right_justify");

  $buffer->insert_with_tags_by_name ($iter,
					    "\nThis line has big wide margins. Text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text.\n", 
					    "wide_margins");  

  $buffer->insert_with_tags_by_name ($iter, "Internationalization. ", 
					    "heading");
	  
  $buffer->insert ($iter, "You can put all sorts of Unicode text in the buffer.\n\nGerman (S\x{fc}ddeutschland) Gr\x{fc}\x{df} Gott\nGreek (\x{395}\x{3bb}\x{3bb}\x{3b7}\x{3bd}\x{3b9}\x{3ba}\x{3ac}) \x{393}\x{3b5}\x{3b9}\x{3ac} \x{3c3}\x{3b1}\x{3c2}\nHebrew	\x{5e9}\x{5dc}\x{5d5}\x{5dd}\nJapanese (\x{65e5}\x{672c}\x{8a9e})\n\nThe widget properly handles bidirectional text, word wrapping, DOS/UNIX/Unicode paragraph separators, grapheme boundaries, and so on using the Pango internationalization framework.\n");  

  $buffer->insert ($iter, "Here's a word-wrapped quote in a right-to-left language:\n");
  $buffer->insert_with_tags_by_name ($iter, "\x{648}\x{642}\x{62f} \x{628}\x{62f}\x{623} \x{62b}\x{644}\x{627}\x{62b} \x{645}\x{646} \x{623}\x{643}\x{62b}\x{631} \x{627}\x{644}\x{645}\x{624}\x{633}\x{633}\x{627}\x{62a} \x{62a}\x{642}\x{62f}\x{645}\x{627} \x{641}\x{64a} \x{634}\x{628}\x{643}\x{629} \x{627}\x{643}\x{633}\x{64a}\x{648}\x{646} \x{628}\x{631}\x{627}\x{645}\x{62c}\x{647}\x{627} \x{643}\x{645}\x{646}\x{638}\x{645}\x{627}\x{62a} \x{644}\x{627} \x{62a}\x{633}\x{639}\x{649} \x{644}\x{644}\x{631}\x{628}\x{62d}\x{60c} \x{62b}\x{645} \x{62a}\x{62d}\x{648}\x{644}\x{62a} \x{641}\x{64a} \x{627}\x{644}\x{633}\x{646}\x{648}\x{627}\x{62a} \x{627}\x{644}\x{62e}\x{645}\x{633} \x{627}\x{644}\x{645}\x{627}\x{636}\x{64a}\x{629} \x{625}\x{644}\x{649} \x{645}\x{624}\x{633}\x{633}\x{627}\x{62a} \x{645}\x{627}\x{644}\x{64a}\x{629} \x{645}\x{646}\x{638}\x{645}\x{629}\x{60c} \x{648}\x{628}\x{627}\x{62a}\x{62a} \x{62c}\x{632}\x{621}\x{627} \x{645}\x{646} \x{627}\x{644}\x{646}\x{638}\x{627}\x{645} \x{627}\x{644}\x{645}\x{627}\x{644}\x{64a} \x{641}\x{64a} \x{628}\x{644}\x{62f}\x{627}\x{646}\x{647}\x{627}\x{60c} \x{648}\x{644}\x{643}\x{646}\x{647}\x{627} \x{62a}\x{62a}\x{62e}\x{635}\x{635} \x{641}\x{64a} \x{62e}\x{62f}\x{645}\x{629} \x{642}\x{637}\x{627}\x{639} \x{627}\x{644}\x{645}\x{634}\x{631}\x{648}\x{639}\x{627}\x{62a} \x{627}\x{644}\x{635}\x{63a}\x{64a}\x{631}\x{629}. \x{648}\x{623}\x{62d}\x{62f} \x{623}\x{643}\x{62b}\x{631} \x{647}\x{630}\x{647} \x{627}\x{644}\x{645}\x{624}\x{633}\x{633}\x{627}\x{62a} \x{646}\x{62c}\x{627}\x{62d}\x{627} \x{647}\x{648} \x{bb}\x{628}\x{627}\x{646}\x{643}\x{648}\x{633}\x{648}\x{644}\x{ab} \x{641}\x{64a} \x{628}\x{648}\x{644}\x{64a}\x{641}\x{64a}\x{627}.\n\n",
						"rtl_quote");
      
  $buffer->insert ($iter, "You can put widgets in the buffer: Here's a button: ");
  $anchor = $buffer->create_child_anchor ($iter);
  $buffer->insert ($iter, " and a menu: ");
  $anchor = $buffer->create_child_anchor ($iter);
  $buffer->insert ($iter, " and a scale: ");
  $anchor = $buffer->create_child_anchor ($iter);
  $buffer->insert ($iter, " and an animation: ");
  $anchor = $buffer->create_child_anchor ($iter);
  $buffer->insert ($iter, " finally a text entry: ");
  $anchor = $buffer->create_child_anchor ($iter);
  $buffer->insert ($iter, ".\n");
  
  $buffer->insert ($iter, "\n\nThis demo doesn't demonstrate all the GtkTextBuffer features; it leaves out, for example: invisible/hidden text (doesn't work in GTK 2, but planned), tab stops, application-drawn areas on the sides of the widget for displaying breakpoints and such...");

  # Apply word_wrap tag to whole buffer
  $buffer->apply_tag_by_name ("word_wrap", $buffer->get_bounds);
}

sub find_anchor {
  my $iter = shift;
  while ($iter->forward_char) {
    return TRUE if $iter->get_child_anchor;
  }
  return FALSE;
}

sub attach_widgets {
  my $text_view = shift;
  
  my $buffer = $text_view->get_buffer;

  my $iter = $buffer->get_start_iter;

  my $i = 0;
  while (find_anchor ($iter)) {
      my $widget;
      
      my $anchor = $iter->get_child_anchor;

      if ($i == 0) {
          $widget = Gtk2::Button->new ("Click Me");

          $widget->signal_connect (clicked => \&easter_egg_callback);

      } elsif ($i == 1) {
	  if (Gtk2->CHECK_VERSION (2, 4, 0)) {
             $widget = Gtk2::ComboBox->new_text;
             $widget->append_text ("Option 1");
             $widget->append_text ("Option 2");
             $widget->append_text ("Option 3");

          } else {
             # ComboBox is not available, use OptionMenu instead
             my $menu = Gtk2::Menu->new;
             $menu->append (Gtk2::MenuItem->new ("Option 1"));
             $menu->append (Gtk2::MenuItem->new ("Option 2"));
             $menu->append (Gtk2::MenuItem->new ("Option 3"));

             $widget = Gtk2::OptionMenu->new;
             $widget->set_menu ($menu);
          }

      } elsif ($i == 2) {
          $widget = Gtk2::HScale->new (undef);
          $widget->set_range (0, 100);
          $widget->set_size_request (70, -1);

      } elsif ($i == 3) {
	  my $filename = main::demo_find_file ("floppybuddy.gif");
	  $widget = Gtk2::Image->new_from_file ($filename);

      } elsif ($i == 4) {
          $widget = Gtk2::Entry->new;

      } else {
	  croak "shouldn't get here";
      }

      $text_view->add_child_at_anchor ($widget, $anchor);

      $widget->show_all;

      ++$i;
  }
}

my $window;

sub do {
  if (!$window) {
      
      $window = Gtk2::Window->new ('toplevel');
      $window->set_default_size (450, 450);
      
      $window->signal_connect (destroy => sub { $window = undef; });

      $window->set_title ("TextView");
      $window->set_border_width (0);

      my $vpaned = Gtk2::VPaned->new;
      $vpaned->set_border_width (5);
      $window->add ($vpaned);

      # For convenience, we just use the autocreated buffer from
      # the first text view; you could also create the buffer
      # by itself with gtk_text_buffer_new(), then later create
      # a view widget.
      
      my $view1 = Gtk2::TextView->new;
      my $buffer = $view1->get_buffer;
      my $view2 = Gtk2::TextView->new_with_buffer ($buffer);
      
      my $sw = Gtk2::ScrolledWindow->new;
      $sw->set_policy ('automatic', 'automatic');
      $vpaned->add1 ($sw);

      $sw->add ($view1);

      $sw = Gtk2::ScrolledWindow->new;
      $sw->set_policy ('automatic', 'automatic');
      $vpaned->add2 ($sw);

      $sw->add ($view2);

      create_tags ($buffer);
      insert_text ($buffer);

      attach_widgets ($view1);
      attach_widgets ($view2);
      
      $vpaned->show_all;
  }

  if (!$window->visible) {
      $window->show;

  } else {
      $window->destroy;
      $window = undef;
  }

  return $window;
}

sub recursive_attach_view {
  my ($depth, $view, $anchor) = @_;
  
  return if $depth > 4;
  
  my $child_view = Gtk2::TextView->new_with_buffer ($view->get_buffer);

  # Event box is to add a black border around each child view
  my $event_box = Gtk2::EventBox->new;
  my $color = Gtk2::Gdk::Color->parse ("black");
  $event_box->modify_bg ('normal', $color);

  my $align = Gtk2::Alignment->new (0.5, 0.5, 1.0, 1.0);
  $align->set_border_width (1);
  
  $event_box->add ($align);
  $align->add ($child_view);
  
  $view->add_child_at_anchor ($event_box, $anchor);

  recursive_attach_view ($depth + 1, $child_view, $anchor);
}

sub easter_egg_callback {
  my $button = shift;

  if ($tvee_window) {
      $tvee_window->present;
      return;
  }
  
  my $buffer = Gtk2::TextBuffer->new (undef);

  my $iter = $buffer->get_start_iter;

  $buffer->insert ($iter, "This buffer is shared by a set of nested text views.\n Nested view:\n");
  my $anchor = $buffer->create_child_anchor ($iter);
  $buffer->insert ($iter, "\nDon't do this in real applications, please.\n");

  my $view = Gtk2::TextView->new_with_buffer ($buffer);
  
  recursive_attach_view (0, $view, $anchor);
  
  $tvee_window = Gtk2::Window->new ('toplevel');
  my $sw = Gtk2::ScrolledWindow->new (undef, undef);
  $sw->set_policy ('automatic', 'automatic');

  $tvee_window->add ($sw);
  $sw->add ($view);

  $tvee_window->signal_connect (destroy => sub {$tvee_window = undef; 1});

  $tvee_window->set_default_size (300, 400);
  
  $tvee_window->show_all;
}

1;
__END__
Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
