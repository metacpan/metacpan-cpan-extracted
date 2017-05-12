package Kephra::Dialog::Info;
our $VERSION = '0.08';

use strict;
use warnings;

sub combined {
	return simple();

	my $info_win = Wx::Frame->new(
		Kephra::App::Window::_ref(), -1,
		" Info About Kephra",
		[ 100, 100 ],
		[ 460, 260 ],
		&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX,
	);
	Kephra::App::Window::load_icon( $info_win,
		Kephra::API::settings()->{app}{window}{icon} );
	$info_win->SetBackgroundColour( Wx::Colour->new( 0xed, 0xeb, 0xdb ) );
# Wx::HyperlinkCtrl->new($win,-1,label,url,pos,size,wxHL_CONTEXTMENU)
	$info_win->Centre(&Wx::wxBOTH);
	$info_win->Show(1);
}

sub simple {
	my $info = Kephra::Config::Localisation::strings()->{dialog}{info};
	my $sciv = 'Scintilla ';
	my $v = substr(&Wx::wxVERSION_STRING ,-5);
	if    ($v eq '2.4.2'){$sciv .= '1.54'}
	elsif ($v eq '2.6.2'){$sciv .= '1.62'}
	elsif ($v eq '2.6.3'){$sciv .= '1.62'}
	elsif ($v eq '2.8.4'){$sciv .= '1.70'}
	elsif ($v eq '2.8.7'){$sciv .= '1.70'}
	elsif ($v eq '2.8.10'){$sciv .= '1.70'}
	my $content = "Kephra, $info->{motto}\n"
		. $info->{mady_by} . "  Herbert Breunung\n\n"
		. $info->{licensed} . " GPL (GNU Public License) \n"
		. " ( $info->{detail} \n   $info->{more} ) \n"
		. "$info->{homepage}  http://kephra.sf.net\n\n"
		. $info->{contains} . ": \n"
		. " - Perl ". substr($],0,1).'.'.int(substr($],3,2)).'.'.substr($],7,1)."\n"
		. " - WxPerl $Wx::VERSION $info->{wrappes} \n"
		. "   - " . &Wx::wxVERSION_STRING . " $info->{and} $sciv\n"
		. " - Config::General $Config::General::VERSION \n"
		. " - YAML::Tiny $YAML::Tiny::VERSION \n"
		."\n\n $info->{dedication}"
		. "";
	my $title = "$info->{title} $Kephra::NAME $Kephra::VERSION";
	$title .=  ' pl ' . $Kephra::PATCHLEVEL if $Kephra::PATCHLEVEL;
	Kephra::Dialog::msg_box( $content, $title );
}

1;

