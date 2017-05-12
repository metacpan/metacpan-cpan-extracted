#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 16;

use FindBin;
use lib "$FindBin::Bin";
use my_helper;

use Glib qw(TRUE FALSE);
use Gtk2::SourceView2;

exit tests();


sub tests {
	test_constructor();
	test_properties();
	return 0;
}


sub test_constructor {
	my $mark;
	
	$mark = Gtk2::SourceView2::Mark->new(undef, 'test');
	isa_ok($mark, 'Gtk2::SourceView2::Mark');

	$mark = Gtk2::SourceView2::Mark->new('named', 'test');
	isa_ok($mark, 'Gtk2::SourceView2::Mark');
}


sub test_properties {
	my $mark = Gtk2::SourceView2::Mark->new(undef, 'test');
	is($mark->next(undef), undef, "no next from a mark without buffer");
	is($mark->next('test'), undef, "no next('test') from a mark without buffer");
	is($mark->next('test2'), undef, "no next('test2') from a mark without buffer");
	is($mark->prev(undef), undef, "no prev from a mark without buffer");
	is($mark->prev('test'), undef, "no prev('test') from a mark without buffer");
	is($mark->prev('test2'), undef, "no prev('test2') from a mark without buffer");
	is($mark->get_category, 'test', "get_category");
	
	my $buffer = Gtk2::SourceView2::Buffer->new(undef);
	$buffer->set_text("Jumps over a green sheep");
	my $iter1 = $buffer->get_iter_at_offset(6);
	my $iter2 = $buffer->get_iter_at_offset(12);
	my $iter3 = $buffer->get_iter_at_offset(18);
	my $mark1 = $buffer->create_source_mark('m1', 'word', $iter1);
	my $mark2 = $buffer->create_source_mark('m2', 'mark', $iter2);
	my $mark3 = $buffer->create_source_mark('m3', 'word', $iter3);
	
	is($mark1->get_category, 'word', "get_category");
	is($mark2->get_category, 'mark', "get_category");
	is($mark3->get_category, 'word', "get_category");
	
	is($mark1->next(undef), $mark2, "next(undef)");
	is($mark1->next('word'), $mark3, "next('word')");

	is($mark3->prev(undef), $mark2, "prev(undef)");
	is($mark3->prev('word'), $mark1, "prev('word')");
}

