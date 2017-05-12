#!/usr/bin/perl -w

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

use 5.008;
use strict;
use warnings;
use Gtk2::Ex::ErrorTextDialog::SaveDialog;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2;
MyTestHelpers::glib_gtk_versions();

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY available";

plan tests => 10;

#-----------------------------------------------------------------------------

my $want_version = 11;
is ($Gtk2::Ex::ErrorTextDialog::SaveDialog::VERSION, $want_version,
    'VERSION variable');
is (Gtk2::Ex::ErrorTextDialog::SaveDialog->VERSION, $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::ErrorTextDialog::SaveDialog->VERSION($want_version); 1 },
    "VERSION class check $want_version");
ok (! eval { Gtk2::Ex::ErrorTextDialog::SaveDialog->VERSION($want_version + 1000); 1 },
    "VERSION class check " . ($want_version + 1000));

#-----------------------------------------------------------------------------
# dialog and saving

{
  my $dialog = do {
    local $SIG{'__WARN__'} = \&MyTestHelpers::warn_suppress_gtk_icon;
    Gtk2::Ex::ErrorTextDialog::SaveDialog->new;
  };

  is ($dialog->VERSION, $want_version, 'VERSION object method');
  ok (eval { $dialog->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $dialog->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));

  my $errdialog = Gtk2::Ex::ErrorTextDialog->new;
  $errdialog->add_message ("hello\n");
  $dialog->set_transient_for ($errdialog);

  require File::Temp;
  my $fh = File::Temp->new;
  my $filename = $fh->filename;
  diag "temp file $filename";

  # for some very dubious reason set_current_name() doesn't work until the
  # dialog is shown, and not just realized either, :-(
  $dialog->show;
  MyTestHelpers::main_iterations ();
  $dialog->set_current_name($filename);
  is ($dialog->get_filename, $filename, "filename set into dialog: $filename");

 SKIP: {
    $dialog->get_filename eq $filename
      or skip "filename not set correctly into dialog, don't want to overwrite something else", 1;
    $dialog->save;
    my $str = do { local $/ = undef; <$fh> }; # slurp
    is ($str, "hello\n", "saved to $filename");
  }

  $dialog->destroy;
  $errdialog->destroy;
}

#-----------------------------------------------------------------------------
# destroy and weaken

{
  my $dialog = do {
    local $SIG{'__WARN__'} = \&MyTestHelpers::warn_suppress_gtk_icon;
    Gtk2::Ex::ErrorTextDialog::SaveDialog->new;
  };
  require Scalar::Util;
  Scalar::Util::weaken ($dialog);
  $dialog->destroy;
  MyTestHelpers::main_iterations ();
  is ($dialog, undef, 'garbage collect after destroy');
}

exit 0;
