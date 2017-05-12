package Kephra::Document;
our $VERSION = '0.53';

use strict;
use warnings;

sub _file_config { Kephra::File::_config() }
sub _new_if_allowed {
	# new(empty), add(open) restore(open session)
	my $mode = shift;
	my $ep   = Kephra::App::EditPanel::_ref();
	my $file = Kephra::Document::Data::get_file_path();
	my $old_doc_nr= Kephra::Document::Data::current_nr();
	my $new_doc_nr= Kephra::Document::Data::get_value('buffer');
	my $config    = _file_config()->{open};

	# check settings
	# in single doc mode close previous doc first
	if ( $config->{single_doc} == 1 ) {
		Kephra::File::close_current();
		return 0;
	}
	unless ( $mode eq 'new' ) {
		if ($ep->GetText eq '' and $ep->GetModify == 0 and (not $file or not -e $file)){
			return $old_doc_nr
				if ($config->{into_empty_doc} == 1)
				or ($config->{into_only_empty_doc} == 1 and $new_doc_nr == 1 );
		}
	}
	# still there? good, now we make a new document
	Kephra::Document::Data::create_slot($new_doc_nr);
	Kephra::App::TabBar::add_edit_tab($new_doc_nr);
	Kephra::App::EditPanel::apply_settings_here
		( Kephra::Document::Data::_ep($new_doc_nr) );
	Kephra::Document::Data::inc_value('buffer');
	return $new_doc_nr;
}

sub _load_file_in_buffer {
	my $file = shift;
	my $doc_nr = shift || Kephra::Document::Data::current_nr();
	my $ep = Kephra::Document::Data::_ep($doc_nr);
	return unless -r $file and Kephra::App::EditPanel::is( $ep );
	$ep->ClearAll();
	# retrieve if utf is set
	Kephra::Document::Data::set_file_path($file, $doc_nr);
	if (Kephra::File::IO::open_buffer($doc_nr) ){
		Kephra::File::_remember_save_moment($doc_nr);
		$ep->EmptyUndoBuffer;
		$ep->SetSavePoint;
		Kephra::Document::Data::inc_value('loaded');
	}
}
#
sub new   {   # make document empty and reset all document properties to default
	my $old_nr = Kephra::Document::Data::current_nr();
	my $doc_nr = _new_if_allowed('new');
	Kephra::Document::Data::set_previous_nr( $old_nr );
	Kephra::Document::Data::set_current_nr( $doc_nr );
	Kephra::App::TabBar::raise_tab_by_doc_nr($doc_nr);
	&reset($doc_nr);
	Kephra::EventTable::trigger('document.new');
}

sub reset {   # restore once opened file from its settings
	my $doc_nr = Kephra::Document::Data::validate_doc_nr(shift);
	$doc_nr = Kephra::Document::Data::current_nr() unless defined $doc_nr;
	my $ep = Kephra::Document::Data::_ep( $doc_nr );
	Kephra::Document::Property::set_readonly(0, $doc_nr);
	$ep->ClearAll;
	$ep->EmptyUndoBuffer;
	$ep->SetSavePoint;
	Kephra::Document::Data::set_attributes_to_default($doc_nr, '');
	Kephra::Document::Data::evaluate_attributes($doc_nr);
	Kephra::App::Window::refresh_title();
	Kephra::App::TabBar::refresh_label($doc_nr);
	Kephra::App::StatusBar::refresh_all_cells();
	Kephra::Edit::Marker::delete_doc($doc_nr);
	Kephra::App::EditPanel::Margin::autosize_line_number($ep, $doc_nr);
}


