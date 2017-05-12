#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 25;

use FindBin;
use lib "$FindBin::Bin";
use my_helper;

use Glib qw(TRUE FALSE);
use Gtk2::SourceView2;

exit tests();


sub tests {
	test_constructors();
	test_properties();
	return 0;
}


sub test_constructors {
	my $buffer;

	$buffer = Gtk2::SourceView2::Buffer->new(undef);
	isa_ok($buffer, 'Gtk2::SourceView2::Buffer');

	my $table = Gtk2::TextTagTable->new();
	$buffer = Gtk2::SourceView2::Buffer->new($table);
	isa_ok($buffer, 'Gtk2::SourceView2::Buffer');

	my $lm = Gtk2::SourceView2::LanguageManager->get_default();
	my $language = $lm->get_language('perl');
	$buffer = Gtk2::SourceView2::Buffer->new_with_language($language);
	isa_ok($buffer, 'Gtk2::SourceView2::Buffer');
}


sub test_properties {
	my $buffer = Gtk2::SourceView2::Buffer->new(undef);
	$buffer->set_text("The lazy grey fox");
	is_buffer_text($buffer, "The lazy grey fox", "text 1");

	is_boolean_ok($buffer, 'highlight_syntax');
	is_boolean_ok($buffer, 'highlight_matching_brackets');

	is_int_ok($buffer, 'max_undo_levels', 40, 60);

	my $language = Gtk2::SourceView2::LanguageManager->get_default->get_language('perl');
	$buffer->set_language($language);
	is($buffer->get_language, $language, "set_language");

	$buffer->set_language(undef);
	is($buffer->get_language, undef, "set_language(undef)");

	my $scheme = Gtk2::SourceView2::StyleSchemeManager->get_default->get_scheme('classic');
	$buffer->set_style_scheme($scheme);
	is($buffer->get_style_scheme, $scheme, "set_style_scheme");

	ok($buffer->can_undo, "can_undo");
	$buffer->undo();
	is_buffer_text($buffer, "", "text undo");

	ok($buffer->can_redo, "can_redo");
	$buffer->redo();
	is_buffer_text($buffer, "The lazy grey fox", "redo");


	# Undoable action
	$buffer->begin_not_undoable_action();
	$buffer->set_text("Jumps over a green sheep");
	$buffer->end_not_undoable_action();
	is_buffer_text($buffer, "Jumps over a green sheep", "undoable action");
	ok(! $buffer->can_undo, "can't undo after an undoable action ");

	# Mark
	my $iter1 = $buffer->get_iter_at_offset(6);
	my $iter2 = $buffer->get_iter_at_offset(12);
	my $iter3 = $buffer->get_iter_at_offset(18);
	my $mark1 = $buffer->create_source_mark('word1', 'marks', $iter1);
	isa_ok($mark1, 'Gtk2::SourceView2::Mark');
	my $mark2 = $buffer->create_source_mark('word2', 'mark2', $iter2);
	my $mark3 = $buffer->create_source_mark(undef, 'mark3', $iter3);


	my $iter = $buffer->get_start_iter;
	is($iter->get_offset, 0, "iter at offset 0");

	# Move forward
	$buffer->forward_iter_to_source_mark($iter, 'mark2');
	is($iter->get_offset, $iter2->get_offset, "iter at offset of iter2");
	$buffer->forward_iter_to_source_mark($iter, undef);
	is($iter->get_offset, $iter3->get_offset, "iter at offset of iter3");

	# Move backward
	$buffer->backward_iter_to_source_mark($iter, 'mark2');
	is($iter->get_offset, $iter2->get_offset, "iter at offset of iter2");
	$buffer->backward_iter_to_source_mark($iter, undef);
	is($iter->get_offset, $iter1->get_offset, "iter at offset of iter1");


	# Get marks at (iter, line)
	my $mark_twice = $buffer->create_source_mark('bugs', 'duplicate', $iter2);
	my @marks = $buffer->get_source_marks_at_iter($iter2, undef);
	is_deeply(
		[ sort @marks ],
		[ sort $mark2, $mark_twice],
		"get_source_marks_at_iter"
	);

	@marks = $buffer->get_source_marks_at_line(0, undef);
	is_deeply(
		[ sort @marks ],
		[ sort $mark1, $mark2, $mark3, $mark_twice ],
		"get_source_marks_at_line"
	);

	$buffer->remove_source_marks($buffer->get_start_iter, $buffer->get_end_iter, undef);
	@marks = $buffer->get_source_marks_at_line(0, undef);
	is_deeply(\@marks, [], "remove_source_marks");

	$buffer->ensure_highlight($buffer->get_start_iter, $buffer->get_end_iter);
}


sub is_buffer_text {
	my ($buffer, $wanted, $message) = @_;
	my $start = $buffer->get_start_iter;
	my $end = $buffer->get_end_iter;
	my $text = $buffer->get_text($start, $end, TRUE);

	my $tester = Test::Builder->new();
	$tester->is_eq($text, $wanted, $message);
}
