#!/usr/bin/perl -w
#
# Text Widget/Hypertext
#
# Usually, tags modify the appearance of text in the view, e.g. making it 
# bold or colored or underlined. But tags are not restricted to appearance. 
# They can also affect the behavior of mouse and key presses, as this demo 
# shows.
#

package hypertext;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Gdk::Keysyms;
use Gtk2::Pango;


my $window = undef;

# Inserts a piece of text into the buffer, giving it the usual
# appearance of a hyperlink in a web browser: blue and underlined.
# Additionally, attaches some data on the tag, to make it recognizable
# as a link. 
#
sub insert_link {
  my ($buffer, $iter, $text, $page) = @_;
  
  my $tag = $buffer->create_tag (undef, 
				 foreground => "blue", 
				 underline => 'single');
  $tag->{page} = $page;
  $buffer->insert_with_tags ($iter, $text, $tag);
}

# Fills the buffer with text and interspersed links. In any real
# hypertext app, this method would parse a file to identify the links.
#
sub show_page {
  my ($buffer, $page) = @_;

  $buffer->set_text ("");
  my $iter = $buffer->get_iter_at_offset (0);
  if ($page == 1)
    {
      $buffer->insert ($iter, "Some text to show that simple ");
      insert_link ($buffer, $iter, "hypertext", 3);
      $buffer->insert ($iter, " can easily be realized with ");
      insert_link ($buffer, $iter, "tags", 2);
      $buffer->insert ($iter, ".");
    }
  elsif ($page == 2)
    {
      $buffer->insert ($iter, 
	       "A tag is an attribute that can be applied to some range of text. "
	     . "For example, a tag might be called \"bold\" and make the text inside "
	     . "the tag bold. However, the tag concept is more general than that; "
	     . "tags don't have to affect appearance. They can instead affect the "
	     . "behavior of mouse and key presses, \"lock\" a range of text so the "
	     . "user can't edit it, or countless other things.\n");
      insert_link ($buffer, $iter, "Go back", 1);
    }
  elsif ($page == 3) 
    {
      my $tag = $buffer->create_tag (undef, weight => PANGO_WEIGHT_BOLD);
      $buffer->insert_with_tags ($iter, "hypertext:\n", $tag);
      $buffer->insert ($iter, 
		       "machine-readable text that is not sequential but is organized "
		     . "so that related items of information are connected.\n");
      insert_link ($buffer, $iter, "Go back", 1);
    }
}

# Looks at all tags covering the position of iter in the text view, 
# and if one of them is a link, follow it by showing the page identified
# by the data attached to it.
#
sub follow_if_link {
  my ($text_view, $iter) = @_;

  foreach my $tag ($iter->get_tags) {
      my $page = $tag->{page};

      if ($page != 0) {
	  show_page ($text_view->get_buffer, $page);
	  last;
      }
  }
}

# Links can be activated by pressing Enter.
#
sub key_press_event {
  my ($text_view, $event) = @_;

  if ($event->keyval == $Gtk2::Gdk::Keysyms{Return} ||
      $event->keyval == $Gtk2::Gdk::Keysyms{KP_Enter})
    {
        my $buffer = $text_view->get_buffer;
        my $iter = $buffer->get_iter_at_mark ($buffer->get_insert);
        follow_if_link ($text_view, $iter);
    }

  return FALSE;
}

# Links can also be activated by clicking.
#
sub event_after {
  my ($text_view, $event) = @_;

  return FALSE unless $event->type eq 'button-release'; 
  return FALSE unless $event->button == 1;

  my $buffer = $text_view->get_buffer;

  # we shouldn't follow a link if the user has selected something
  my ($start, $end) = $buffer->get_selection_bounds;
  return FALSE if defined $end
                  and $start->get_offset != $end->get_offset;

  my ($x, $y) = $text_view->window_to_buffer_coords ('widget', #GTK_TEXT_WINDOW_WIDGET,
                                                     $event->x, $event->y);

  my $iter = $text_view->get_iter_at_location ($x, $y);

  follow_if_link ($text_view, $iter);

  return FALSE;
}

my $hovering_over_link = FALSE;
my $hand_cursor = undef;
my $regular_cursor = undef;

# Looks at all tags covering the position (x, y) in the text view, 
# and if one of them is a link, change the cursor to the "hands" cursor
# typically used by web browsers.
#
sub set_cursor_if_appropriate {
  my ($text_view, $x, $y) = @_;
  my $hovering = FALSE;

  my $buffer = $text_view->get_buffer;

  my $iter = $text_view->get_iter_at_location ($x, $y);
  
  foreach my $tag ($iter->get_tags) {
      if ($tag->{page}) {
          $hovering = TRUE;
          last;
      }
  }

  if ($hovering != $hovering_over_link)
    {
      $hovering_over_link = $hovering;

      $text_view->get_window ('text')->set_cursor
      		($hovering_over_link ? $hand_cursor : $regular_cursor);
    }
}

# Update the cursor image if the pointer moved. 
#
sub motion_notify_event {
  my ($text_view, $event) = @_;

  my ($x, $y) = $text_view->window_to_buffer_coords ( 
                                         'widget', #GTK_TEXT_WINDOW_WIDGET,
                                         $event->x, $event->y);

  set_cursor_if_appropriate ($text_view, $x, $y);

  $text_view->window->get_pointer;
  return FALSE;
}

# Also update the cursor image if the window becomes visible
# (e.g. when a window covering it got iconified).
#
sub visibility_notify_event {
  my ($text_view, $event) = @_;

  my (undef, $wx, $wy, undef) = $text_view->window->get_pointer;
  
  my ($bx, $by) = $text_view->window_to_buffer_coords ( 
                                         'widget', #GTK_TEXT_WINDOW_WIDGET,
                                         $wx, $wy);

  set_cursor_if_appropriate ($text_view, $bx, $by);

  return FALSE;
}

sub do {
  my $do_widget = shift;

  if (!$window) {
      $hand_cursor = Gtk2::Gdk::Cursor->new ('hand2');
      $regular_cursor = Gtk2::Gdk::Cursor->new ('xterm');
      
      $window = Gtk2::Window->new;
      $window->set_screen ($do_widget->get_screen)
        if Gtk2->CHECK_VERSION (2, 2, 0);
      $window->set_default_size (450, 450);
      
      $window->signal_connect (destroy => sub {$window = undef});

      $window->set_title ("Hypertext");
      $window->set_border_width (0);

      my $view = Gtk2::TextView->new;
      $view->set_wrap_mode ('word');
      $view->signal_connect (key_press_event => \&key_press_event);
      $view->signal_connect (event_after => \&event_after);
      $view->signal_connect (motion_notify_event => \&motion_notify_event);
      $view->signal_connect (visibility_notify_event => \&visibility_notify_event);

      my $buffer = $view->get_buffer;
      
      my $sw = Gtk2::ScrolledWindow->new;
      $sw->set_policy ('automatic', 'automatic');
      $window->add ($sw);
      $sw->add ($view);

      show_page ($buffer, 1);

      $sw->show_all;
  }

  if (!$window->visible) {
      $window->show;
  } else {
      $window->destroy;
      $window = undef;
  }

  return $window;
}

1;
