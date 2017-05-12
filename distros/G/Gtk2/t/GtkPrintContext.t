#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 11,
  at_least_version => [2, 10, 0, "GtkPrintContext is new in 2.10"];

# $Id$

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

# I hope that signal will always fire ...

my $op = Gtk2::PrintOperation -> new();
$op -> signal_connect(begin_print => sub {
  my ($op, $context) = @_;

  isa_ok($context, "Gtk2::PrintContext");
  isa_ok(my $cr = $context -> get_cairo_context(), "Cairo::Context");
  isa_ok($context -> get_page_setup(), "Gtk2::PageSetup");
  ok(defined $context -> get_width());
  ok(defined $context -> get_height());
  ok(defined $context -> get_dpi_x());
  ok(defined $context -> get_dpi_y());
  isa_ok($context -> get_pango_fontmap(), "Gtk2::Pango::FontMap");
  isa_ok($context -> create_pango_context(), "Gtk2::Pango::Context");
  isa_ok($context -> create_pango_layout(), "Gtk2::Pango::Layout");

  $context -> set_cairo_context($cr, 72, 72);

  SKIP: {
    skip 'new 2.20 stuff', 1
      unless Gtk2->CHECK_VERSION(2, 20, 0);

    my ($top, $bottom, $left, $right) = $context -> get_hard_margins();
    ok((defined $top && defined $bottom && defined $left && defined $right) ||
       (!defined $top && !defined $bottom && !defined $left && !defined $right));
  }
});

$op -> set_n_pages(1);
$op -> set_allow_async(TRUE);
$op -> set_export_filename("$dir/test.pdf");

$op -> run("export", undef);
$op -> cancel();

__END__

Copyright (C) 2006, 2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
