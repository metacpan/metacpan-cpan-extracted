#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

# $Id: GtkSourceTag.t,v 1.1 2005/08/11 18:01:56 kaffeetisch Exp $

use Glib qw(TRUE FALSE);
use Gtk2::SourceView;

my $tag = Gtk2::SourceView::SyntaxTag -> new("brackets", "Brackets", "[(\[{]", "[)\]}]");
isa_ok($tag, "Gtk2::SourceView::SyntaxTag");
isa_ok($tag, "Gtk2::SourceView::Tag");

$tag = Gtk2::SourceView::PatternTag -> new("our", "Our", "our");
isa_ok($tag, "Gtk2::SourceView::PatternTag");
isa_ok($tag, "Gtk2::SourceView::Tag");

is($tag -> get_id(), "our");

my $style = Gtk2::SourceView::TagStyle -> new();
$tag -> set_style($style);
isa_ok($tag -> get_style(), "Gtk2::SourceView::TagStyle");

$tag = Gtk2::SourceView::KeywordListTag -> new(
         "loops", "Loops", [qw(for foreach while)],
         TRUE, TRUE, TRUE, '\s', '\s');
isa_ok($tag, "Gtk2::TextTag");

$tag = Gtk2::SourceView::LineCommentTag -> new("pound", "Pound", "#");
isa_ok($tag, "Gtk2::TextTag");

$tag = Gtk2::SourceView::StringTag -> new("double", "Double", '"', '"', FALSE);
isa_ok($tag, "Gtk2::TextTag");
