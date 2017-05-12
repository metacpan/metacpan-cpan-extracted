package Kephra::Dialog;
our $VERSION = '0.20';

use strict;
use warnings;

sub _set_icon { my ($d, $cmd_id) = @_; }
sub _win      { Kephra::App::Window::_ref() }

# standard dialogs

sub msg_box {
	Wx::MessageBox( @_[0,1], &Wx::wxOK | &Wx::wxSTAY_ON_TOP, _win() );
}

sub info_box {
	Wx::MessageBox
		(@_[0,1], &Wx::wxOK | &Wx::wxICON_INFORMATION | &Wx::wxSTAY_ON_TOP, _win());
}

sub warning_box {
	Wx::MessageBox
		( @_[0,1], &Wx::wxOK | &Wx::wxICON_WARNING | &Wx::wxSTAY_ON_TOP, _win() );
}

sub get_confirm_2 {
	Wx::MessageBox
		(@_[0,1], &Wx::wxYES_NO | &Wx::wxICON_QUESTION | &Wx::wxSTAY_ON_TOP, _win());
}

sub get_confirm_3 {
	Wx::MessageBox
		( @_[0,1], &Wx::wxYES_NO | &Wx::wxCANCEL | &Wx::wxICON_QUESTION, _win() );
}

sub get_file_open {
	Wx::FileSelector( @_[0,1], '', '', $_[2], &Wx::wxFD_OPEN, _win());
}

sub get_files_open {
	my $dialog = Wx::FileDialog->new(
		_win(),  @_[0,1], '', $_[2], &Wx::wxFD_OPEN | &Wx::wxFD_MULTIPLE, [-1,-1]
	);
	if ($dialog->ShowModal != &Wx::wxID_CANCEL) {
		my @files = $dialog->GetPaths;
		return \@files;
	}
}

sub get_file_save { 
	Wx::FileSelector( @_[0,1], '', '', $_[2], &Wx::wxFD_SAVE, _win())
}

sub get_dir  { Wx::DirSelector      ( @_[0,1] ,0, [-1,-1], _win()) }
sub get_font { Wx::GetFontFromUser  ( _win(), $_[0]) }
sub get_text { Wx::GetTextFromUser  ( $_[0], $_[1], "", _win()) }
sub get_number{Wx::GetNumberFromUser( $_[0], '', $_[1],$_[2], 0, 100000, _win())}

# own dialogs

sub find {
	require Kephra::Dialog::Search;
	&Kephra::Dialog::Search::find;
}

sub replace {
	require Kephra::Dialog::Search;
	&Kephra::Dialog::Search::replace;
}
sub choose_color {
	require Kephra::Dialog::Color;
	Kephra::Dialog::Color::choose_color();
}
sub config {
	require Kephra::Dialog::Config;
	&Kephra::Dialog::Config::main;
}

sub info {
	require Kephra::Dialog::Info;
	&Kephra::Dialog::Info::combined;
}

sub notify_file_changed {
	require Kephra::Dialog::Notify;
	&Kephra::Dialog::Notify::file_changed;
}
sub notify_file_deleted {
	require Kephra::Dialog::Notify;
	&Kephra::Dialog::Notify::file_deleted;
}

sub save_on_exit {
	require Kephra::Dialog::Exit;
	&Kephra::Dialog::Exit::save_on_exit;
}

1;
