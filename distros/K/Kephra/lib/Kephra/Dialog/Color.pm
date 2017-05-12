package Kephra::Dialog::Color;
our $VERSION = '0.02';

use strict;
use warnings;

sub choose_color {
	my $ep    = &Kephra::App::EditPanel::_ref;
	my $color = $ep->GetSelectedText || '#ffffff';

	$color = sprintf ("%02x%02x%02x", ($color =~ /(\d+).(\d+).(\d+)/))
		if index $color, ',' or index $color, '.';
	$color = sprintf "#%s", $color unless index( $color, '#' ) == 0;

	my $color_obj = Wx::Colour->new( $color );
  
	my $data = Wx::ColourData->new;
	$data->SetColour( $color_obj );
	$data->SetChooseFull( 1 );

	my $dialog = Wx::ColourDialog->new( Kephra::App::Window::_ref(), $data );

	if( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
		my $data      = $dialog->GetColourData;
		my $ret_color = $data->GetColour;
	
		my $html_color = $ret_color->GetAsString( &Wx::wxC2S_HTML_SYNTAX );
		$html_color =~ s/^#//;
		$ep->ReplaceSelection( $html_color );
	}
}

1;