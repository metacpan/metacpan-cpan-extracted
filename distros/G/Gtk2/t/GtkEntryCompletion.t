#
# $Id$
#

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, "GtkEntryCompletion is new in 2.4"],
	tests => 12;

sub match_func {
	my ($completion, $key, $iter, $data) = @_;
	isa_ok ($completion, 'Gtk2::EntryCompletion');
	#isa_ok ($key, 'STRING');
	isa_ok ($iter, 'Gtk2::TreeIter');
	is ($data, 42);
	return TRUE;
}

my $entry = Gtk2::Entry->new;

my $completion = Gtk2::EntryCompletion->new;
isa_ok ($completion, 'Gtk2::EntryCompletion');
ginterfaces_ok($completion);

$entry->set_completion ($completion);

is ($completion->get_entry, $entry);


$completion->set_model (undef);

my $model = Gtk2::ListStore->new ('Glib::String');
$completion->set_model ($model);
is ($completion->get_model, $model);
$completion->set_text_column (0);

$completion->set_match_func (\&match_func, 42);

$completion->set_minimum_key_length (5);
is ($completion->get_minimum_key_length, 5);

$completion->complete;

$completion->insert_action_text (1, 'text string');

$completion->insert_action_markup (2, '<i>markup</i> string');

$entry->set_text ('text s');
$completion->complete;

$completion->delete_action (0);

SKIP: {
	skip 'new 2.6 stuff', 3
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	is ($completion->get_text_column, 0);

	$completion->set_inline_completion (1);
	is ($completion->get_inline_completion, 1);

	$completion->set_popup_completion (1);
	is ($completion->get_popup_completion, 1);

	$completion->insert_prefix;
}

SKIP: {
	skip 'new 2.8 stuff', 2
		unless Gtk2->CHECK_VERSION (2, 8, 0);

	$completion->set_popup_set_width (TRUE);
	is ($completion->get_popup_set_width, TRUE);

	$completion->set_popup_single_match (TRUE);
	is ($completion->get_popup_single_match, TRUE);
}

SKIP: {
	skip 'new 2.12 stuff', 2
		unless Gtk2->CHECK_VERSION (2, 12, 0);

	$completion->set_inline_selection (TRUE);
	is ($completion->get_inline_selection, TRUE);

	is ($completion->get_completion_prefix, undef);
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
