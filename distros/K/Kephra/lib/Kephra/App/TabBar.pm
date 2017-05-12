package Kephra::App::TabBar;
our $VERSION = '0.18';

use strict;
use warnings;

# internal data
my $notebook;
sub _ref    { $notebook = ref $_[0] eq 'Wx::AuiNotebook' ? $_[0] : $notebook }
sub _config { my $cfg = Kephra::API::settings(); $cfg->{app}{tabbar} if keys %$cfg }

my @doc2tab_pos; # tab index numbers in doc order
my @tab2doc_pos; # doc numbers in tab index order
my @doc2vis_pos; # visible tab pos number in doc order
my @vis2doc_pos; # doc numbers in visible tab order
sub _update_doc_pos  {
	@doc2tab_pos = ();
	@doc2vis_pos = ();
	$doc2tab_pos[ $tab2doc_pos[$_] ] = $_ for 0 .. $#tab2doc_pos;
	$doc2vis_pos[ $vis2doc_pos[$_] ] = $_ for 0 .. $#vis2doc_pos;
}
sub _validate_doc_nr { &Kephra::Document::Data::validate_doc_nr }
sub _doc2tab_pos {
	my $nr = _validate_doc_nr(shift);
	return $nr == -1 ? -1 : $doc2tab_pos[$nr];
}
sub _tab2doc_pos {
	my $nr = _validate_doc_nr(shift);
	return $nr == -1 ? -1 : $tab2doc_pos[$nr];
}
sub _vis2doc_pos {
	my $nr = _validate_doc_nr(shift);
	return $nr == -1 ? -1 : $vis2doc_pos[$nr];
}
sub _doc2vis_pos {
	my $nr = _validate_doc_nr(shift);
	return $nr == -1 ? -1 : $doc2vis_pos[$nr];
}
sub _move_vis_pos {
	my $from = _validate_doc_nr(shift);
	my $to = _validate_doc_nr(shift);
	return if $from == -1 or $to == -1;
	my $doc_nr = splice @vis2doc_pos, $from, 1;
	splice @vis2doc_pos, $to, 0, $doc_nr;
	_update_doc_pos();
#print "vis_order: @vis2doc_pos, tab_order: @tab2doc_pos\n";
#print $notebook->GetPageIndex( Kephra::Document::Data::_ep($_) )."\n" for @{Kephra::Document::Data::all_nr()};
}
sub _move_tab_pos {
	my $from = _validate_doc_nr(shift);
	my $to = _validate_doc_nr(shift);
	return if $from == -1 or $to == -1;
	my $doc_nr = splice @tab2doc_pos, $from, 1;
	splice @tab2doc_pos, $to, 0, $doc_nr;
	_update_doc_pos(); #print "taborder: @tab2doc_pos, doc_order: @doc_order\n";
#print $notebook->GetPageIndex( Kephra::Document::Data::_ep($_) )."\n" for @{Kephra::Document::Data::all_nr()};
}
sub _remove_tab {
	my $tab_nr = _validate_doc_nr(shift);
	return if $tab_nr == -1;
	my $doc_nr = $tab2doc_pos[$tab_nr];
	my $vis_nr = $doc2vis_pos[$doc_nr];
	splice @tab2doc_pos, $tab_nr, 1;
	splice @vis2doc_pos, $vis_nr, 1;
	for (0 .. $#tab2doc_pos) {$tab2doc_pos[$_]-- if $tab2doc_pos[$_] > $doc_nr}
	for (0 .. $#vis2doc_pos) {$vis2doc_pos[$_]-- if $vis2doc_pos[$_] > $doc_nr}
	_update_doc_pos();
#print "vis_order: @vis2doc_pos, tab_order: @tab2doc_pos\n";
}
#
# basic toolbar creation
#
sub create {
	# create notebook if there is none
	my $notebook = _ref();
	$notebook->Destroy if defined $notebook;
	$notebook = Wx::AuiNotebook->new
		(Kephra::App::Window::_ref(),-1, [0,0], [-1,23],
		&Wx::wxAUI_NB_TOP | &Wx::wxAUI_NB_SCROLL_BUTTONS);
	_ref($notebook);
	#Wx::Event::EVT_LEFT_UP( $notebook, sub {
		#my ($tabs, $event) = @_; print "\n left up\n";
		#Kephra::Document::Data::set_value('b4tabchange', $tabs->GetSelection);
		#$event->Skip;
	#});
	#Wx::Event::EVT_LEFT_DOWN( $notebook, sub {
		#my ($tabs, $event) = @_; print "\n left down\n";
		#Kephra::Document::Change::switch_back()
			#if Kephra::Document::Data::get_value('b4tabchange')==$tabs->GetSelection;
		#$event->Skip;
	#});
	my $begin_drag_index;
	Wx::Event::EVT_AUINOTEBOOK_BEGIN_DRAG($notebook, -1, sub {
		$begin_drag_index = $_[1]->GetSelection;
	});	
	Wx::Event::EVT_AUINOTEBOOK_END_DRAG($notebook, -1, sub {
		_move_vis_pos($begin_drag_index, $_[1]->GetSelection);
		#rotate_tab($_[1]->GetSelection - $begin_drag_index);
		Kephra::App::EditPanel::gets_focus();
		Kephra::EventTable::trigger('document.list');
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED( $notebook, -1, sub {
		my ( $bar, $event ) = @_;
		my $new_nr = _tab2doc_pos( $event->GetSelection );
		my $old_nr = _tab2doc_pos( $event->GetOldSelection );
#print "=begin change ".$event->GetSelection." page ; docs: $old_nr -> $new_nr\n";
		#print "=end change page $nr\n";
		Kephra::Document::Change::to_number( $new_nr, $old_nr);
		Kephra::App::EditPanel::gets_focus();
		$event->Skip;
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE( $notebook, -1, sub {
		my ( $bar, $event ) = @_;
		Kephra::File::close_nr( _tab2doc_pos($event->GetSelection) );
		$event->Veto;
	});
}

sub apply_settings {
	my $notebook = _ref();
	# Optional middle click over the tabs
	if ( _config()->{middle_click} ) {
		Wx::Event::EVT_MIDDLE_UP(
			$notebook,
			Kephra::CommandList::get_cmd_property( _config()->{middle_click},'call')
		);
	}
	my $style = $notebook->GetWindowStyleFlag();
	$style |= &Wx::wxAUI_NB_TAB_MOVE if _config->{movable_tabs};
	$style |= &Wx::wxAUI_NB_WINDOWLIST_BUTTON if _config->{tablist_button};
	if    (_config->{close_button} =~ /all/){ $style |= &Wx::wxAUI_NB_CLOSE_ON_ALL_TABS}
	elsif (_config->{close_button} =~ /one/){ $style |= &Wx::wxAUI_NB_CLOSE_BUTTON}
	elsif (_config->{close_button} =~ /current/){$style |= &Wx::wxAUI_NB_CLOSE_ON_ACTIVE_TAB}
	elsif (_config->{close_button} =~ /active/) {$style |= &Wx::wxAUI_NB_CLOSE_ON_ACTIVE_TAB}
	# wxAUI_NB_TAB_SPLIT wxAUI_NB_TAB_EXTERNAL_MOVE
	$notebook->SetWindowStyle( $style );
	show();
}
#
# tab functions
#
sub add_edit_tab  {
	my $current_nr = Kephra::Document::Data::current_nr();
	my $doc_nr = shift || $current_nr;
	my $config = _config();
	my $mode = (ref $config and defined $config->{insert_new_tab})
		? $config->{insert_new_tab}
		: 'rightmost';
	my $vis_pos;
	$vis_pos = 0             if $mode eq 'leftmost';
	$vis_pos = $current_nr   if $mode eq 'left';
	$vis_pos = $current_nr+1 if $mode eq 'right';
	$vis_pos = $doc_nr       if $mode eq 'rightmost';
	my $stc = Kephra::App::EditPanel::new();
	Kephra::Document::Data::set_attribute('ep_ref', $stc, $doc_nr);
	#my $panel = Wx::Panel->new( $notebook, -1);
	#$stc->Reparent($panel);
	#my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
	#$sizer->Add( $stc, 1, &Wx::wxGROW, 0);
	#$panel->SetSizer($sizer);
	#$panel->SetAutoLayout(1);
	#$notebook->Freeze(); #$notebook->Thaw();
	my $notebook = _ref();
	#$notebook->InsertPage( $vis_pos, $stc, '', 0 );
	$notebook->AddPage( $stc, '', 0 );
	$notebook->Layout();
	$stc->Layout();
	splice @tab2doc_pos, $doc_nr, 0, $doc_nr; # splice @tab2doc_pos, $vis_pos, 0, $doc_nr;
	splice @vis2doc_pos, $doc_nr, 0, $doc_nr; # splice @vis2doc_pos, $vis_pos, 0, $doc_nr;
	_update_doc_pos();
	return $stc;
}

sub add_panel_tab {
	my $doc_nr = shift || Kephra::Document::Data::current_nr();
	my $panel = shift;
	return unless defined $panel and substr(ref $panel, 0, 4) eq 'Wx::';
	$panel->Reparent($notebook);
	$notebook->InsertPage($panel, '', 0 ); # attention no $pos yet
	return $panel;
}

sub raise_tab_by_doc_nr { raise_tab_by_tab_nr( _doc2tab_pos(shift) ) }
sub raise_tab_by_vis_nr { raise_tab_by_tab_nr( _doc2tab_pos( _vis2doc_pos(shift)))}
sub raise_tab_by_tab_nr {
	my $nr = shift;
	$notebook->SetSelection($nr) unless $nr == $notebook->GetSelection;
}
sub raise_tab_left  {
	my $vis_nr = _doc2vis_pos( Kephra::Document::Data::current_nr() );
	raise_tab_by_vis_nr( Kephra::Document::Data::next_nr(-1, $vis_nr) );
}
sub raise_tab_right {
	my $vis_nr = _doc2vis_pos( Kephra::Document::Data::current_nr() );
	raise_tab_by_vis_nr( Kephra::Document::Data::next_nr(1, $vis_nr) );
}
sub rotate_tab_left { rotate_tab(-1) }
sub rotate_tab_right{ rotate_tab( 1) }
sub rotate_tab {
	return unless _config()->{movable_tabs};
	my $rot_step = shift;
	my $doc_nr = Kephra::Document::Data::current_nr();
	my $old_tab_pos = _doc2tab_pos( $doc_nr );
	my $old_vis_pos = _doc2vis_pos( $doc_nr );
	my $new_vis_pos = Kephra::Document::Data::next_nr($rot_step, $old_vis_pos);
	my $notebook = _ref();
	my $label = $notebook->GetPageText( $old_tab_pos );
	my $stc = Kephra::Document::Data::_ep($doc_nr);
	$notebook->RemovePage( $old_tab_pos );
	$notebook->InsertPage( $new_vis_pos, $stc, $label, 0 );
	_move_tab_pos( $old_tab_pos, $new_vis_pos );
	_move_vis_pos( $old_vis_pos, $new_vis_pos );
	raise_tab_by_vis_nr($new_vis_pos);
	Kephra::EventTable::trigger('document.list');
}

sub delete_tab_by_doc_nr { delete_tab_by_tab_nr( _doc2tab_pos(shift) ) }
sub delete_tab_by_tab_nr { 
	my $tab_nr = shift;
	my $doc_nr = _tab2doc_pos($tab_nr);
	my $notebook = _ref();
#print "delete tab $tab_nr \n";
	my $stc = Kephra::Document::Data::_ep($doc_nr);
#print $notebook->GetSelection."current, del tab nr $nr\n";
	_remove_tab($tab_nr);
	$notebook->RemovePage($tab_nr); # DeletePage,RemovePage
	$stc->Destroy(); # $xw->Reparent( undef );
}
#
# refresh the label of given number
#
sub refresh_label {
	my $doc_nr = shift;
	$doc_nr = Kephra::Document::Data::current_nr() unless defined $doc_nr;
	return unless _validate_doc_nr($doc_nr) > -1;

	my $config   = _config();
	my $untitled = Kephra::Config::Localisation::strings()->{app}{general}{untitled};
	my $label    = Kephra::Document::Data::get_attribute
					( $config->{file_info}, $doc_nr ) || "<$untitled>";

	# shorten too long filenames
	my $max_width = $config->{max_tab_width};
	if ( length($label) > $max_width and $max_width > 7 ) {
		$label = substr( $label, 0, $max_width - 3 ) . '...';
	}
	# set config files in square brackets
	if (    $config->{mark_configs}
		and Kephra::Document::Data::get_attribute('config_file', $doc_nr)
		and Kephra::API::settings()->{file}{save}{reload_config}              ) {
		$label = '$ ' . $label;
	}
	$label = ( $doc_nr + 1 ) . ' ' . $label if $config->{number_tabs};
	Kephra::Document::Data::set_attribute('label', $label);
	if ( $config->{info_symbol} ) {
		$label .= ' #' if Kephra::Document::Data::get_attribute('editable');
		$label .= ' *' if Kephra::Document::Data::get_attribute('modified');
	}
	$notebook->SetPageText( _doc2tab_pos($doc_nr), $label );
}

sub refresh_current_label { refresh_label(Kephra::Document::Data::current_nr()) }
sub refresh_all_label {
	if ( Kephra::Document::Data::get_value('loaded') ) {
		refresh_label($_) for @{ Kephra::Document::Data::all_nr() };
		raise_tab_by_doc_nr( Kephra::Document::Data::current_nr() );
	}
}
#
# tabbar and his menu visibility
#
sub get_visibility { _config()->{visible} }
sub set_visibility { _config()->{visible} = shift }
sub switch_visibility { show( _config()->{visible} ^ 1 ) }
sub show {
	my $visible = shift;
	$visible = get_visibility() unless defined $visible;
	$visible
		? _ref()->SetTabCtrlHeight(25)
		: _ref()->SetTabCtrlHeight(0);
	set_visibility($visible);
}

sub switch_contextmenu_visibility { 
	_config()->{contextmenu_use} ^= 1;
	Kephra::App::ContextMenu::connect_tabbar();
}
sub get_contextmenu_visibility { _config()->{contextmenu_use} }

1;
