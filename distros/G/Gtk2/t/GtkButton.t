#
# $Id$
#

#########################
# GtkButton Tests
# 	- rm
#########################

#########################

use Gtk2::TestHelper tests => 40;

ok( my $button = Gtk2::Button->new("Not Yet") );
ok(1);
ok( $button = Gtk2::Button->new_with_label("Not Yet") );
ok(1);
ok( $button = Gtk2::Button->new_with_mnemonic("_Not Yet") );
ok(1);

$button->signal_connect( "clicked" , sub
	{
		if( $_[0]->get_label eq 'Click _Me' )
		{
			$_[0]->set_label("Next");
			ok(1);

			ok( $_[0]->get_label eq 'Next' );
		}
	} );
ok(1);

foreach (qw/normal half none/)
{
	$button->set_relief($_);
	ok(1);

	ok( $button->get_relief eq $_ );
}

$button->set_label('Click _Me');
ok(1);

ok( $button->get_label eq 'Click _Me' );

ok( my $button_stock = Gtk2::Button->new_from_stock('gtk-apply') );

$button_stock->show;
ok(1);

$button_stock->set_use_underline(1);
ok(1);

ok( $button_stock->get_use_underline );

SKIP: {
	skip("[sg]et_focus_on_click and [sg]et_alignment are new in 2.4", 4)
		unless Gtk2->CHECK_VERSION (2, 4, 0);

	$button_stock->set_focus_on_click(0);
	ok(1);

	ok( ! $button_stock->get_focus_on_click() );

	$button_stock->set_alignment(0.7, 0.3);
	ok(1);

	# avoid precision issues, only compare one decimal place.
	is_deeply([map {sprintf '%.1f', $_} $button_stock->get_alignment()],
	          [0.7, 0.3]);
}

ok( my $button3 = Gtk2::Button->new('gtk-quit') );

$button3->signal_connect( "clicked" , sub
	{
		ok(1);
	} );

$button3->set_use_stock(1);
ok(1);

ok( $button3->get_use_stock );

$button->pressed; ok(1);
$button->released; ok(1);
$button->clicked; ok(1);
$button->enter; ok(1);
$button->leave; ok(1);
$button->clicked; ok(1);
$button3->clicked; ok(1);

SKIP: {
	skip("[sg]et_image are new in 2.6", 2)
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	my $widget = Gtk2::Label->new ("Bla");

	$button->set_image ($widget);
	is ($button->get_image, $widget);

	$button->set_image (undef);
	is ($button->get_image, undef);
}

SKIP: {
	skip("[sg]et_image_position are new in 2.10", 1)
		unless Gtk2->CHECK_VERSION (2, 10, 0);

	$button->set_image_position ("left");
	is ($button->get_image_position, "left");
}

SKIP: {
	skip 'new 2.22 stuff', 1
		unless Gtk2->CHECK_VERSION(2, 22, 0);
	my $button = Gtk2::Button->new ('gtk-quit');
	my $window = Gtk2::Window->new;
	$window->add ($button);
	$button->realize;
	isa_ok ($button->get_event_window, 'Gtk2::Gdk::Window');
}

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
