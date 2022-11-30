use v5.12;
use warnings;
use Wx;

package Kephra::App::Dialog;


sub _parent { undef }

# standard dialogs

sub message {
	$_[1] = $_[1] || 'Kephra Message'; 
	splice @_, 2, 0, &Wx::wxOK | &Wx::wxSTAY_ON_TOP;
	_box( @_ );
}
sub info   {
	$_[1] = $_[1] || 'Kephra Information'; 
	splice @_, 2, 0, &Wx::wxOK | &Wx::wxICON_INFORMATION | &Wx::wxSTAY_ON_TOP;
	_box( @_ );
}
sub warning {
	$_[1] = $_[1] || 'Kephra Warning'; 
	splice @_, 2, 0, &Wx::wxOK | &Wx::wxICON_WARNING | &Wx::wxSTAY_ON_TOP;
	_box( @_ );
}
sub yes_no  { 
	$_[1] = $_[1] || 'Kephra Question'; 
	splice @_, 2, 0, &Wx::wxYES_NO | &Wx::wxICON_QUESTION | &Wx::wxSTAY_ON_TOP;
	_box( @_ );
}
sub yes_no_cancel {
	$_[1] = $_[1] || 'Kephra Question'; 
	splice @_, 2, 0, &Wx::wxYES_NO | &Wx::wxCANCEL | &Wx::wxICON_QUESTION | &Wx::wxSTAY_ON_TOP;
	_box( @_ );
}
sub _box {                                   # $message, $title, $style, $parent
	#Kephra::Log::warning('need at least a message as first parameter', 2) unless $_[0];
	$_[3] = $_[3] || _parent(); 
	Wx::MessageBox( @_ );
}

sub get_file_open {
	my $title  = shift // 'Open File ...';
	my $dir    = shift // '.';
	my $filter = shift // '(*)|*';
	my $parent = shift // _parent();
	Wx::FileSelector( $title, $dir, '', '', $filter, &Wx::wxFD_OPEN, $parent);
}

sub get_files_open {
	my $title  = shift // 'Open File ...';
	my $dir    = shift // '.';
	my $filter = shift // '(*)|*';
	my $parent = shift // _parent();
	my $dialog = Wx::FileDialog->new
		($parent, $title, $dir, '', $filter, &Wx::wxFD_OPEN | &Wx::wxFD_MULTIPLE);
	if ($dialog->ShowModal != &Wx::wxID_CANCEL) {
		return $dialog->GetPaths;
	}
}

sub get_file_save { 
	my $title  = shift // 'Save File As ...';
	my $dir    = shift // '.';
	my $filter = shift // '(*)|*';
	my $parent = shift // _parent();
	Wx::FileSelector( $title, $dir, '', '', $filter, &Wx::wxFD_SAVE, $parent);
}

sub get_dir  {  Wx::DirSelector      ( @_[0,1], 0, [-1,-1], _parent()) }
sub get_font {  Wx::GetFontFromUser  ( _parent(), $_[0]) }
sub get_text {  Wx::GetTextFromUser  ( $_[0], $_[1], "", _parent()) }
sub get_number {Wx::GetNumberFromUser( $_[0], '', $_[1],$_[2], 0, 100000, _parent())}

# own dialogs
#sub find {
	#require Kephra::App::Dialog::Search; &Kephra::App::Dialog::Search::find;
#}
#sub replace {
	#require Kephra::App::Dialog::Search; &Kephra::App::Dialog::Search::replace;
#}
#sub choose_color {
	#require Kephra::App::Dialog::Color; Kephra::App::Dialog::Color::choose_color();
#}
sub about {
	require Kephra::App::Dialog::About;
	Kephra::App::Dialog::About->new( shift )->ShowModal;
}
sub config {
	require Kephra::App::Dialog::Config;
	Kephra::App::Dialog::Config::create( )->ShowModal;
}
sub documentation {
	require Kephra::App::Dialog::Documentation;
	Kephra::App::Dialog::Documentation->new( shift )->ShowModal;
}
sub keymap {
	require Kephra::App::Dialog::Keymap;
	Kephra::App::Dialog::Keymap->new( shift )->ShowModal;
}

#sub notify_file_changed {
	#require Kephra::App::Dialog::Notify; &Kephra::App::Dialog::Notify::file_changed;
#}
#sub notify_file_deleted {
	#require Kephra::App::Dialog::Notify; &Kephra::App::Dialog::Notify::file_deleted;
#}
#sub save_on_exit {
	#require Kephra::App::Dialog::Exit; &Kephra::App::Dialog::Exit::save_on_exit;
#}


1;
