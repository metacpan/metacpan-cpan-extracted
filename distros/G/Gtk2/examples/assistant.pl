#!/usr/bin/perl -w
# 
# GTK - The GIMP Toolkit
# Copyright (C) 1999  Red Hat, Inc.
# Copyright (C) 2002  Anders Carlsson <andersca@gnu.org>
# Copyright (C) 2003  Matthias Clasen <mclasen@redhat.com>
# Copyright (C) 2005  Carlos Garnacho Parro <carlosg@gnome.org>
# Copyright (C) 2006  muppet <scott at asofyet dot org>
#
# All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.
#


use strict;
use Gtk2 -init;
use Glib ':constants';


sub get_test_page {
  return Gtk2::Label->new (shift);
}

sub complete_cb {
  my ($check, $data) = @_;
  $data->{assistant}->set_page_complete ($data->{page}, $check->get_active);
}
	     
sub add_completion_test_page {
  my ($assistant, $text, $visible, $complete) = @_;

  my $page = Gtk2::VBox->new;
  my $check = Gtk2::CheckButton->new_with_label ("Complete");

  $page->add (Gtk2::Label->new ($text));
  $page->add ($check);
  
  $check->set_active ($complete);

  my %pdata = (
    assistant => $assistant,
    page => $page,
  );
  $check->signal_connect (toggled => \&complete_cb, \%pdata);

  $page->show_all if $visible;

  $assistant->append_page ($page);
  $assistant->set_page_title ($page, $text);
  $assistant->set_page_complete ($page, $complete);

  return $page;
}

sub cancel_callback {
  my $widget = shift;
  print "cancel\n";
  $widget->hide;
}

sub close_callback {
  my $widget = shift;
  print "close\n";
  $widget->hide;
}

sub apply_callback {
  my $widget = shift;
  print "apply\n";
}

sub progress_timeout {
  my $assistant = shift;

  my $current_page = $assistant->get_current_page;
  my $page = $assistant->get_nth_page ($current_page);
  my $progress = $page->child;

  my $value  = $progress->get_fraction;
  $value += 0.1;
  $progress->set_fraction ($value);

  if ($value >= 1.0) {
    $assistant->set_page_complete ($page, TRUE);
    return FALSE;
  }

  return TRUE;
}

sub prepare_callback {
  my ($assistant, $page) = @_;

  if ($page->isa ('Gtk2::Label')) {
    print "prepare: ".$page->get_text."\n";
  } elsif ($assistant->get_page_type ($page) eq 'progress') {
    my $progress = $page->child;
    $assistant->set_page_complete ($page, FALSE);
    $progress->set_fraction (0.0);
    Glib::Timeout->add (300, \&progress_timeout, $assistant);
  } else {
    print "prepare: ".$assistant->get_current_page,"\n";
  }
}

sub create_simple_assistant {
  my $widget = shift;

  my $assistant = $widget->{assistant};

  if (!$assistant)
    {
      $assistant = Gtk2::Assistant->new;
      $assistant->set_default_size (400, 300);

      $assistant->signal_connect (cancel => \&cancel_callback);
      $assistant->signal_connect (close => \&close_callback);
      $assistant->signal_connect (apply => \&apply_callback);
      $assistant->signal_connect (prepare => \&prepare_callback);

      my $page = get_test_page ("Page 1");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Page 1");
      $assistant->set_page_complete ($page, TRUE);

      $page = get_test_page ("Page 2");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Page 2");
      $assistant->set_page_type ($page, 'confirm');
      $assistant->set_page_complete ($page, TRUE);
    }

  if (!$assistant->visible) {
    $assistant->show;
  } else {
    $assistant->destroy;
    $assistant = undef;
  }

  $widget->{assistant} = $assistant;
}

sub visible_cb {
  my ($check, $page) = @_;
  $page->set (visible => $check->get_active);
}

