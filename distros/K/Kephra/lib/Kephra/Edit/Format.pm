package Kephra::Edit::Format;
our $VERSION = '0.26';

use strict;
use warnings;

sub _ep_ref { Kephra::App::EditPanel::_ref() }
sub _config { Kephra::API::settings()->{editpanel} }

# change indention width of selected text
sub _indent_selection {
	my $width = shift || 0;
	my $ep    = _ep_ref();
	$ep->BeginUndoAction;
	for (    $ep->LineFromPosition($ep->GetSelectionStart)
	      .. $ep->LineFromPosition($ep->GetSelectionEnd)   ) {
		$ep->SetLineIndentation( $_, $ep->GetLineIndentation($_) + $width )
			unless $ep->PositionFromLine($_) == $ep->GetLineEndPosition($_);
	}
	$ep->EndUndoAction;
}

sub autoindent {
	my $ep  = _ep_ref();
	my $line = $ep->GetCurrentLine;

	$ep->BeginUndoAction;
	$ep->CmdKeyExecute(&Wx::wxSTC_CMD_NEWLINE);
	my $indent = $ep->GetLineIndentation( $line );
	$ep->SetLineIndentation( $line + 1, $indent);
	$ep->GotoPos( $ep->GetLineIndentPosition( $line + 1 ) );
	$ep->EndUndoAction;
}

sub blockindent_open {
	my $ep         = _ep_ref();
	my $tabsize    = Kephra::Document::Data::attr('tab_size');
	my $line       = $ep->GetCurrentLine;
	my $first_cpos = $ep->PositionFromLine($line)
		+ $ep->GetLineIndentation($line); # position of first char in line
	my $matchfirst = $ep->BraceMatch($first_cpos);

	$ep->BeginUndoAction;

	# dedent a "} else {" correct
	if ($ep->GetCharAt($first_cpos) == 125 and $matchfirst > -1) {
		$ep->SetLineIndentation( $line, $ep->GetLineIndentation(
				$ep->LineFromPosition($matchfirst) ) );
	}
	# grabbing
	my $bracepos   = $ep->GetCurrentPos - 1;
	my $leadindent = $ep->GetLineIndentation($line);
	my $matchbrace = $ep->BraceMatch( $bracepos );
	my $matchindent= $ep->GetLineIndentation($ep->LineFromPosition($matchbrace));

	# make newl line
	$ep->CmdKeyExecute(&Wx::wxSTC_CMD_NEWLINE);

	# make new brace if there is missing one
	if (_config()->{auto}{brace}{make} and
		($matchbrace == -1 or $ep->GetLineIndentation($line) != $matchindent )){
		$ep->CmdKeyExecute(&Wx::wxSTC_CMD_NEWLINE);
		$ep->AddText('}');
		$ep->SetLineIndentation( $line + 2, $leadindent );
	}
	$ep->SetLineIndentation( $line + 1, $leadindent + $tabsize );
	$ep->GotoPos( $ep->GetLineIndentPosition( $line + 1 ) );

	$ep->EndUndoAction;
}

sub blockindent_close {
	my $ep = _ep_ref();
	my $bracepos = shift;
	unless ($bracepos) {
		$bracepos = $ep->GetCurrentPos - 1;
		$bracepos-- while $ep->GetCharAt($bracepos) == 32;
	}

	$ep->BeginUndoAction;

	# 1 if it not textend, goto next line
	my $match = $ep->BraceMatch($bracepos);
	my $line  = $ep->GetCurrentLine;
	unless ($ep->GetLineIndentPosition($line)+1 == $ep->GetLineEndPosition($line)
		or  $ep->LineFromPosition($match) == $line ) {
		$ep->GotoPos($bracepos);
		$ep->CmdKeyExecute(&Wx::wxSTC_CMD_NEWLINE);
		$ep->GotoPos( $ep->GetCurrentPos + 1 );
		$line++;
	}

	# 2 wenn match dann korrigiere einrückung ansonst letzte - tabsize
	if ( $match > -1 ) {
		$ep->SetLineIndentation( $line,
			$ep->GetLineIndentation( $ep->LineFromPosition($match) ) );
	} else {
		$ep->SetLineIndentation( $line,
			$ep->GetLineIndentation( $line - 1 )
				- Kephra::Document::Data::attr('tab_size') );
	}

	# make new line
	_config()->{auto}{indent}
		? autoindent()
		: $ep->CmdKeyExecute(&Wx::wxSTC_CMD_NEWLINE);

	# 3 lösche dubs wenn in nächster zeile nur spaces bis dup
	#if ( _config()->{auto}{brace}{join} ) {
		#my $delbrace = $ep->PositionFromLine( $line + 2 )
			#+ $ep->GetLineIndentation( $line + 1 );
		#if ( $ep->GetCharAt($delbrace) == 125 ) {
			#$ep->SetTargetStart( $ep->GetCurrentPos );
			#$ep->SetTargetEnd( $delbrace + 1 );
			#$ep->ReplaceTarget('');
		#}
	#}

	$ep->EndUndoAction;
}

