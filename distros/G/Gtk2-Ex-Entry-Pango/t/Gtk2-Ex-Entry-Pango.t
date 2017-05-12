#!/usr/bin/perl

use strict;
use warnings;

use Carp;

use Gtk2::TestHelper tests => 42;

BEGIN {
	use_ok('Gtk2::Ex::Entry::Pango')
};


my $MARKUP_VOID = -1;
my $MAX_INT = 0;


exit main();


sub main {
	test_set_markup();
	test_set_empty_markup();
	test_bad_usage();
	return 0;
}


sub test_set_markup {
	my $entry = Gtk2::Ex::Entry::Pango->new();
	
	# The styles always end at MAX INT and not at the lenght of the string. This
	# code finds the maximum size that a style can have.
	$MAX_INT = get_styles($entry)->[0][1];
	ok($MAX_INT > 0);


	# Intercept all markup changes. $MARKUP_VOID indicates that the callback
	# wasn't called.
	my $markup_signal = $MARKUP_VOID;
	$entry->signal_connect(markup_changed => sub{
		my ($widget, $markup) = @_;
		$markup_signal = $markup;
	});
	
	
	
	# Use some markup	
	$markup_signal = $MARKUP_VOID;
	$entry->set_markup("<b>markup</b>");
	is($entry->get_text(), "markup");
	is($markup_signal, "<b>markup</b>");
	is_deeply(
		get_styles($entry),
		[
			[0, 6, 'bold'],
			[6, $MAX_INT, undef],
		]
	);
	
	
	# Use some markup	with the same text but the styles are different
	$markup_signal = $MARKUP_VOID;
	$entry->set_markup("m<b>a</b>rk<b>u</b>p");
	is($entry->get_text(), "markup");
	is($markup_signal, "m<b>a</b>rk<b>u</b>p");
	is_deeply(
		get_styles($entry),
		[
			[0, 1, undef],
			[1, 2, 'bold'],
			[2, 4, undef],
			[4, 5, 'bold'],
			[5, $MAX_INT, undef],
		]
	);
	
	
	# Try to remove the markup of the same input text.
	# NOTE: this fails as set_text() doesn't detect a text difference.
	$markup_signal = $MARKUP_VOID;
	$entry->set_text("markup");
	is($entry->get_text(), "markup");
	is($markup_signal, $MARKUP_VOID);
	is_deeply(
		get_styles($entry),
		[
			[0, 1, undef],
			[1, 2, 'bold'],
			[2, 4, undef],
			[4, 5, 'bold'],
			[5, $MAX_INT, undef],
		]
	);
	
	
	
	
	# Reset the text
	$markup_signal = $MARKUP_VOID;
	$entry->set_text("reset");
	is($entry->get_text(), "reset");
	is($markup_signal, undef);
	is_deeply(
		get_styles($entry),
		[
			[0, $MAX_INT, undef],
		]
	);
	
	
	# Use some markup	
	$markup_signal = $MARKUP_VOID;
	$entry->set_markup("<b>markup</b>");
	is($entry->get_text(), "markup");
	is($markup_signal, "<b>markup</b>");
	is_deeply(
		get_styles($entry),
		[
			[0, 6, 'bold'],
			[6, $MAX_INT, undef],
		]
	);
	

	# Clear the markup
	$markup_signal = $MARKUP_VOID;
	$entry->clear_markup();
	is($entry->get_text(), "");
	is($markup_signal, undef);
	is_deeply(
		get_styles($entry),
		[
			[0, $MAX_INT, undef],
		]
	);
	
	
	# Test the clear on focus property
	do_clear_on_focus($entry);
}



#
# Testing set_emtpy_markup is tricky because the widget is not realized. This
# means that the 'expose_event' signal is never called. In order to test this
# we need to cheat a little bit and access the private data of the widget.
#
sub test_set_empty_markup {
	my $entry = Gtk2::Ex::Entry::Pango->new();
	
	# The styles always end at MAX INT and not at the lenght of the string. This
	# code finds the maximum size that a style can have.
	$MAX_INT = get_styles($entry)->[0][1];
	ok($MAX_INT > 0);


	# Intercept all markup changes. $MARKUP_VOID indicates that the callback
	# wasn't called.
	my $markup_signal = $MARKUP_VOID;
	$entry->signal_connect(empty_markup_changed => sub{
		my ($widget, $markup) = @_;
		$markup_signal = $markup;
	});
	
	
	# Use some markup	
	$markup_signal = $MARKUP_VOID;
	$entry->set_empty_markup("<b>markup</b>");
	$entry->request_redraw();
	is($entry->get_text(), "");
	is($markup_signal, "<b>markup</b>");
	is_deeply(
		get_styles($entry, $entry->{empty_attributes}),
		[
			[0, 6, 'bold'],
			[6, $MAX_INT, undef],
		]
	);
	
	
	# Use some markup	with the same text but the styles are different
	$markup_signal = $MARKUP_VOID;
	$entry->set_empty_markup("m<b>a</b>rk<b>u</b>p");
	is($entry->get_text(), "");
	is($markup_signal, "m<b>a</b>rk<b>u</b>p");
	is_deeply(
		get_styles($entry, $entry->{empty_attributes}),
		[
			[0, 1, undef],
			[1, 2, 'bold'],
			[2, 4, undef],
			[4, 5, 'bold'],
			[5, $MAX_INT, undef],
		]
	);
	

	# Clear the markup
	$markup_signal = $MARKUP_VOID;
	$entry->clear_empty_markup();
	is($entry->get_text(), "");
	is($markup_signal, undef);
	is($entry->{empty_attributes}, undef);
	
	do_clear_on_focus($entry);
}


#
# Generic tests on the property 'clear_on_focus'
#
sub do_clear_on_focus {
	my ($entry) = @_;
	
	# Test the clear on focus property
	my $count = 0;
	$entry->signal_connect('notify::clear-on-focus' => sub{++$count});

	ok($entry->get_clear_on_focus);
	
	is($count, 0);
	$entry->set_clear_on_focus(FALSE);
	
	is($count, 1);
	ok(!$entry->get_clear_on_focus);
}


sub get_styles {
	my ($widget, $attributes) = @_;

	my @collected = ();
	
	$attributes ||= $widget->get_layout->get_attributes;
	my $iter = $attributes->get_iterator;
	do {
		my ($start, $end) = $iter->range;
		my $attribute = $iter->get('weight');
		$attribute = defined $attribute ? $attribute->value : undef;
		push @collected, [$start, $end, $attribute];
	} while ($iter->next);
	
	return \@collected;
}


#
# Testing that using wrong input will throw an exception.
#
sub test_bad_usage {
	my $entry = Gtk2::Ex::Entry::Pango->new();
	
	test_die(
		sub { $entry->set_markup("Me & You");},
		"set_markup is passed a character not escaped",
	);
	
	test_die(
		sub { $entry->set_markup("4 < 5");},
		"set_markup is passed broken XML",
	);
	
	test_die(
		sub { $entry->set_empty_markup("Me & You");},
		"set_empty_markup is passed a character not escaped",
	);
	
	test_die(
		sub { $entry->set_empty_markup("4 < 5");},
		"set_empty_markup is passed broken XML",
	);
}


sub test_die {
	my ($code, $name) = @_;
	croak "First parameter isn't a code referce (sub)" unless ref $code eq 'CODE';
	
	my $test = 0;
	eval {
		$code->();
		1;
	} or do {
		$test = 1;
	};

	my $tb = Test::More->builder;
	return $tb->ok($test, $name);
}
