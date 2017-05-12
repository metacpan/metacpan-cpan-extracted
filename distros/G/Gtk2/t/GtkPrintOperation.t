#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 17,
  at_least_version => [2, 10, 0, "GtkPrintOperation is new in 2.10"];

# $Id$

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

my $op = Gtk2::PrintOperation -> new();
isa_ok($op, "Gtk2::PrintOperation");

my $setup = Gtk2::PageSetup -> new();
$op -> set_default_page_setup(undef);
is($op -> get_default_page_setup(), undef);
$op -> set_default_page_setup($setup);
is($op -> get_default_page_setup(), $setup);

my $settings = Gtk2::PrintSettings -> new();
$op -> set_print_settings(undef);
is($op -> get_print_settings(), undef);
$op -> set_print_settings($settings);
is($op -> get_print_settings(), $settings);

ok(defined $op -> get_status());
ok(defined $op -> get_status_string());
ok(defined $op -> is_finished());

sub get_op {
  my $op = Gtk2::PrintOperation -> new();
  $op -> set_job_name("Test");
  $op -> set_n_pages(2);
  $op -> set_current_page(1);
  $op -> set_use_full_page(TRUE);
  $op -> set_unit("mm");
  $op -> set_export_filename("$dir/test.pdf");
  $op -> set_track_print_status(TRUE);
  $op -> set_show_progress(FALSE);
  $op -> set_allow_async(TRUE);
  $op -> set_custom_tab_label("Print");
  return $op;
}

$op = get_op();
ok(defined $op -> run("export", undef));
$op -> cancel();

$op = get_op();
ok(defined $op -> run("export", Gtk2::Window -> new()));
$op -> cancel();

# FIXME: Don't know how to trigger an actual error.
# warn $op -> get_error();


SKIP: {
  skip 'draw page finish (2.16)', 3
    unless Gtk2->CHECK_VERSION(2, 16, 0);

  # NOTE draw_page_finish() has to be called under the right conditions
  #      otherwise the print context doesn't seem to be setup properly causing
  #      the program to crash with a segmentation fault.
  #
  #      This is tricky as draw_page_finish() must be called if
  #      set_defer_drawing() is called and the latter can be called only from
  #      the 'draw-page' callback.

  # 'draw-page' is called twice because there are 2 pages, see get_op()
  $op = get_op();
  $op -> signal_connect('draw-page' => sub {
    # Pretend that the drawing is asynchronous.
    $op -> set_defer_drawing();

    # Finish the drawing later
    Glib::Idle->add(sub {
      ok(TRUE, "Draw page finish called");
      $op -> draw_page_finish();
      return Glib::SOURCE_REMOVE;
    });
  });

  ok(defined $op -> run("export", Gtk2::Window -> new()));
}

SKIP: {
  skip 'new 2.18 stuff', 4
    unless Gtk2->CHECK_VERSION(2, 18, 0);

  my $op = Gtk2::PrintOperation -> new();

  $op -> set_embed_page_setup(TRUE);
  ok($op -> get_embed_page_setup());

  $op -> set_support_selection(TRUE);
  ok($op -> get_support_selection());

  $op -> set_has_selection(TRUE);
  ok($op -> get_has_selection());

  ok(defined $op -> get_n_pages_to_print());
}

=comment

# Can't non-interactively test these, I think.  I manually verified that they
# work though.

Gtk2::Print -> run_page_setup_dialog_async(
                 undef, undef, $settings,
                 sub { warn join ", ", @_; Gtk2 -> main_quit(); }, "data");
Gtk2 -> main();

Gtk2::Print -> run_page_setup_dialog_async(
                 $window, $setup, $settings,
                 sub { warn join ", ", @_; Gtk2 -> main_quit(); }, "data");
Gtk2 -> main();

warn Gtk2::Print -> run_page_setup_dialog(undef, undef, $settings);

warn Gtk2::Print -> run_page_setup_dialog($window, $setup, $settings);

=cut

__END__

Copyright (C) 2006, 2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
