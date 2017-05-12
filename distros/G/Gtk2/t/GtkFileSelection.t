#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 19;

# $Id$

my $fs = Gtk2::FileSelection -> new("Bla");
isa_ok($fs, "Gtk2::FileSelection");

isa_ok($fs -> dir_list(), "Gtk2::TreeView");
isa_ok($fs -> file_list(), "Gtk2::TreeView");
isa_ok($fs -> selection_entry(), "Gtk2::Entry");
isa_ok($fs -> selection_text(), "Gtk2::Label");
isa_ok($fs -> main_vbox(), "Gtk2::VBox");
isa_ok($fs -> ok_button(), "Gtk2::Button");
isa_ok($fs -> cancel_button(), "Gtk2::Button");
# isa_ok($fs -> help_button(), "Gtk2::Button");
isa_ok($fs -> history_pulldown(), "Gtk2::OptionMenu");
isa_ok($fs -> history_menu(), "Gtk2::Menu");
# isa_ok($fs -> fileop_dialog(), "Gtk2::Dialog");
# isa_ok($fs -> fileop_entry(), "Gtk2::Entry");
isa_ok($fs -> fileop_c_dir(), "Gtk2::Button");
isa_ok($fs -> fileop_del_file(), "Gtk2::Button");
isa_ok($fs -> fileop_ren_file(), "Gtk2::Button");
isa_ok($fs -> button_area(), "Gtk2::Widget");
isa_ok($fs -> action_area(), "Gtk2::HBox");

use Cwd;
use File::Spec;

my $this = File::Spec -> catfile(cwd(), $0);

$fs -> set_filename($this);
is($fs -> get_filename(), $this);

my $that = $this;
substr($that, -1, 1, "");

$fs -> complete($that);
is($fs -> get_filename(), $this);

$fs -> show_fileop_buttons();
$fs -> hide_fileop_buttons();

is_deeply([$fs -> get_selections()], [$this]);

$fs -> set_select_multiple(1);
is($fs -> get_select_multiple(), 1);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