sub create_generous_assistant {
  my ($widget) = @_;

  my $assistant = $widget->{assistant};

  if (!$assistant)
    {
      $assistant = Gtk2::Assistant->new;
      $assistant->set_default_size (400, 300);

      $assistant->signal_connect (cancel => \&cancel_callback);
      $assistant->signal_connect (close => \&close_callback);
      $assistant->signal_connect (apply => \&apply_callback);
      $assistant->signal_connect (prepare => \&prepare_callback);

      my $page = get_test_page ("Introduction");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Introduction");
      $assistant->set_page_type ($page, 'intro');
      $assistant->set_page_complete ($page, TRUE);

      $page = add_completion_test_page ($assistant, "Content", TRUE, FALSE);
      my $next = add_completion_test_page ($assistant, "More Content", TRUE, TRUE);

      my $check = Gtk2::CheckButton->new ("Next page visible");
      $check->set_active (TRUE);
      $check->signal_connect (toggled => \&visible_cb, $next);
      $check->show;
      $page->add ($check);
      
      add_completion_test_page ($assistant, "Even More Content", TRUE, TRUE);

      $page = get_test_page ("Confirmation");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Confirmation");
      $assistant->set_page_type ($page, 'confirm');
      $assistant->set_page_complete ($page, TRUE);

      $page = Gtk2::Alignment->new (0.5, 0.5, 0.9, 0.0);
      $page->add (Gtk2::ProgressBar->new ());
      $page->show_all;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Progress");
      $assistant->set_page_type ($page, 'progress');

      $page = get_test_page ("Summary");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Summary");
      $assistant->set_page_type ($page, 'summary');
      $assistant->set_page_complete ($page, TRUE);
    }

  if (!$assistant->visible) {
    $assistant->show;
  } else {
    $assistant->destroy;
    $assistant = undef;
  }

  $widget->{assistant} = $assistant;
}

my $selected_branch = 'A';

sub select_branch {
  my ($widget, $branch) = @_;
  $selected_branch = $branch;
}

sub nonlinear_assistant_forward_page {
  my ($current_page, $data) = @_;

  if ($current_page == 0) {
    return $selected_branch eq 'A' ? 1 : 2;
  } elsif ($current_page == 1 || $current_page == 2) {
    return 3;
  } else {
    return -1;
  }
}

sub create_nonlinear_assistant {
  my ($widget) = @_;

  my $assistant = $widget->{assistant};

  if (!$assistant)
    {
      $assistant = Gtk2::Assistant->new ();
      $assistant->set_default_size (400, 300);

      $assistant->signal_connect (cancel => \&cancel_callback);
      $assistant->signal_connect (close => \&close_callback);
      $assistant->signal_connect (apply => \&apply_callback);
      $assistant->signal_connect (prepare => \&prepare_callback);

      $assistant->set_forward_page_func (\&nonlinear_assistant_forward_page);

      my $page = Gtk2::VBox->new (FALSE, 6);

      my $button = Gtk2::RadioButton->new_with_label (undef, "branch A");
      $page->pack_start ($button, FALSE, FALSE, 0);
      $button->signal_connect (toggled => \&select_branch, 'A');
      $button->set_active (TRUE);
      
      $button = Gtk2::RadioButton->new_with_label ($button->get_group,
						   "branch B");
      $page->pack_start ($button, FALSE, FALSE, 0);
      $button->signal_connect (toggled => \&select_branch, 'B');

      $page->show_all;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Page 1");
      $assistant->set_page_complete ($page, TRUE);
      
      $page = get_test_page ("Page 2A");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Page 2A");
      $assistant->set_page_complete ($page, TRUE);

      $page = get_test_page ("Page 2B");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Page 2B");
      $assistant->set_page_complete ($page, TRUE);

      $page = get_test_page ("Confirmation");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Confirmation");
      $assistant->set_page_type ($page, 'confirm');
      $assistant->set_page_complete ($page, TRUE);
    }

  if (!$assistant->visible) {
    $assistant->show;
  } else {
    $assistant->destroy;
    $assistant = undef;
  }

  $widget->{assistant} = $assistant;
}

sub looping_assistant_forward_page {
  my ($current_page, $assistant) = @_;
  print "@_\n";

  if ($current_page == 0) {
    return 1;
  } elsif ($current_page == 1) {
    return 2;
  } elsif ($current_page == 2) {
    return 3;
  } elsif ($current_page == 3) {
    my $page = $assistant->get_nth_page ($current_page);
    return $page->get_active ? 0 : 4;
  } else {
    return -1;
  }
}

