#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2::Ex::ErrorTextDialog;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

BEGIN {
  # Test::Weaken 3 for "contents"
  my $have_test_weaken = eval "use Test::Weaken 3;
                               use Test::Weaken::Gtk2;
                               1";
  if (! $have_test_weaken) {
    plan skip_all => "due to Test::Weaken 3 and/or Test::Weaken::Gtk2 not available -- $@";
  }
  diag ("Test::Weaken version ", Test::Weaken->VERSION);

  require Gtk2;
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  my $have_display = Gtk2->init_check;
  if (! $have_display) {
    plan skip_all => "due to no DISPLAY available";
  }

  plan tests => 5;
}

MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------
# TextView::FollowAppend

diag "on TextView::FollowAppend->new()";
{
  require Gtk2::Ex::TextView::FollowAppend;
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { return Gtk2::Ex::TextView::FollowAppend->new },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}
diag "on TextView::FollowAppend->new_with_buffer()";
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $textbuf = Gtk2::TextBuffer->new;
         my $textview
           = Gtk2::Ex::TextView::FollowAppend->new_with_buffer ($textbuf);
         return [ $textview, $textbuf ];
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}


#-----------------------------------------------------------------------------
# ErrorTextDialog

diag "on new() ErrorTextDialog";
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $dialog = Gtk2::Ex::ErrorTextDialog->new;
         $dialog->realize;
         MyTestHelpers::main_iterations ();
         return $dialog;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}


diag "on instance() ErrorTextDialog";
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $dialog = Gtk2::Ex::ErrorTextDialog->instance;
         $dialog->realize;
         MyTestHelpers::main_iterations ();
         return $dialog;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

# with save dialog
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $error_dialog = Gtk2::Ex::ErrorTextDialog->new;
         my $save_dialog = do {
           local $SIG{'__WARN__'} = \&MyTestHelpers::warn_suppress_gtk_icon;
           $error_dialog->_save_dialog
         };
         $error_dialog->present;
         $save_dialog->present;
         MyTestHelpers::main_iterations ();
         return [ $error_dialog, $save_dialog ];
       },
       # $save_dialog is destroy-with-parent, so destructor only on
       # $error_dialog
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef,
      'Test::Weaken deep garbage collection -- with save dialog too');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
