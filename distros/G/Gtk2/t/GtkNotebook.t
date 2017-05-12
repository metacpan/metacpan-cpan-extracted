#!/usr/bin/env perl

#########################
# GtkNotbook Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 66;

my $win = Gtk2::Window->new;

ok( my $nb = Gtk2::Notebook->new );
$win->add($nb);
ok(1);


# just to make the lines shorter
sub label { Gtk2::Label->new (shift) }

is ($nb->prepend_page (label ('p1c'), label ('p1')), 0);

is ($nb->append_page (label ('p2c'), label ('p2')), 1);

my $child = label ('p1.5c');
is ($nb->insert_page ($child, label ('p1.5'), 1), 1);

is ($nb->prepend_page_menu (label ('Page 1c'), undef, label ('Page 1 pop')), 0);

is ($nb->append_page_menu (label ('Page 6c'), label ('Page 6l'),
			   label ('Page 6 pop')),
    4);;

my $child2 = label ('Page 2c');
is ($nb->insert_page_menu ($child2, label ('Page 2 pop'), undef, 1), 1);

is ($nb->insert_page (label ('remove'), label ('remove'), 7), 6);
is ($nb->insert_page (label ('remove'), label ('remove'), 7), 7);
is ($nb->insert_page (label ('remove'), label ('remove'), 0), 0);

$nb->remove_page(7);
ok(1);
$nb->remove_page(0);
ok(1);
$nb->remove_page(-1);
ok(1);

foreach (qw/left right bottom top/)
{
	$nb->set_tab_pos($_);
	ok(1);

	ok( $nb->get_tab_pos eq $_ );
}

$nb->set_show_tabs(0);
ok(1);
ok( ! $nb->get_show_tabs );

$nb->set_show_tabs(1);
ok(1);
ok( $nb->get_show_tabs );

$nb->set_show_border(0);
ok(1);
ok( ! $nb->get_show_border );

$nb->set_show_border(1);
ok(1);
ok( $nb->get_show_border );

$nb->set_scrollable(1);
ok(1);
ok( $nb->get_scrollable );

$nb->set_scrollable(0);
ok(1);

$nb->popup_disable;
ok(1);

$nb->popup_enable;
ok(1);
ok( ! $nb->get_scrollable );

# in reality this one is only in gtk2.2+, but it's been implemented in
# the xs wrapper since it's trivial anyway
ok( $nb->get_n_pages == 6 );

$nb->set_menu_label($child2, Gtk2::Label->new('re-set'));
ok(1);
ok( $nb->get_menu_label($child2)->get_text eq 're-set');

$nb->set_menu_label_text($child2, 're-set2');
ok(1);
ok( $nb->get_menu_label_text($child2) eq 're-set2');

$nb->set_tab_label($child, Gtk2::Label->new('re-set'));
ok(1);
ok( $nb->get_tab_label($child)->get_text eq 're-set' );

$nb->set_tab_label_text($child, 're-set2');
ok(1);
ok( $nb->get_tab_label_text($child) eq 're-set2' );

ok( $nb->get_nth_page(1)->get_text eq 'Page 2c' );

is_deeply( [ $nb->query_tab_label_packing($child) ],
	   [ FALSE, TRUE, 'start' ] );

$nb->set_tab_label_packing($child, 1, 0, 'end');
ok(1);
is_deeply( [ $nb->query_tab_label_packing($child) ],
	   [ TRUE, FALSE, 'end' ] );

SKIP: {
	skip "2.10 stuff", 3
		unless Gtk2->CHECK_VERSION (2, 10, 0);

	$nb->set_group_id (23);
	is ($nb->get_group_id, 23);

	$nb->set_tab_reorderable ($child, TRUE);
	ok ($nb->get_tab_reorderable ($child));

	$nb->set_tab_detachable ($child, TRUE);
	ok ($nb->get_tab_detachable ($child));
}

SKIP: {
	skip "2.20 stuff", 1
		unless Gtk2->CHECK_VERSION (2, 20, 0);

	my $button=Gtk2::Button->new("click me");
	$nb->set_action_widget($button,'end');
	is ($nb->get_action_widget('end'), $button, '[gs]et_action_widget');
}

SKIP: {
	skip 'new 2.22 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 22, 0);

	ok (defined $nb->get_tab_hborder);
	ok (defined $nb->get_tab_vborder);
}

$win->show_all;
ok(1);
run_main sub {
		$nb->next_page;
		ok(1);
		$nb->prev_page;
		ok(1);
		ok( (my $index = $nb->page_num($child)) == 3 );
		$nb->reorder_child($child, 0);
		ok(1);
		$nb->reorder_child($child, $index);

		ok( $nb->get_current_page == 0 );

		$nb->next_page;
		ok(1);
		ok( $nb->get_current_page == 1 );

		$nb->set_current_page(4);
       		ok(1);
		ok( $nb->get_current_page == 4 );
};

ok(1);

=comment

Here's some interactive code for testing the window creation hook.

my $w = Gtk2::Window->new;
my $nb = Gtk2::Notebook->new;
$nb->append_page (my $c = Gtk2::Label->new ('Test'));
$nb->set_tab_detachable ($c, TRUE);

Gtk2::Notebook->set_window_creation_hook (
  sub {
    my ($notebook, $page, $x, $y, $data) = @_;

    my $new_window = Gtk2::Window->new;
    my $new_notebook = Gtk2::Notebook->new;
    $new_window->add ($new_notebook);
    $new_window->show_all;

    # Either do it manually and return undef, or ...
    #$notebook->remove ($page);
    #$new_notebook->append_page ($page);
    #return undef;

    # ... simply return the new notebook and let gtk+ do the work.
    return $new_notebook;
  });

$w->add ($nb);
$w->signal_connect (destroy => sub { Gtk2->main_quit; });
$w->show_all;
Gtk2->main;

=cut

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
