#!/usr/bin/perl -w
# vim: set ft=perl :

use strict;
use Gtk2::TestHelper
  tests => 26,
  at_least_version => [2, 10, 0, "GtkAssistant is new in 2.10"];

#typedef gint (*GtkAssistantPageFunc) (gint current_page, gpointer data);

my $assistant = Gtk2::Assistant->new;
isa_ok ($assistant, 'Gtk2::Assistant');
isa_ok ($assistant, 'Gtk2::Window');


isa_ok ($assistant->get_cancel_button (), 'Gtk2::Button');
isa_ok ($assistant->get_forward_button (), 'Gtk2::Button');
isa_ok ($assistant->get_back_button (), 'Gtk2::Button');
isa_ok ($assistant->get_apply_button (), 'Gtk2::Button');
isa_ok ($assistant->get_close_button (), 'Gtk2::Button');
isa_ok ($assistant->get_last_button (), 'Gtk2::Button');


# add some pages...
sub make_a_page {
	my $label = Gtk2::Label->new (shift);
	$label->show;
	return $label;
}

is ($assistant->append_page (make_a_page ("appended")), 0);
is ($assistant->prepend_page (make_a_page ("prepended")), 0);
is ($assistant->insert_page (make_a_page ("inserted first"), 0), 0);
is ($assistant->insert_page (make_a_page ("inserted at 2"), 2), 2);
is ($assistant->insert_page (make_a_page ("inserted last"), -1), 4);
is ($assistant->get_n_pages, 5);

is ($assistant->get_current_page (), -1, "none set yet");
$assistant->set_current_page (3);
is ($assistant->get_current_page (), 3);

my $page = $assistant->get_nth_page (2);
isa_ok ($page, 'Gtk2::Widget');

$assistant->set_page_title ($page, "a title");
is ($assistant->get_page_title ($page), "a title");

$assistant->set_page_type ($page, "content");
is ($assistant->get_page_type ($page), "content");

ok (!$assistant->get_page_complete ($page));
$assistant->set_page_complete ($page, TRUE);
ok ($assistant->get_page_complete ($page));

my $header_image = Gtk2::Gdk::Pixbuf->new ('rgb', FALSE, 8, 45, 20);
my $side_image = Gtk2::Gdk::Pixbuf->new ('rgb', FALSE, 8, 20, 45);

ok (!$assistant->get_page_header_image ($page));
$assistant->set_page_header_image ($page, $header_image);
is ($assistant->get_page_header_image ($page), $header_image);

ok (!$assistant->get_page_side_image ($page));
$assistant->set_page_side_image ($page, $side_image);
is ($assistant->get_page_side_image ($page), $side_image);

my $button = Gtk2::Button->new ("extra");
$assistant->add_action_widget ($button);
$assistant->remove_action_widget ($button);

$assistant->update_buttons_state ();

$assistant->set_forward_page_func (\&page_func);

sub page_func {
	ok (1);
}

SKIP: {
	skip 'new 2.22 stuff', 0
		unless Gtk2->CHECK_VERSION(2, 22, 0);
	my $assistant = Gtk2::Assistant->new;
	$assistant->commit;
}
