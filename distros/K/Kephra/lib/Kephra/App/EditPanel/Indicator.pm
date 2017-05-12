package Kephra::App::EditPanel::Indicator;
$VERSION = '0.01';

use strict;
use warnings;

sub _ref     { Kephra::App::EditPanel::_ref() }
sub _all_ref { Kephra::Document::Data::get_all_ep() }
sub _config  { Kephra::API::settings()->{editpanel}{indicator} }

# aply all indicator setting to this edit panel
sub apply_all_here {
	my $ep = shift || _ref();
	my $indicator = _config();
	my $color     = \&Kephra::Config::color;

	$ep->SetCaretLineBack( &$color( $indicator->{caret_line}{color} ) );
	$ep->SetCaretPeriod( $indicator->{caret}{period} );
	$ep->SetCaretWidth( $indicator->{caret}{width} );
	$ep->SetCaretForeground( &$color( $indicator->{caret}{color} ) );
	if ( $indicator->{selection}{fore_color} ne '-1' ) {
		$ep->SetSelForeground
			( 1, &$color( $indicator->{selection}{fore_color} ) );
	}
	$ep->SetSelBackground( 1, &$color( $indicator->{selection}{back_color}));
	$ep->SetWhitespaceForeground
		( 1, &$color( $indicator->{whitespace}{color} ) );

	apply_whitespace_settings_here($ep);
	apply_bracelight_settings_here($ep);
	apply_caret_line_settings_here($ep);
	apply_indention_guide_settings_here($ep);
	apply_LLI_settings_here($ep);
	apply_EOL_settings_here($ep);
}

# whitespace
#
sub whitespace_visible { _config()->{whitespace}{visible} }
sub apply_whitespace_settings_here {
	my $ep = shift || _ref();
	$ep->SetViewWhiteSpace( whitespace_visible() )
}
sub apply_whitespace_settings { 
	apply_whitespace_settings_here($_) for @{_all_ref()}
}
sub switch_whitespace_visibility {
	my $v = _config()->{whitespace}{visible} ^= 1;
	apply_whitespace_settings();
	return $v;
}
# bracelight
#
sub bracelight_visible { _config()->{bracelight}{visible} }
sub switch_bracelight {
	bracelight_visible() ? set_bracelight_off() : set_bracelight_on();
}
sub set_bracelight_on {
	_config()->{bracelight}{visible} = 1;
	apply_bracelight_settings()
}
sub set_bracelight_off {
	_config()->{bracelight}{visible} = 0;
	apply_bracelight_settings()
}#{bracelight}{mode} = 'adjacent'|'surround';

sub apply_bracelight_settings { 
	apply_bracelight_settings_here($_) for @{_all_ref()}
}
sub apply_bracelight_settings_here {
	my $ep = shift || _ref();
	if (bracelight_visible()){
		Kephra::EventTable::add_call
			('caret.move', 'bracelight', \&paint_bracelight);
		paint_bracelight($ep);
	} else {
		Kephra::EventTable::del_call('caret.move', 'bracelight');
		$ep->BraceHighlight( -1, -1 );
	}
}

sub paint_bracelight {
	my $ep       = shift || _ref();
	my $pos      = $ep->GetCurrentPos;
	my $tab_size = Kephra::Document::Data::get_attribute('tab_size');
	my $matchpos = $ep->BraceMatch(--$pos);
	$matchpos = $ep->BraceMatch(++$pos) if $matchpos == -1;

	$ep->SetHighlightGuide(0);
	if ( $matchpos > -1 ) {
		# highlight braces
		$ep->BraceHighlight($matchpos, $pos);
		# asign pos to opening brace
		$pos = $matchpos if $matchpos < $pos;
		my $indent = $ep->GetLineIndentation( $ep->LineFromPosition($pos) );
		# highlighting indenting guide
		$ep->SetHighlightGuide($indent)
			if $indent and $tab_size and $indent % $tab_size == 0;
	} else {
		# disbale all highlight
		$ep->BraceHighlight( -1, -1 );
		$ep->BraceBadLight($pos-1)
			if $ep->GetTextRange($pos-1,$pos) =~ /{|}|\(|\)|\[|\]/;
		$ep->BraceBadLight($pos)
			if $pos < $ep->GetTextLength
			and $ep->GetTextRange( $pos, $pos + 1 ) =~ tr/{}()\[\]//;
	}
}
# indention guide
#
sub indention_guide_visible { _config()->{indent_guide}{visible} }
sub apply_indention_guide_settings {
	apply_indention_guide_settings_here($_) for @{_all_ref()}
}
sub apply_indention_guide_settings_here {
	my $ep = shift || _ref();
	$ep->SetIndentationGuides( indention_guide_visible() )
}
sub switch_indention_guide_visibility {
	_config()->{indent_guide}{visible} ^= 1;
	apply_indention_guide_settings();
}

# caret line
#
sub caret_line_visible { _config()->{caret_line}{visible} }
sub apply_caret_line_settings_here {
	my $ep = shift || _ref();
	$ep->SetCaretLineVisible( caret_line_visible() );
}
sub apply_caret_line_settings {
	apply_caret_line_settings_here($_) for @{_all_ref()}
}
sub switch_caret_line_visibility {
	_config()->{caret_line}{visible} ^= 1;
	apply_caret_line_settings();
}

# LLI = long line indicator = right margin
#
sub LLI_visible { _config()->{right_margin}{style} == &Wx::wxSTC_EDGE_LINE }
sub apply_LLI_settings_here {
	my $ep = shift || _ref();
	my $config = _config()->{right_margin};
	my $color   = \&Kephra::Config::color;
	$ep->SetEdgeColour( &$color( $config->{color} ) );
	$ep->SetEdgeColumn( $config->{position} );
	show_LLI( $config->{style}, $ep);
}
sub show_LLI {
	my $style = shift;
	my $ep = shift || _ref();
	$ep->SetEdgeMode( $style );
}
sub apply_LLI_settings { apply_LLI_settings_here($_) for @{_all_ref()} }
sub switch_LLI_visibility {
	my $style = _config()->{right_margin}{style} = LLI_visible()
		? &Wx::wxSTC_EDGE_NONE
		: &Wx::wxSTC_EDGE_LINE;
	apply_LLI_settings($style);
}

# EOL = end of line marker
#
sub EOL_visible { _config()->{end_of_line_marker} }
sub switch_EOL_visibility {
	_config()->{end_of_line_marker} ^= 1;
	apply_EOL_settings();
}
sub apply_EOL_settings { apply_EOL_settings_here($_) for @{_all_ref()} }
sub apply_EOL_settings_here {
	my $ep = shift || _ref();
	$ep->SetViewEOL( EOL_visible() );

}

1;