sub indent_space { _indent_selection( 1) }
sub dedent_space { _indent_selection(-1) }
sub indent_tab   { _indent_selection( Kephra::Document::Data::attr('tab_size') ) }
sub dedent_tab   { _indent_selection(-Kephra::Document::Data::attr('tab_size') ) }

#
sub align_indent {
	my $ep = _ep_ref();
	my $firstline = $ep->LineFromPosition( $ep->GetSelectionStart );
	my $align = $ep->GetLineIndentation($firstline);
	$ep->BeginUndoAction();
	$ep->SetLineIndentation($_ ,$align)
		for $firstline + 1 .. $ep->LineFromPosition($ep->GetSelectionEnd);
	$ep->EndUndoAction();
}

# deleting trailing spaces on line ends
sub del_trailing_spaces {
	&Kephra::Edit::_save_positions;
	my $ep = _ep_ref();
	my $text = Kephra::Edit::_select_all_if_none();
	$text =~ s/[ \t]+(\r|\n|\Z)/$1/g;
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
	Kephra::Edit::_restore_positions();
}

#
sub join_lines {
 my $ep = _ep_ref();
 my $text = $ep->GetSelectedText();
	$text =~ s/[\r|\n]+/ /g; # delete end of line marker
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
}

sub blockformat{
	return unless Scalar::Util::looks_like_number($_[0]);
	my $width     = (int shift) + 1;
	my $ep        = _ep_ref();
	my ($begin, $end) = $ep->GetSelection;
	my $bline     = $ep->LineFromPosition($begin);
	my $tmp_begin = $ep->PositionFromLine($bline);
	my $bspace    = ' ' x $ep->GetLineIndentation($bline);
	my $space     = _config()->{auto}{indention} ? $bspace : '';
	chop $bspace;

	$ep->SetSelection($tmp_begin, $end);
	require Text::Wrap;
	$Text::Wrap::columns  = $width;
	$Text::Wrap::unexpand = Kephra::Document::Data::attr('tab_use');
	$Text::Wrap::tabstop  = Kephra::Document::Data::attr('tab_size');

	my $text = $ep->GetSelectedText;
	$text =~ s/[\r|\n]+/ /g;
	$ep->BeginUndoAction();
	$ep->ReplaceSelection( Text::Wrap::fill($bspace, $space, $text) );
	$ep->EndUndoAction();
}

sub blockformat_LLI{
	blockformat( _config()->{indicator}{right_margin}{position} );
}

sub blockformat_custom {
	my $l18n = Kephra::Config::Localisation::strings()->{dialog}{edit};
	my $width = Kephra::Dialog::get_text(
		$l18n->{wrap_width_input}, 
		$l18n->{wrap_custom_headline}
	);
	blockformat( $width ) if defined $width;
}



# breaking too long lines into smaller one
sub line_break {
	return unless Scalar::Util::looks_like_number($_[0]);
	my $width        = (int shift) + 1;
	my $ep           = _ep_ref();
	my ($begin, $end)= $ep->GetSelection;
	my $tmp_begin    = $ep->LineFromPosition( $ep->PositionFromLine($begin) );

	$ep->SetSelection($tmp_begin, $end);
	require Text::Wrap;
	$Text::Wrap::columns  = $width;
	$Text::Wrap::unexpand = Kephra::Document::Data::attr('tab_use');
	$Text::Wrap::tabstop  = Kephra::Document::Data::attr('tab_size');

	$ep->BeginUndoAction();
	$ep->ReplaceSelection( Text::Wrap::wrap('', '', $ep->GetSelectedText) );
	$ep->EndUndoAction();
}

sub linebreak_custom {
	my $l10n = Kephra::Config::Localisation::strings()->{dialog}{edit};
	my $width = Kephra::Dialog::get_text
			($l10n->{wrap_width_input}, $l10n->{wrap_custom_headline} );
	line_break( $width ) if defined $width;
}

sub linebreak_LLI {
	line_break( _config()->{indicator}{right_margin}{position} );
}

sub linebreak_window {
	my $app = Kephra::App::Window::_ref();
	my $ep  = _ep_ref();
	my ($width) = $app->GetSizeWH();
	my $pos = $ep->GetColumn( $ep->PositionFromPointClose(100, 67) );
	Kephra::Dialog::msg_box( $pos, '' );
	#line_break($width);
}

1;
__END__

=head1 NAME

Kephra::App::Format - functions that play with indention and length of lines

=head1 DESCRIPTION
