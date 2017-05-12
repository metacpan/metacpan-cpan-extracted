package Kephra::Document::Change;
our $VERSION = '0.07';

use strict;
use warnings;
#
# changing the current document
#
# set document with a given nr as current document
sub to_nr     { to_number(@_) }
sub to_number {
	my $new_doc = Kephra::Document::Data::validate_doc_nr(shift);
	my $old_doc = Kephra::Document::Data::current_nr();
	if ($new_doc != $old_doc and $new_doc > -1) {
		Kephra::Document::Data::update_attributes($old_doc);
		Kephra::File::save_current() if Kephra::File::_config()->{save}{change_doc};
		Kephra::Document::Data::set_current_nr($new_doc);
		Kephra::Document::Data::set_previous_nr($old_doc);
		Kephra::App::Window::refresh_title();
		Kephra::App::TabBar::raise_tab_by_doc_nr($new_doc);
		Kephra::App::StatusBar::refresh_all_cells();
		Kephra::EventTable::trigger_group( 'doc_change' );
		Kephra::App::EditPanel::gets_focus();
		return 1;
	} else { 
		#print "not changed\n"
	}
	return 0;
}
#sub to_path{} # planing
# change to the previous used document
sub switch_back { to_number( Kephra::Document::Data::previous_nr() ) }
# change to the previous used document
sub tab_left  { Kephra::App::TabBar::raise_tab_left()  }
sub tab_right { Kephra::App::TabBar::raise_tab_right() }
sub move_left { Kephra::App::TabBar::rotate_tab_left() }
sub move_right{ Kephra::App::TabBar::rotate_tab_right()}

1;
