#
# $Id$
#
# Pretty much complete
#
# TODO:
#	GtkList isn't really tested as it's deprecated, should we test it?
#

#########################
# GtkCombo Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 11;

ok (my $combo = Gtk2::Combo->new, 'Gtk2::Combo->new');

$combo->set_popdown_strings (qw/str1 str2 str3 str4/);

$combo->list->select_item (0);
is ($combo->entry->get_text, 'str1', 
	'$combo->list->select_item|entry->get_text, 1');
$combo->list->select_item (1);
is ($combo->entry->get_text, 'str2', 
	'$combo->list->select_item|entry->get_text, 2');

$combo->set_value_in_list (1, 0);

$combo->set_use_arrows (0);
is ($combo->get ('enable-arrow-keys'), 0, 
	'$combo->use_arrows, false');
$combo->set_use_arrows (1);
is ($combo->get ('enable-arrow-keys'), 1, 
	'$combo->use_arrows, true');

$combo->set_use_arrows_always (0);
is ($combo->get ('enable-arrows-always'), 0, 
	'$combo->use_arrows_always, false');
$combo->set_use_arrows_always (1);
is ($combo->get ('enable-arrows-always'), 1, 
	'$combo->use_arrows_always, true');

$combo->set_case_sensitive (0);
is ($combo->get ('case-sensitive'), 0, '$combo->set_case_sensitive, false');
$combo->set_case_sensitive (1);
is ($combo->get ('case-sensitive'), 1, '$combo->set_case_sensitive, true');

$combo->set_case_sensitive (0);

ok (my $item = Gtk2::ListItem->new_with_label ('test'), 
	'Gtk2::ListItem->new_with_label');
$combo->set_item_string ($item, 'test-text');
$item->select;

$combo->disable_activate;

ok (1, 'all complete');

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
