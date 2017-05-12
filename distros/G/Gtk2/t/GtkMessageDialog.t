#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 8;

# $Id$

my $dialog = Gtk2::MessageDialog -> new(undef,
                                        "destroy-with-parent",
                                        "warning",
                                        "ok-cancel",
                                        "%s, %d", "Bla", 23);
isa_ok($dialog, "Gtk2::MessageDialog");

$dialog = Gtk2::MessageDialog -> new(undef,
                                     "destroy-with-parent",
                                     "warning",
                                     "ok-cancel",
                                     "Bla, 23");
isa_ok($dialog, "Gtk2::MessageDialog");

$dialog = Gtk2::MessageDialog -> new(undef,
                                     "destroy-with-parent",
                                     "warning",
                                     "ok-cancel",
                                     undef);
isa_ok($dialog, "Gtk2::MessageDialog");

# Make we sure we get the custom 'response' signal marshaller.
{
  my $dialog = Gtk2::MessageDialog -> new(undef,
                                          "destroy-with-parent",
                                          "warning",
                                          "ok-cancel",
                                          undef);
  $dialog->signal_connect(response => sub {
    is ($_[1], 'ok');
    Gtk2->main_quit;
  });
  $dialog->show;
  run_main (sub { $dialog->response ('ok'); });
}

SKIP: {
  skip("new_with_markup and set_markup are new in 2.4", 2)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $dialog = Gtk2::MessageDialog -> new_with_markup(undef,
                                                   "destroy-with-parent",
                                                   "warning",
                                                   "ok-cancel",
                                                   "<span>Bla, 23</span>");
  isa_ok($dialog, "Gtk2::MessageDialog");

  $dialog = Gtk2::MessageDialog -> new_with_markup(undef,
                                                   "destroy-with-parent",
                                                   "warning",
                                                   "ok-cancel",
                                                   undef);
  isa_ok($dialog, "Gtk2::MessageDialog");

  $dialog -> set_markup("<span>Bla, 23</span>");
}

SKIP: {
  skip("new 2.6 stuff", 0)
    unless Gtk2->CHECK_VERSION (2, 6, 0);

  $dialog -> format_secondary_text("%s, %d", "Bla", 23);
  $dialog -> format_secondary_text("Bla, 23");
  $dialog -> format_secondary_text(undef);

  $dialog -> format_secondary_markup("<span>%s, %d</span>", "Bla", 23);
  $dialog -> format_secondary_markup("<span>Bla, 23</span>");
  $dialog -> format_secondary_markup(undef);
}

my $image = Gtk2::Label -> new(":-)");

SKIP: {
  skip("new 2.10 stuff", 0)
    unless Gtk2->CHECK_VERSION (2, 10, 0);

  $dialog -> set_image($image);
}

SKIP: {
  skip 'new 2.14 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 14, 0);

  is ($dialog -> get_image(), $image);
}

SKIP: {
  skip 'new 2.22 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  isa_ok ($dialog -> get_message_area(), 'Gtk2::Widget');
}

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
