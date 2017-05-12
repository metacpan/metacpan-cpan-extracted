#
# $Id$
#

use Gtk2::TestHelper tests => 52;

use strict;
use warnings;

#
# the new 2.4 API and the pre-2.4 API cannot be used on the same widget,
# so we create completely separate toolbars for the two APIs.
#

SKIP: {
	skip "new and improved 2.4 toolbar API", 21
		unless Gtk2->CHECK_VERSION (2, 4, 0);

	my $toolbar = Gtk2::Toolbar->new;
	isa_ok ($toolbar, 'Gtk2::Toolbar');

	my @toolitems = map { Gtk2::ToolButton->new (undef, "$_") } 0..9;

	foreach (@toolitems) {
		$toolbar->insert ($_, -1);
	}

	is ($toolbar->get_n_items, scalar(@toolitems));
	is ($toolbar->get_item_index ($toolitems[4]), 4);

	is ($toolbar->get_nth_item (-1), undef, "get_nth_item -1");
	for (0..12) {
		is ($toolbar->get_nth_item ($_), $toolitems[$_],
		    "get_nth_item $_");
	}

	$toolbar->set_show_arrow (FALSE);
	ok (!$toolbar->get_show_arrow);

	$toolbar->set_show_arrow (TRUE);
	ok ($toolbar->get_show_arrow);


	my $reliefstyle = $toolbar->get_relief_style;
	ok (defined $reliefstyle);

	# this assumes that 0,0 will get the first item in the toolbar.
	# i hope that this isn't subject to theme borders and the like.
	is (0, $toolbar->get_drop_index (0, 0));

	# can't use an item with a parent...
	$toolbar->set_drop_highlight_item (Gtk2::ToolButton->new (undef, ''), 3);
	# turn off the highlighting
	$toolbar->set_drop_highlight_item (undef, 0);
}


#
# just about everything from here to the end is deprecated as of 2.4.0,
# but will not be disabled because it wasn't deprecated in 2.0.x and 2.2.x.
#

my $toolbar = Gtk2::Toolbar->new;

my $widget;

     # text tooltip private     icon           callback  data
for ([   '',    '',      '', 'Gtk2::Image', sub {1},    [] ],
     [   '', undef,   undef,         undef ],  # test default params
     )
{
	my $icontype = $_->[3];

	$_->[3] = new $icontype if defined $icontype;
	$widget = $toolbar->append_item (@$_);
	isa_ok ($widget, 'Gtk2::Widget');

	$_->[3] = new $icontype if defined $icontype;
	$widget = $toolbar->prepend_item (@$_);
	isa_ok ($widget, 'Gtk2::Widget');

	$_->[3] = new $icontype if defined $icontype;
	$widget = $toolbar->insert_item ($_->[0], # text
					 $_->[1], # tooltip_text
					 $_->[2], # tooltip_private_text
					 $_->[3], # icon
					 $_->[4], # callback
					 $_->[5], # user_data
					 1); # position
	isa_ok ($widget, 'Gtk2::Widget');

	$widget = $toolbar->insert_stock ('gtk-open', # stock-id
					  $_->[1], # tooltip_text
					  $_->[2], # tooltip_private_text
					  $_->[4], # callback
					  $_->[5], # user_data
					  2); # position
	isa_ok ($widget, 'Gtk2::Widget');
}


#
# this is highly obnoxious, but we need to test prepend, insert, and append
# with multiple sets of arguments to ensure that we get the marshaling right.
# unfortunately, there's not really any good way to loop this, so the code
# is quite repetitive.  (and wide.)
#

# GtkToolbarChildType
#   space        a space in the style of the toolbar's GtkToolbarSpaceStyle.
#   button       a GtkButton.
#   togglebutton a GtkToggleButton.
#   radiobutton  a GtkRadioButton.
#   widget       a standard GtkWidget.

#
#$widget = $toolbar->prepend_element (type, widget, text, tooltip_text, tooltip_private_text, icon, callback=NULL, user_data=NULL)
#
$widget = $toolbar->prepend_element ('space', undef, undef, undef, undef, undef);
is ($widget, undef, 'prepend_element with a space');

$widget = $toolbar->prepend_element ('button', undef, '', undef, undef, undef, sub {1});
isa_ok ($widget, 'Gtk2::Widget', 'prepend_element with a button and a callback');

$widget = $toolbar->prepend_element ('togglebutton', undef, '', undef, undef, undef);
isa_ok ($widget, 'Gtk2::Widget', 'prepend_element with a togglebutton');

$widget = $toolbar->prepend_element ('radiobutton', undef, '', undef, undef, undef);
isa_ok ($widget, 'Gtk2::Widget', 'prepend_element with a radiobutton');

