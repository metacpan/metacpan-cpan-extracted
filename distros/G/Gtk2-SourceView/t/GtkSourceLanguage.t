#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;

# $Id$

use Gtk2::SourceView;

my $manager = Gtk2::SourceView::LanguagesManager -> new();
my $language = $manager -> get_language_from_mime_type("application/x-perl");

is($language -> get_id(), "Perl");
is($language -> get_name(), "Perl");
is($language -> get_section(), "Scripts");

my @tags = $language -> get_tags();
isa_ok($tags[0], "Gtk2::SourceView::Tag");

is($language -> get_escape_char(), "\\");

my @original_mime_types = $language -> get_mime_types();
ok(@original_mime_types > 0);

$language -> set_mime_types("bla/blub", "blub/bla");
is_deeply([$language -> get_mime_types()],
          ["bla/blub", "blub/bla"]);

$language -> set_mime_types();
is_deeply([$language -> get_mime_types()],
          [reverse @original_mime_types]); # FIXME: Bug in gtksourceview?

$language -> set_mime_types(undef);
is_deeply([$language -> get_mime_types()],
          [reverse @original_mime_types]); # FIXME: Bug in gtksourceview?

my $scheme = $language -> get_style_scheme();
isa_ok($scheme, "Gtk2::SourceView::StyleScheme");

$language -> set_style_scheme($scheme);

my $id = $tags[0] -> get("id");

my $style = $language -> get_tag_style($id);
isa_ok($style, "Gtk2::SourceView::TagStyle");

$language -> set_tag_style($id, $style);
isa_ok($style, "Gtk2::SourceView::TagStyle");

$language -> set_tag_style($id, undef);
isa_ok($style, "Gtk2::SourceView::TagStyle");

$style = $language -> get_tag_default_style($id);
isa_ok($style, "Gtk2::SourceView::TagStyle");
