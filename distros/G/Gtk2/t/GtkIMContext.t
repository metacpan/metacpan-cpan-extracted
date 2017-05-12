#!/usr/bin/perl -w
# vim: set ft=perl :

use Gtk2::TestHelper tests => 9;

my $context = Gtk2::IMContextSimple->new;
isa_ok ($context, 'Gtk2::IMContextSimple');
isa_ok ($context, 'Gtk2::IMContext');
isa_ok ($context, 'Glib::Object');


# unset.
$context->set_client_window (undef);


# something with which to mock up the tests
my $drawing_area = Gtk2::DrawingArea->new;
$drawing_area->set_size_request (200, 200);
$drawing_area->show;
my $window = Gtk2::Window->new;
$window->add ($drawing_area);
$window->show_now;

$context->set_client_window ($drawing_area->window);


my ($str, $attrs, $cursor_pos) = $context->get_preedit_string ();

my $key_event = Gtk2::Gdk::Event->new ('key-press');
$key_event->window ($drawing_area->window);
my $success = $context->filter_keypress ($key_event);

$context->focus_in ();
$context->focus_out ();
$context->reset ();
$context->set_cursor_location (Gtk2::Gdk::Rectangle->new (0, 0, 10, 10));
$context->set_use_preedit (TRUE);
$context->set_use_preedit (FALSE);
$context->set_surrounding ("some text", "3");

$context->signal_connect (retrieve_surrounding => sub {
	ok (1, 'retrieve_surrounding called');
});
my ($text, $cursor_index) = $context->get_surrounding ();
# The actual behavior here is dependent on the input method being used, so
# we can't rely on that for a test.  retrieve_surrounding will have been invoked,
# so that will have to suffice.
#is ($text, 'some text');
#is ($cursor_index, 3);

my $offset = 3;
my $n_chars = 2;
$success = $context->delete_surrounding ($offset, $n_chars);


$context = Gtk2::IMMulticontext->new;
isa_ok ($context, 'Gtk2::IMMulticontext');
isa_ok ($context, 'Gtk2::IMContext');
isa_ok ($context, 'Glib::Object');

$context->append_menuitems (Gtk2::Menu->new);

SKIP: {
	skip '2.16 additions', 2
		unless Gtk2->CHECK_VERSION (2, 16, 0);

	is ($context->get_context_id, undef, 'No default context ID');

	# Get a default context
	$context->focus_in ();
	my $id = $context->get_context_id;
	ok (defined $id, 'Context ID');
	$context->set_context_id ($id);
}
