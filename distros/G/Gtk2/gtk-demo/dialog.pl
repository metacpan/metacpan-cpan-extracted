#!/usr/bin/perl -w
#
# Dialog and Message Boxes
#
# Dialog widgets are used to pop up a transient window for user feedback.
#

package dialog;

use Glib qw(TRUE FALSE);
use Gtk2;

my $window = undef;
my $entry1 = undef;
my $entry2 = undef;

my $i = 1;

sub message_dialog_clicked {
  my $dialog = Gtk2::MessageDialog->new ($window,
				   [qw/modal destroy-with-parent/],
				   'info',
				   'ok',
				   sprintf "This message box has been popped up the following\nnumber of times:\n\n%d", $i);
  $dialog->run;
  $dialog->destroy;
  $i++;
}

sub interactive_dialog_clicked {
  #my $dialog = Gtk2::Dialog->new_with_buttons ("Interactive Dialog",
  my $dialog = Gtk2::Dialog->new ("Interactive Dialog",
					$window,
					[qw/modal destroy-with-parent/],
					'gtk-ok',
					'ok',
                                        "_Non-stock Button",
                                        'cancel');

  my $hbox = Gtk2::HBox->new (FALSE, 8);
  $hbox->set_border_width (8);
  $dialog->vbox->pack_start ($hbox, FALSE, FALSE, 0);

  my $stock = Gtk2::Image->new_from_stock ('gtk-dialog-question', 'dialog');
  $hbox->pack_start ($stock, FALSE, FALSE, 0);

  my $table = Gtk2::Table->new (2, 2, FALSE);
  $table->set_row_spacings (4);
  $table->set_col_spacings (4);
  $hbox->pack_start ($table, TRUE, TRUE, 0);
  my $label = Gtk2::Label->new_with_mnemonic ("_Entry 1");
  $table->attach_defaults ($label, 0, 1, 0, 1);
  my $local_entry1 = Gtk2::Entry->new;
  $local_entry1->set_text ($entry1->get_text);
  $table->attach_defaults ($local_entry1, 1, 2, 0, 1);
  $label->set_mnemonic_widget ($local_entry1);

  $label = Gtk2::Label->new_with_mnemonic ("E_ntry 2");
  $table->attach_defaults ($label, 0, 1, 1, 2);

  my $local_entry2 = Gtk2::Entry->new;
  $local_entry2->set_text ($entry2->get_text);
  $table->attach_defaults ($local_entry2, 1, 2, 1, 2);
  $label->set_mnemonic_widget ($local_entry2);
  
  $hbox->show_all;
  my $response = $dialog->run;

  if ($response eq 'ok') {
      $entry1->set_text ($local_entry1->get_text);
      $entry2->set_text ($local_entry2->get_text);
  }

  $dialog->destroy;
}

sub do {
  if (!$window) {
      $window = Gtk2::Window->new;
      $window->set_title ("Dialogs");

      $window->signal_connect (destroy => sub { $window = undef; 1 });
      $window->set_border_width (8);

      my $frame = Gtk2::Frame->new ("Dialogs");
      $window->add ($frame);

      my $vbox = Gtk2::VBox->new (FALSE, 8);
      $vbox->set_border_width (8);
      $frame->add ($vbox);

      # Standard message dialog
      my $hbox = Gtk2::HBox->new (FALSE, 8);
      $vbox->pack_start ($hbox, FALSE, FALSE, 0);
      my $button = Gtk2::Button->new_with_mnemonic ("_Message Dialog");
      $button->signal_connect (clicked => \&message_dialog_clicked);
      $hbox->pack_start ($button, FALSE, FALSE, 0);

      $vbox->pack_start (Gtk2::HSeparator->new, FALSE, FALSE, 0);

      # Interactive dialog
      $hbox = Gtk2::HBox->new (FALSE, 8);
      $vbox->pack_start ($hbox, FALSE, FALSE, 0);
      $vbox2 = Gtk2::VBox->new (FALSE, 0);

      $button = Gtk2::Button->new_with_mnemonic ("_Interactive Dialog");
      $button->signal_connect (clicked => \&interactive_dialog_clicked);
      $hbox->pack_start ($vbox2, FALSE, FALSE, 0);
      $vbox2->pack_start ($button, FALSE, FALSE, 0);

      my $table = Gtk2::Table->new (2, 2, FALSE);
      $table->set_row_spacings (4);
      $table->set_col_spacings (4);
      $hbox->pack_start ($table, FALSE, FALSE, 0);

      my $label = Gtk2::Label->new_with_mnemonic ("_Entry 1");
      $table->attach_defaults ($label, 0, 1, 0, 1);

      $entry1 = Gtk2::Entry->new;
      $table->attach_defaults ($entry1, 1, 2, 0, 1);
      $label->set_mnemonic_widget ($entry1);

      $label = Gtk2::Label->new_with_mnemonic ("E_ntry 2");
      
      $table->attach_defaults ($label, 0, 1, 1, 2);

      $entry2 = Gtk2::Entry->new;
      $table->attach_defaults ($entry2, 1, 2, 1, 2);
      $label->set_mnemonic_widget ($entry2);
  }

  if (!$window->visible) {
      $window->show_all;
  } else {    
      $window->destroy;
      $window = undef;
  }

  return $window;
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
