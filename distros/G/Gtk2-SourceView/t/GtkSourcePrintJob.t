#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 24;

# $Id$

use Glib qw(TRUE FALSE);
use Gtk2::SourceView;

my $config = Gnome2::Print::Config -> default();
my $table = Gtk2::SourceView::TagTable -> new();
my $buffer = Gtk2::SourceView::Buffer -> new($table);
my $view = Gtk2::SourceView::View -> new();

my $job = Gtk2::SourceView::PrintJob -> new($config);
isa_ok($job, "Gtk2::SourceView::PrintJob");

$job = Gtk2::SourceView::PrintJob -> new_with_buffer($config, $buffer);
isa_ok($job, "Gtk2::SourceView::PrintJob");

$job -> set_config($config);
is($job -> get_config(), $config);

$job -> set_buffer($buffer);
is($job -> get_buffer(), $buffer);

Gtk2 -> init();
$job -> setup_from_view($view);

$job -> set_tabs_width(8);
is($job -> get_tabs_width(), 8);

$job -> set_wrap_mode("word");
is($job -> get_wrap_mode(), "word");

$job -> set_highlight(TRUE);
is($job -> get_highlight(), TRUE);

$job -> set_font("Sans 12");
like($job -> get_font(), qr/Sans/);

$job -> set_numbers_font("Sans 12");
like($job -> get_numbers_font(), qr/Sans/);

$job -> set_print_numbers(42);
is($job -> get_print_numbers(), 42);

$job -> set_text_margins(1, 2, 3, 4);
is_deeply([$job -> get_text_margins()], [1, 2, 3, 4]);

SKIP: {
  skip "font desc stuff", 3
    unless Gtk2::SourceView -> CHECK_VERSION(1, 2, 0);

  my $description = Gtk2::Pango::FontDescription -> new();
  $description -> set_family("Sans");
  $description -> set_size(12);

  $job -> set_font_desc($description);
  isa_ok($job -> get_font_desc(), "Gtk2::Pango::FontDescription");

  $job -> set_numbers_font_desc($description);
  isa_ok($job -> get_font_desc(), "Gtk2::Pango::FontDescription");

  $job -> set_header_footer_font_desc($description);
  isa_ok($job -> get_font_desc(), "Gtk2::Pango::FontDescription");
}

SKIP: {
  skip "I suppose I shouldn't do any test prints ;-)", 7
    unless (0);

  isa_ok($job -> print(), "Gnome2::Print::Job");
  isa_ok($job -> print_range($buffer -> get_bounds()), "Gnome2::Print::Job");
  ok($job -> print_range_async($buffer -> get_bounds()));
  isa_ok($job -> get_print_job(), "Gnome2::Print::Job");
  is($job -> get_page(), 0);
  is($job -> get_page_count(), 1);
  isa_ok($job -> get_print_context(), "Gnome2::Print::Context");

  $job -> cancel();
}

$job -> set_print_header(TRUE);
is($job -> get_print_header(), TRUE);

$job -> set_print_footer(TRUE);
is($job -> get_print_footer(), TRUE);

$job -> set_header_footer_font("Sans 12");
like($job -> get_header_footer_font(), qr/Sans/);

$job -> set_header_format("%s", "%s", "%s", TRUE);
$job -> set_footer_format("%s", "%s", "%s", TRUE);