# with radiobutton, the widget is used to determine the group.
$widget = $toolbar->prepend_element ('radiobutton', $widget, '', undef, undef, undef);
isa_ok ($widget, 'Gtk2::Widget', 'prepend_element with a radiobutton');

my $entry = Gtk2::Entry->new;
$widget = $toolbar->prepend_element ('widget', $entry, undef, undef, undef, undef);
is ($widget, $entry, 'prepend_element with a widget');


#
#$widget = $toolbar->insert_element (type, widget, text, tooltip_text, tooltip_private_text, icon, callback, user_data, position)
#
$widget = $toolbar->insert_element ('space', undef, undef, undef, undef, undef, undef, undef, -1);
is ($widget, undef, 'insert_element with a space');

$widget = $toolbar->insert_element ('button', undef, '', undef, undef, undef, sub {1}, undef, 0);
isa_ok ($widget, 'Gtk2::Widget', 'insert_element with a button and a callback');

$widget = $toolbar->insert_element ('togglebutton', undef, '', undef, undef, undef, undef, undef, 1);
isa_ok ($widget, 'Gtk2::Widget', 'insert_element with a togglebutton');

$widget = $toolbar->insert_element ('radiobutton', undef, '', undef, undef, undef, undef, undef, 2);
isa_ok ($widget, 'Gtk2::Widget', 'insert_element with a radiobutton');

# with radiobutton, the widget is used to determine the group.
$widget = $toolbar->insert_element ('radiobutton', $widget, '', undef, undef, undef, undef, undef, 3);
isa_ok ($widget, 'Gtk2::Widget', 'insert_element with a radiobutton');

$entry = Gtk2::Entry->new;
$widget = $toolbar->insert_element ('widget', $entry, undef, undef, undef, undef, undef, undef, 4);
is ($widget, $entry, 'insert_element with a widget');


#
#$widget = $toolbar->append_element (type, widget, text, tooltip_text, tooltip_private_text, icon, callback=NULL, user_data=NULL)
#
$widget = $toolbar->append_element ('space', undef, undef, undef, undef, undef);
is ($widget, undef, 'append_element with a space');

$widget = $toolbar->append_element ('button', undef, '', undef, undef, undef, sub {1});
isa_ok ($widget, 'Gtk2::Widget', 'append_element with a button and a callback');

$widget = $toolbar->append_element ('togglebutton', undef, '', undef, undef, undef);
isa_ok ($widget, 'Gtk2::Widget', 'append_element with a togglebutton');

$widget = $toolbar->append_element ('radiobutton', undef, '', undef, undef, undef);
isa_ok ($widget, 'Gtk2::Widget', 'append_element with a radiobutton');

# with radiobutton, the widget is used to determine the group.
$widget = $toolbar->append_element ('radiobutton', $widget, '', undef, undef, undef);
isa_ok ($widget, 'Gtk2::Widget', 'append_element with a radiobutton');

$entry = Gtk2::Entry->new;
$widget = $toolbar->append_element ('widget', $entry, undef, undef, undef, undef);
is ($widget, $entry, 'append_element with a widget');




$toolbar->prepend_widget (Gtk2::Image->new, 'tooltip', 'tooltip_private');
$toolbar->prepend_widget (Gtk2::Image->new, undef, undef);

$toolbar->insert_widget (Gtk2::Image->new, 'tooltip', 'tooltip_private', -1);
$toolbar->insert_widget (Gtk2::Image->new, undef, undef, 1);

$toolbar->append_widget (Gtk2::Image->new, 'tooltip', 'tooltip_private');
$toolbar->append_widget (Gtk2::Image->new, undef, undef);




$toolbar->prepend_space;
$toolbar->remove_space (0);
$toolbar->insert_space (-1);
$toolbar->insert_space (1);
$toolbar->append_space;


# GtkToolbarStyle
#  GTK_TOOLBAR_ICONS
#  GTK_TOOLBAR_TEXT
#  GTK_TOOLBAR_BOTH
#  GTK_TOOLBAR_BOTH_HORIZ

$toolbar->set_style ('icons');
is ('icons', $toolbar->get_style, '[sg]et_style');
$toolbar->set_style ('both');
is ('both', $toolbar->get_style, '[sg]et_style');
$toolbar->unset_style;

$toolbar->set_icon_size ('small-toolbar');
is ('small-toolbar', $toolbar->get_icon_size, '[sg]et_icon_size');
$toolbar->unset_icon_size;

$toolbar->set_tooltips (TRUE);
ok ($toolbar->get_tooltips, '[sg]et_tooltips');

$toolbar->set_orientation ('vertical');
is ('vertical', $toolbar->get_orientation, '[sg]et_orientation');


__END__

Copyright (C) 2003-2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
