#!/usr/bin/perl -w
# vim: set ft=perl :
use Gtk2::TestHelper tests => 115,
	at_least_version => [2, 2, 0, "GtkClipboard didn't exist in 2.0.x"];

# $Id$

my $clipboard;

SKIP: {
	skip "GdkDisplay is new in 2.2", 1
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	my $display = Gtk2::Gdk::Display->get_default;

	$clipboard = Gtk2::Clipboard->get_for_display (
		$display,
		Gtk2::Gdk->SELECTION_CLIPBOARD);

	isa_ok ($clipboard, 'Gtk2::Clipboard');
	is ($clipboard->get_display, $display);
}

$clipboard = Gtk2::Clipboard->get (Gtk2::Gdk->SELECTION_PRIMARY);
isa_ok ($clipboard, 'Gtk2::Clipboard');

my $expect = '0123456789abcdef';

$clipboard->set_text ($expect);

my $text = $clipboard->wait_for_text;
is ($text, $expect);

is ($clipboard->wait_is_text_available, 1);

$clipboard->request_text (sub {
	# print "hello from the callback\n" . Dumper(\@_);
	is ($_[0], $clipboard);
	is ($_[1], $expect);
	is ($_[2], 'user data!');
}, 'user data!');

$clipboard->request_contents (Gtk2::Gdk->SELECTION_TYPE_STRING, sub {
	#print "hello from the callback\n" . Dumper(\@_);
	is ($_[0], $clipboard);
	isa_ok ($_[1], 'Gtk2::SelectionData');
	is ($_[2], 'user data!');
	is ($_[1]->get_text, $expect);
}, 'user data!');


SKIP: {
	skip 'request_targets and wait_for_targets are new in 2.4', 4
		unless Gtk2->CHECK_VERSION (2, 4, 0);

	$clipboard->request_targets (sub {
		is ($_[0], $clipboard);
		isa_ok ($_[1], "ARRAY");
		isa_ok ($_[1][0], "Gtk2::Gdk::Atom");
		is ($_[2], "bla");
	}, "bla");
}

SKIP: {
	skip 'new/now-working targets stuff', 2
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	is ($clipboard->wait_is_target_available (Gtk2::Gdk::Atom->intern ('TEXT')), TRUE);
	isa_ok (($clipboard->wait_for_targets)[0], 'Gtk2::Gdk::Atom');
}

SKIP: {
	skip "new image stuff", 5
		# Some of this was broken in 2.6.0
		unless Gtk2->CHECK_VERSION (2, 6, 1);

	my $pixbuf = Gtk2::Gdk::Pixbuf->new ("rgb", FALSE, 8, 23, 42);
	$clipboard->set_image ($pixbuf);

	is ($clipboard->wait_is_image_available, TRUE);

	isa_ok ($clipboard->wait_for_image, "Gtk2::Gdk::Pixbuf");
	$clipboard->request_image (sub {
		is ($_[0], $clipboard);
		isa_ok ($_[1], "Gtk2::Gdk::Pixbuf");
		is ($_[2], "bla");
	}, "bla");
}

SKIP: {
        skip "new stuff in 2.10", 7
                unless Gtk2->CHECK_VERSION (2, 10, 0);

	my $test_text = 'test test test';

	my $buffer = Gtk2::TextBuffer->new;
	$buffer->insert ($buffer->get_start_iter, 'bla!');
	$buffer->register_deserialize_format (
		'text/rdf',
		sub { warn "here"; $_[1]->insert ($_[2], 'bla!'); });

	$clipboard->set_with_data (
		sub {
			my ($clipboard, $selection_data, $info, $data) = @_;
			$selection_data->set (Gtk2::Gdk::Atom->new ('text/rdf'),
					      8, $data);
		},
		sub {},
		$test_text,
		{target=>'text/rdf'});

	$clipboard->request_rich_text ($buffer, sub {
		# print "hello from the callback\n" . Dumper(\@_);
		is ($_[0], $clipboard);
		is ($_[1]->name, 'text/rdf');
		is ($_[2], $test_text);
		is ($_[3], undef);
	});

	ok ($clipboard->wait_is_rich_text_available ($buffer));

	my ($data, $atom) = $clipboard->wait_for_rich_text ($buffer);
	is ($data, $test_text);
	is ($atom->name, 'text/rdf');
}

SKIP: {
	skip 'new uris stuff', 5
		unless Gtk2->CHECK_VERSION (2, 14, 0);

	my @uris = ('file:///foo/bar', 'file:///bar/foo');
	$clipboard->set_with_data (
		sub {
			my ($clipboard, $selection_data, $info, $data) = @_;
			$selection_data->set_uris (@$data);
		},
		sub {},
		\@uris,
		{target=>'text/uri-list'});

	is ($clipboard->wait_is_uris_available, TRUE);

	is_deeply ($clipboard->wait_for_uris, \@uris);
	$clipboard->request_uris (sub {
		my ($tmp_clipboard, $tmp_uris, $data) = @_;
		is ($tmp_clipboard, $clipboard);
		is_deeply ($tmp_uris, \@uris);
		is ($data, undef);
	});
}

