#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::ErrorTextDialog;

require Gtk2;
MyTestHelpers::glib_gtk_versions();

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY available";

plan tests => 20;

#-----------------------------------------------------------------------------

my $want_version = 11;
{
  is ($Gtk2::Ex::ErrorTextDialog::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ErrorTextDialog->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::ErrorTextDialog->VERSION($want_version); 1 },
      "VERSION class check $want_version");

  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ErrorTextDialog->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}
{
  my $dialog = Gtk2::Ex::ErrorTextDialog->new;

  is ($dialog->VERSION, $want_version, 'VERSION object method');
  ok (eval { $dialog->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $dialog->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  $dialog->destroy;
}

#-----------------------------------------------------------------------------
# Scalar::Util::weaken

diag "Scalar::Util::weaken";
{
  my $dialog = Gtk2::Ex::ErrorTextDialog->new;
  require Scalar::Util;
  Scalar::Util::weaken ($dialog);
  $dialog->destroy;
  MyTestHelpers::main_iterations ();
  is ($dialog, undef, 'garbage collect after destroy');
}

#-----------------------------------------------------------------------------
# instance()

{
  my $instance = Gtk2::Ex::ErrorTextDialog->instance;
  isa_ok ($instance, 'Gtk2::Ex::ErrorTextDialog');
  my $i2 = Gtk2::Ex::ErrorTextDialog->instance;
  is ($instance, $i2, 'instance() same from two calls');

  $instance->destroy;
  $i2 = Gtk2::Ex::ErrorTextDialog->instance;
  isnt ($instance, $i2, 'instance() different after ->destroy');
}

#-----------------------------------------------------------------------------
# _textbuf_ensure_final_newline()

# {
#   my $textbuf = Gtk2::TextBuffer->new;
#   foreach my $elem (['', ''],
#                     ["\n", "\n"],
#                     ["hello", "hello\n"],
#                     ["hello\n", "hello\n"],
#                     ["hello\nhello", "hello\nhello\n"],
#                     ["hello\nhello\n", "hello\nhello\n"],
#                    ) {
#     my ($text, $want) = @$elem;
# 
#     $textbuf->set (text => $text);
#     ## no critic (ProtectPrivateSubs)
#     Gtk2::Ex::ErrorTextDialog::_textbuf_ensure_final_newline($textbuf);
#     is ($textbuf->get('text'), $want,
#         "_textbuf_ensure_final_newline() on '$text'");
#   }
# }

#-----------------------------------------------------------------------------
# _message_dialog_set_text()

{
  my $dialog = Gtk2::MessageDialog->new (undef, [], 'info', 'ok',
                                         'An informational message');
  ## no critic (ProtectPrivateSubs)
  Gtk2::Ex::ErrorTextDialog::_message_dialog_set_text($dialog, 'new message');

  if ($dialog->find_property('text')) {
    is ($dialog->get('text'), 'new message',
        '_message_dialog_text_widget() messagedialog');
  } else {
    ok (1, "_message_dialog_text_widget() no 'text' property to read back");
  }
  $dialog->destroy;
}

#-----------------------------------------------------------------------------
# get_text()

{
  my $dialog = Gtk2::Ex::ErrorTextDialog->new;
  is ($dialog->get_text, '', 'get_text() when empty');
  $dialog->add_message ('hello');
  is ($dialog->get_text, "hello\n", 'get_text() of some text');
  $dialog->destroy;
}

#-----------------------------------------------------------------------------
# action signals

{
  my $dialog = Gtk2::Ex::ErrorTextDialog->new;
  my $textbuf = $dialog->{'textbuf'};

  my ($find_popup) = grep {$_->{'signal_name'} eq 'popup-save-dialog'}
    Glib::Type->list_signals ('Gtk2::Ex::ErrorTextDialog');
  ok ($find_popup, 'have "popup-save-dialog" signal');
  if ($find_popup) {
    diag "$find_popup->{'signal_name'} $find_popup->{'signal_id'} $find_popup->{'itype'} $find_popup->{'signal_flags'}";
  }

  $dialog->add_message ('hello');
  my $saw_popup = 0;
  $dialog->signal_connect (popup_save_dialog => sub { $saw_popup = 1 });
  { local $SIG{'__WARN__'} = \&MyTestHelpers::warn_suppress_gtk_icon;
    $dialog->popup_save_dialog;
  }
  is ($saw_popup, 1, 'popup_save_dialog() emits "popup-save-dialog"');
  isnt ($textbuf->get_char_count, 0, 'popup - textbuf still has message');

  $dialog->add_message ('hello');
  my $saw_clear = 0;
  $dialog->signal_connect (clear => sub { $saw_clear = 1 });
  $dialog->clear;
  is ($saw_clear, 1, 'clear() emits "clear"');
  is ($textbuf->get_char_count, 0, 'clear - textbuf now empty');

  $dialog->destroy;
}

#-----------------------------------------------------------------------------
# popup_add_message()

{
  Gtk2::Ex::ErrorTextDialog->popup_add_message ('hello');

  my $dialog = Gtk2::Ex::ErrorTextDialog->instance;
  isa_ok ($dialog, 'Gtk2::Ex::ErrorTextDialog');
  $dialog->popup_add_message ('hello');
}

exit 0;