sub restore { # add newly opened file from known settings
	my %file_settings = %{ shift; };
	my $file = $file_settings{file_path};
	my $config = _file_config();
	if ( -e $file ) {
		# open only text files and empty files
		return if $config->{open}{only_text} == 1 and -B $file;
		# check if file is already open and goto this already opened
		return if $config->{open}{each_once} == 1 
		      and Kephra::Document::Data::file_already_open($file);
		my $doc_nr = _new_if_allowed('restore');
		$file_settings{ep_ref} = Kephra::Document::Data::_ep($doc_nr);
		Kephra::Document::Data::set_all_attributes(\%file_settings, $doc_nr);
		_load_file_in_buffer($file, $doc_nr);
		Kephra::Document::Data::set_current_nr($doc_nr);
		Kephra::Document::Data::set_file_path($file, $doc_nr);
		Kephra::Document::Data::evaluate_attributes($doc_nr);
		Kephra::App::TabBar::raise_tab_by_doc_nr($doc_nr);
		return $doc_nr;
	}
	return -1;
}


sub add {     # create a new document if settings allow it
	my $file = shift;
	my $config = _file_config();
	my $old_nr = Kephra::Document::Data::current_nr();
	if ( defined $file and -e $file ) {
		$file = Kephra::Config::standartize_path_slashes( $file );
		# open only text files and empty files
		# return if -B $file and $config->{open}{only_text} == 1;
		# check if file is already open and goto this already opened
		my $other_nr = Kephra::Document::Data::nr_from_file_path($file);
		return Kephra::Document::Change::to_nr( $other_nr )
			if $config->{open}{each_once} == 1 and $other_nr > -1;
		# save constantly changing settings
		Kephra::Document::Data::update_attributes();
		# create new edit panel
		my $doc_nr = _new_if_allowed('add') || 0;
		# return because settings didn't allow new doc
		return if $doc_nr > 0 and $doc_nr == $old_nr;
		Kephra::Document::Data::set_current_nr($doc_nr);
		Kephra::Document::Data::set_previous_nr($old_nr);
		# load default settings for doc attributes
		Kephra::Document::Data::set_attributes_to_default($doc_nr, $file);
		_load_file_in_buffer($file, $doc_nr);
		Kephra::Document::Property::convert_EOL(), Kephra::File::_save_nr($doc_nr)
			unless Kephra::Document::Data::get_attribute{'EOL',$doc_nr} eq 'auto';
		Kephra::Document::Data::evaluate_attributes($doc_nr);
		Kephra::App::Window::refresh_title();
		Kephra::App::TabBar::raise_tab_by_doc_nr($doc_nr);
		Kephra::App::EditPanel::Margin::autosize_line_number();
		Kephra::EventTable::trigger('document.new');
		Kephra::EventTable::trigger('document.list');
	}
}

# document wide coverter
sub convert_indent2tabs   { _edit( \&Kephra::Edit::Convert::indent2tabs  )}
sub convert_indent2spaces { _edit( \&Kephra::Edit::Convert::indent2spaces)}
sub convert_spaces2tabs   { _edit( \&Kephra::Edit::Convert::spaces2tabs  )}
sub convert_tabs2spaces   { _edit( \&Kephra::Edit::Convert::tabs2spaces  )}
sub del_trailing_spaces   { _edit( \&Kephra::Edit::Format::del_trailing_spaces)}

sub save_state {
}
sub restore_styte {
}
#
sub _edit {
	my $coderef = shift;
	return unless ref $coderef eq 'CODE';
	Kephra::Edit::_save_positions();
	Kephra::Edit::Select::all();
	&$coderef();
	Kephra::Edit::_restore_positions();
	1;
}

sub do_with_all {
	my $code = shift;
	return unless ref $code eq 'CODE';
	my $nr = Kephra::Document::Data::current_nr();
	my $attr = Kephra::Document::Data::_attributes();
	Kephra::Document::Data::update_attributes();
	for ( @{ Kephra::Document::Data::all_nr() } ) {
		Kephra::Document::Data::set_current_nr($_);
		&$code( $attr->[$_] );
	}
	Kephra::Document::Data::set_current_nr($nr);
	Kephra::Document::Data::evaluate_attributes($nr);
}

1;

=head1 NAME

Kephra::Document - general doc functions

=head1 DESCRIPTION



=cut