sub create_looping_assistant {
  my $widget = shift;

  my $assistant = $widget->{assistant};

  if (!$assistant)
    {
      $assistant = Gtk2::Assistant->new ();
      $assistant->set_default_size (400, 300);

      $assistant->signal_connect (cancel => \&cancel_callback);
      $assistant->signal_connect (close => \&close_callback);
      $assistant->signal_connect (apply => \&apply_callback);
      $assistant->signal_connect (prepare => \&prepare_callback);

      $assistant->set_forward_page_func (\&looping_assistant_forward_page,
					 $assistant);

      my $page = get_test_page ("Introduction");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Introduction");
      $assistant->set_page_type ($page, 'intro');
      $assistant->set_page_complete ($page, TRUE);

      $page = get_test_page ("Content");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Content");
      $assistant->set_page_complete ($page, TRUE);

      $page = get_test_page ("More content");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "More content");
      $assistant->set_page_complete ($page, TRUE);

      $page = Gtk2::CheckButton->new_with_label ("Loop?");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Loop?");
      $assistant->set_page_complete ($page, TRUE);
      
      $page = get_test_page ("Confirmation");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Confirmation");
      $assistant->set_page_type ($page, 'confirm');
      $assistant->set_page_complete ($page, TRUE);
    }

  if (!$assistant->visible) {
    $assistant->show;
  } else {
    $assistant->destroy;
    $assistant = undef;
  }

  $widget->{assistant} = $assistant;
}

sub create_full_featured_assistant {
  my $widget = shift;

  my $assistant = $widget->{assistant};

  if (!$assistant)
    {
      $assistant = Gtk2::Assistant->new ();
      $assistant->set_default_size (400, 300);

      my $button = Gtk2::Button->new_from_stock ('stop');
      $button->show;
      $assistant->add_action_widget ($button);

      $assistant->signal_connect (cancel => \&cancel_callback);
      $assistant->signal_connect (close => \&close_callback);
      $assistant->signal_connect (apply => \&apply_callback);
      $assistant->signal_connect (prepare => \&prepare_callback);

      my $page = get_test_page ("Page 1");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Page 1");
      $assistant->set_page_complete ($page, TRUE);

      # set a side image
      my $pixbuf = $page->render_icon ('gtk-dialog-warning', 'dialog');
      $assistant->set_page_side_image ($page, $pixbuf);

      # set a header image
      $pixbuf = $page->render_icon ('gtk-dialog-info', 'dialog');
      $assistant->set_page_header_image ($page, $pixbuf);

      $page = get_test_page ("Invisible page");
      $assistant->append_page ($page);

      $page = get_test_page ("Page 3");
      $page->show;
      $assistant->append_page ($page);
      $assistant->set_page_title ($page, "Page 3");
      $assistant->set_page_type  ($page, 'confirm');
      $assistant->set_page_complete ($page, TRUE);

      # set a header image
      $pixbuf = $page->render_icon ('gtk-dialog-info', 'dialog');
      $assistant->set_page_header_image ($page, $pixbuf);
    }

  if (!$assistant->visible) {
    $assistant->show;
  } else {
    $assistant->destroy;
    $assistant = undef;
  }

  $widget->{assistant} = $assistant;
}

{
  Gtk2::Widget->set_default_direction ('rtl') if $ENV{'RTL'};

  my $window = Gtk2::Window->new;

  $window->signal_connect (destroy => sub { Gtk2->main_quit });
  $window->signal_connect (delete_event => sub { FALSE });

  my $box = Gtk2::VBox->new;
  $window->add ($box);

  my @tests = (
    { text => "simple assistant",        func => \&create_simple_assistant },
    { text => "generous assistant",      func => \&create_generous_assistant },
    { text => "nonlinear assistant",     func => \&create_nonlinear_assistant },
    { text => "looping assistant",       func => \&create_looping_assistant },
    { text => "full featured assistant", func => \&create_full_featured_assistant },
  );

  foreach my $test (@tests) {
    my $button = Gtk2::Button->new ($test->{text});

    $button->signal_connect (clicked => $test->{func});

    $box->pack_start ($button, TRUE, TRUE, 0);
  }

  $window->show_all;
  Gtk2->main ();
}
