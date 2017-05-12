#!/usr/bin/perl -w
#
# Assistant
#
# Demonstrates a sample multistep assistant. Assistants are used to divide
# an operation into several simpler sequential steps, and to guide the user
# through these steps.
#

package assistant;

use strict;
use warnings;
use Glib ':constants';
use Gtk2;
#include "demo-common.h"

my $assistant = undef;
my $progress_bar = undef;


sub apply_changes_gradually($) {
  my $fraction;
  
  # Work, work, work...
  Gtk2::Gdk::Threads->leave();
  $fraction = $progress_bar->get_fraction();
  $fraction += 0.05;
  
  my $cont = TRUE;
  if ($fraction < 1.0) {
  	$progress_bar->set_fraction($fraction);
  } else {
    # Close automatically once changes are fully applied.
  	$assistant->destroy();
  	undef $assistant;
  	$cont = FALSE;
  }
  Gtk2::Gdk::Threads->enter();
  return $cont;
}


sub on_assistant_apply($$)
{
  my ($widget, $data) = @_;
  # Start a timer to simulate changes taking a few seconds to apply.
  Glib::Timeout->add(100, \&apply_changes_gradually, undef);
}


sub on_assistant_close_cancel($$)
{
  my ($widget, $assistant) = @_;
  $$assistant->destroy();
  undef $$assistant;
}


sub on_assistant_prepare($$$)
{
  my ($widget, $page, $data) = @_;
  my ($current_page, $n_pages, $title);
  
  $current_page = $widget->get_current_page();
  $n_pages = $widget->get_n_pages();
  
  $title = sprintf("Sample assistant (%d of %d)", $current_page + 1, $n_pages);
  $widget->window()->set_title($title);

  # The fourth page (counting from zero) is the progress page.  The
  # user clicked Apply to get here so we tell the assistant to commit,
  # which means the changes up to this point are permanent and cannot
  # be cancelled or revisited.
  if ($current_page == 3) {
      $widget->commit();
  }
}


sub on_entry_changed($$)
{
  my ($widget, $data) = @_;
  my $assistant = $data;
  my ($current_page, $page_number, $text);
  
  $page_number = $assistant->get_current_page();
  $current_page = $assistant->get_nth_page($page_number);
  $text = $widget->get_text();

  if ($text && $text ne '') {
    $assistant->set_page_complete($current_page, TRUE);
  } else {
    $assistant->set_page_complete($current_page, FALSE);
  }
}


sub create_page1($)
{
  my $assistant = shift;
  my ($box, $label, $entry, $pixbuf);

  $box = Gtk2::HBox->new(FALSE, 12);
  $box->set_border_width(12);

  $label = Gtk2::Label->new("You must fill out this entry to continue:");
  $box->pack_start($label, FALSE, FALSE, 0);

  $entry = Gtk2::Entry->new();
  $box->pack_start($entry, TRUE, TRUE, 0);
  $entry->signal_connect("changed",
		    \&on_entry_changed, $assistant);

  $box->show_all();
  $assistant->append_page($box);
  $assistant->set_page_title($box, "Page 1");
  $assistant->set_page_type($box, 'GTK_ASSISTANT_PAGE_INTRO');

  $pixbuf = $assistant->render_icon('gtk-dialog-info', 'GTK_ICON_SIZE_DIALOG');
  $assistant->set_page_header_image($box, $pixbuf);
  undef $pixbuf;
}


sub create_page2($)
{
  my $assistant = shift;
  my ($box, $checkbutton, $pixbuf);
  
  $box = Gtk2::VBox->new(12, FALSE);
  $box->set_border_width(12);

  $checkbutton = Gtk2::CheckButton->new_with_label("This is optional data, you may continue " .
						 "even if you do not check this");
  $box->pack_start($checkbutton, FALSE, FALSE, 0);

  $box->show_all();
  $assistant->append_page($box);
  $assistant->set_page_complete($box, TRUE);
  $assistant->set_page_title($box, "Page 2");

  $pixbuf = $assistant->render_icon('gtk-dialog-info', 'GTK_ICON_SIZE_DIALOG');
  $assistant->set_page_header_image($box, $pixbuf);
  undef $pixbuf;
}


sub create_page3($)
{
  my $assistant = shift;
  my ($label, $pixbuf);

  $label = Gtk2::Label->new ("This is a confirmation page, press 'Apply' to apply changes");

  $label->show();
  $assistant->append_page($label);
  $assistant->set_page_type($label, 'GTK_ASSISTANT_PAGE_CONFIRM');
  $assistant->set_page_complete($label, TRUE);
  $assistant->set_page_title($label, "Confirmation");

  $pixbuf = $assistant->render_icon('gtk-dialog-info', 'GTK_ICON_SIZE_DIALOG');
  $assistant->set_page_header_image($label, $pixbuf);
  undef $pixbuf;
}


sub create_page4($)
{
  my $assistant = shift;
  my ($page);

  $page = Gtk2::Alignment->new (0.5, 0.5, 0.5, 0.0);

  $progress_bar = Gtk2::ProgressBar->new();
  $page->add($progress_bar);

  $page->show_all();
  $assistant->append_page($page);
  $assistant->set_page_type($page, 'GTK_ASSISTANT_PAGE_PROGRESS');
  $assistant->set_page_title($page, "Applying changes");

  # This prevents the assistant window from being
  # closed while we're "busy" applying changes.
  $assistant->set_page_complete($page, FALSE);
}

sub do {  
  my $do_widget = shift;

  if (!$assistant) {
      $assistant = Gtk2::Assistant->new ();

	  $assistant->set_default_size(-1, 300);

      $assistant->set_screen ($do_widget->get_screen)
        if Gtk2->CHECK_VERSION (2, 2, 0);

      create_page1 ($assistant);
      create_page2 ($assistant);
      create_page3 ($assistant);
      create_page4 ($assistant);

      $assistant->signal_connect ("cancel",
			\&on_assistant_close_cancel, \$assistant);
      $assistant->signal_connect ("close",
			\&on_assistant_close_cancel, \$assistant);
      $assistant->signal_connect ("apply",
			\&on_assistant_apply, undef);
      $assistant->signal_connect ("prepare",
			\&on_assistant_prepare, undef);
    }

  if (!$assistant->visible()) {
      $assistant->show();
  } else {
      $assistant->destroy();
      $assistant = undef;
  }

  return $assistant;
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