run_main;

#print "----------------------------------\n";

$expect = 'whee';

my $get_func_call_count = 0;
sub get_func {
	return if ++$get_func_call_count == 3;

	my ($cb, $sd, $info, $user_data_or_owner) = @_;

	is ($cb, $clipboard);
	isa_ok ($sd, 'Gtk2::SelectionData');
	is ($info, 0);
	ok (defined $user_data_or_owner);

	# Tests for Gtk2::SelectionData:

	$sd->set (Gtk2::Gdk->TARGET_STRING, 8, 'bla blub');

	is ($sd->get_selection ()->name, 'PRIMARY');
	ok (defined $sd->get_target ()->name);
	is ($sd->get_data_type ()->name, 'STRING');
	is ($sd->get_format (), 8);
	is ($sd->get_data (), 'bla blub');
	is ($sd->get_length (), 8);

	# Deprecated but provided for backwards compatibility
	ok ($sd->selection () == $sd->get_selection ());
	ok ($sd->target () == $sd->get_target ());
	ok ($sd->type () == $sd->get_data_type ());
	ok ($sd->format () == $sd->get_format ());
	ok ($sd->data () eq $sd->get_data ());
	ok ($sd->length () == $sd->get_length ());

	SKIP: {
		skip 'GdkDisplay is new in 2.2', 2
			unless Gtk2->CHECK_VERSION (2, 2, 0);

		isa_ok ($sd->get_display (), 'Gtk2::Gdk::Display');

		# Deprecated but provided for backwards compatibility
		ok ($sd->display () == $sd->get_display ());
	}

	# FIXME: always empty and false?
	# warn $sd->get_targets;
	# warn $sd->targets_include_text;

	$sd->set_text ($expect);
	is ($sd->get_text, $expect);

	is ($sd->data, $expect);
	is ($sd->length, length ($expect));

	SKIP: {
		skip '2.6 stuff', 7
			unless Gtk2->CHECK_VERSION (2, 6, 0);

		# This won't work with a STRING selection, but I don't know
		# what else to use, so we just check that both operations fail.
		my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', FALSE, 8, 23, 42);
		is ($sd->set_pixbuf ($pixbuf), FALSE);
		is ($sd->get_pixbuf, undef);

		# Same here.
		is ($sd->set_uris, FALSE);
		is_deeply ([$sd->get_uris], []);
		is ($sd->set_uris (qw(a b c)), FALSE);
		is_deeply ([$sd->get_uris], []);

		is ($sd->targets_include_image (TRUE), FALSE);
	}

	SKIP: {
		skip '2.10 stuff', 2
			unless Gtk2->CHECK_VERSION (2, 10, 0);

		is ($sd->targets_include_uri, FALSE);

		my $buffer = Gtk2::TextBuffer->new;
		$buffer->register_deserialize_format (
			'text/rdf',
			sub { warn "here"; $sd->insert ($info, 'bla!'); });
		is ($sd->targets_include_rich_text ($buffer), FALSE);
	}
}

sub clear_func {
	is (shift, $clipboard);
	ok (shift);
}

sub received_func {
	is ($_[0], $clipboard);
	isa_ok ($_[1], 'Gtk2::SelectionData');
	is ($_[2], 'user data!');

	is ($_[1]->get_text, $expect);
}

# set the selection multiple times to make sure we don't crash on 
# replacing all the GPerlCallbacks.

$clipboard->set_with_data (\&get_func, \&clear_func, 'user data, yo',
	{target=>'TEXT'}, {target=>'STRING'}, {target=>'COMPOUND_TEXT'},
);

ok(1);

$clipboard->set_with_data (\&get_func, \&clear_func, 'user data, yo',
	{target=>'TEXT'}, {target=>'STRING'}, {target=>'COMPOUND_TEXT'},
);

ok(1);

$clipboard->set_with_data (\&get_func, \&clear_func, 'user data, yo',
	{target=>'TEXT'}, {target=>'STRING'}, {target=>'COMPOUND_TEXT'},
);

ok(1);

$clipboard->request_contents (Gtk2::Gdk->SELECTION_TYPE_STRING,
			      \&received_func, 'user data!');
run_main;

my $widget = Gtk2::Window->new;
$clipboard->set_with_owner (\&get_func, \&clear_func, $widget,
	{target=>'TEXT'}, {target=>'STRING'}, {target=>'COMPOUND_TEXT'},
);

is ($clipboard->get_owner, $widget);

$clipboard->request_contents (Gtk2::Gdk->SELECTION_TYPE_STRING,
                              \&received_func, 'user data!');
run_main;

SKIP: {
	skip "new 2.6 stuff", 0
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	$clipboard->set_can_store ({target=>'STRING'}, {target=>'TEXT'});
        $clipboard->set_can_store;

        $clipboard->store;
}

$clipboard->clear;

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
