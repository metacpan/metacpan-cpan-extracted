package Kephra::Document::SyntaxMode;
our $VERSION = '0.06';

use strict;
use warnings;

my $current;
sub _ID { $current = defined $_[0] ? $_[0] : $current }

# syntaxstyles

sub _get_auto{ &_get_by_fileending }
sub _get_by_fileending {
	my $file_ending = Kephra::Document::Data::get_attribute('ending', shift );
	chop $file_ending if $file_ending and (substr ($file_ending, -1) eq '~');
	my $language_id;
	if ($file_ending) {
		$language_id = $Kephra::temp{file}{end2langmap}
				{ Kephra::Config::_lc_utf($file_ending) };
	} else                                     { return "none" }
	if ( !$language_id  or $language_id eq '') { return "none" }
	elsif ( $language_id eq 'text' )           { return "none" }
	return $language_id;
}

sub switch_auto {
	my $auto_style = _get_auto();
	if (_ID() ne $auto_style) { set($auto_style) }
	else                      { set('none')      }
}

sub reload { 
	my $nr = Kephra::Document::Data::valid_or_current_doc_nr(shift);
	set( Kephra::Document::Data::get_attribute('syntaxmode', $nr), $nr );
}
sub update { _ID(Kephra::Document::Data::attr('syntaxmode')) }

sub set {
	my $style  = shift;
	my $doc_nr = Kephra::Document::Data::valid_or_current_doc_nr(shift);
	return if $doc_nr == -1;
	my $ep     = Kephra::Document::Data::_ep($doc_nr);
	my $color  = \&Kephra::Config::color;
	$style = _get_by_fileending() if $style eq 'auto';
	$style = 'none' unless $style;

	# do nothing when syntaxmode of next doc is the same
	#return if _ID() eq $style;
	# prevent clash between big lexer & indicator
	if ( $style =~ /asp|html|php|xml/ ) { $ep->SetStyleBits(7) }
	else                                { $ep->SetStyleBits(5) }
	# clear style infos
	$ep->StyleResetDefault;
	Kephra::App::EditPanel::load_font($ep);
	$ep->StyleClearAll;
	$ep->SetKeyWords( $_, '' ) for 0 .. 1;
	# load syntax style
	if ( $style eq 'none' ) { 
		$ep->SetLexer(&Wx::wxSTC_LEX_NULL);
	} else {
		eval("require syntaxhighlighter::$style");
		eval("syntaxhighlighter::$style" . '::load($ep)');
	}

	# restore bracelight, bracebadlight indentguide colors
	my $indicator = Kephra::App::EditPanel::_config()->{indicator};
	my $bracelight = $indicator->{bracelight};
	if ( $bracelight->{visible} ) {
		$ep->StyleSetBold( &Wx::wxSTC_STYLE_BRACELIGHT, 1 );
		$ep->StyleSetBold( &Wx::wxSTC_STYLE_BRACEBAD,   1 );
		$ep->StyleSetForeground
			( &Wx::wxSTC_STYLE_BRACELIGHT, &$color( $bracelight->{good_color} ) );
		$ep->StyleSetBackground
			( &Wx::wxSTC_STYLE_BRACELIGHT, &$color( $bracelight->{back_color} ) );
		$ep->StyleSetForeground
			( &Wx::wxSTC_STYLE_BRACEBAD, &$color( $bracelight->{bad_color} ) );
		$ep->StyleSetBackground
			( &Wx::wxSTC_STYLE_BRACEBAD, &$color( $bracelight->{back_color} ) );
		$ep->StyleSetForeground 
			(&Wx::wxSTC_STYLE_INDENTGUIDE,&$color($indicator->{indent_guide}{color}));
	}

	Kephra::Document::Data::set_attribute( 'syntaxmode', $style, $doc_nr);
	_ID($style);

	Kephra::EventTable::freeze('document.text.change');
	$ep->Colourise( 0, $ep->GetTextLength ); # refresh editpanel painting, not needed normally
	Kephra::EventTable::thaw('document.text.change');
	# cleanup
	Kephra::App::EditPanel::Margin::refresh_changeable_settings($ep);
	Kephra::App::StatusBar::style_info($style);
	return $style;
}

sub compile {}
sub apply_color {}

sub open_file  { Kephra::Config::open_file( 'syntaxhighlighter', "$_[0].pm") }

1;

=head1 NAME

Kephra::Document::SyntaxMode - content language specific settings of a doc

=head1 DESCRIPTION


=cut