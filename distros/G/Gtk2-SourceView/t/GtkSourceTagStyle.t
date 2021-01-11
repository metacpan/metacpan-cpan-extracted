#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

# $Id$

use Gtk2::SourceView;

my $style = Gtk2::SourceView::TagStyle->new();
isa_ok($style, "Gtk2::SourceView::TagStyle");

my $manager = Gtk2::SourceView::LanguagesManager->new();
my $language = $manager->get_language_from_mime_type("application/x-perl");

my @tags = $language->get_tags();
my $id = $tags[0]->get("id");

my $s = $language->get_tag_default_style($id);
isa_ok($s, "Gtk2::SourceView::TagStyle");

ok($s->is_default);

my $fg = Gtk2::Gdk::Color->new(255, 0, 0);
isa_ok($style->foreground($fg), "Gtk2::Gdk::Color");

my $bg = Gtk2::Gdk::Color->new(0, 0, 255);
isa_ok($style->background($bg), "Gtk2::Gdk::Color");
