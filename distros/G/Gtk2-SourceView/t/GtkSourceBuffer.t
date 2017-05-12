#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 19;

# $Id: GtkSourceBuffer.t,v 1.1 2005/08/11 18:01:56 kaffeetisch Exp $

use Glib qw(TRUE FALSE);
use Gtk2::SourceView;

my $table = Gtk2::SourceView::TagTable -> new();

my $buffer = Gtk2::SourceView::Buffer -> new($table);
isa_ok($buffer, "Gtk2::SourceView::Buffer");

my $manager = Gtk2::SourceView::LanguagesManager -> new();
my $language = $manager -> get_language_from_mime_type("application/x-perl");

$buffer = Gtk2::SourceView::Buffer -> new_with_language($language);
isa_ok($buffer, "Gtk2::SourceView::Buffer");

$buffer -> set_check_brackets(TRUE);
is($buffer -> get_check_brackets(), TRUE);

my $tag_style = Gtk2::SourceView::TagStyle -> new();
$buffer -> set_bracket_match_style($tag_style);

$buffer -> set_highlight(TRUE);
is($buffer -> get_highlight(), TRUE);

$buffer -> set_max_undo_levels(23);
is($buffer -> get_max_undo_levels(), 23);

$buffer -> set_language($language);
is($buffer -> get_language(), $language);

$buffer -> set_escape_char("\\");
is($buffer -> get_escape_char(), "\\");

$buffer -> set_text("die('A horrible death');");

is($buffer -> can_undo(), TRUE);
$buffer -> undo();

is($buffer -> can_redo(), TRUE);
$buffer -> redo();

$buffer -> begin_not_undoable_action();
$buffer -> end_not_undoable_action();

my $start = $buffer -> get_start_iter();
my $end = $buffer -> get_end_iter();

my $marker_one = $buffer -> create_marker("Start", "start", $start);
isa_ok($marker_one, "Gtk2::SourceView::Marker");

my $marker_two = $buffer -> create_marker(undef, undef, $end);
isa_ok($marker_two, "Gtk2::SourceView::Marker");

my $marker_three = $buffer -> create_marker("End", "end", $end);
isa_ok($marker_three, "Gtk2::SourceView::Marker");

$buffer -> move_marker($marker_two, $start);
$buffer -> delete_marker($marker_two);

is($buffer -> get_marker("Start"), $marker_one);

is_deeply([$buffer -> get_markers_in_region($start, $end)],
          [$marker_one, $marker_three]);

is($buffer -> get_first_marker(), $marker_one);
is($buffer -> get_last_marker(), $marker_three);

isa_ok($buffer -> get_iter_at_marker($marker_one), "Gtk2::TextIter");

is($buffer -> get_next_marker($start), $marker_one);
is($buffer -> get_prev_marker($end), $marker_three);
