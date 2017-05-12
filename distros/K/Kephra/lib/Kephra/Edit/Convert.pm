package Kephra::Edit::Convert;
our $VERSION = '0.10';

use strict;
use warnings;
# wrapper method for the always same preparation and afterwork
sub _default {
	my $action = shift;
	return until ref $action eq 'CODE';
	my $ep = Kephra::App::EditPanel::_ref();
	Kephra::EventTable::freeze_group('edit');
	my ($begin, $end) = $ep->GetSelection;
	Kephra::Edit::_save_positions();
	$ep->BeginUndoAction;
	$ep->SelectAll if $begin == $end;
	&$action( $ep );
	$ep->EndUndoAction;
	Kephra::Edit::_restore_positions();
	Kephra::EventTable::thaw_group('edit');
}

# perform regexes on selection
sub _tr {
	my ($dir, @arg) = @_;
	my ($fi, $ti);
	($fi, $ti) = $dir eq 'fore' ? (0,1) : (1,0);
	_default( sub {
		my $ep = shift;
		my $text = $ep->GetSelectedText();
		$text =~ s/$_->[$fi]/$_->[$ti]/g for @arg;
		$ep->ReplaceSelection($text);
	} );
}
#
# external calls
#
sub upper_case {_default( sub{ shift->CmdKeyExecute(&Wx::wxSTC_CMD_UPPERCASE) } )}
sub lower_case {_default( sub{ shift->CmdKeyExecute(&Wx::wxSTC_CMD_LOWERCASE) } )}
sub title_case {_default( sub{
		my $ep = shift;
		my ($sel_end, $pos) = ($ep->GetSelectionEnd, 0);
		$ep->SetCurrentPos( $ep->GetSelectionStart - 1 );
		while () {
			$ep->CmdKeyExecute(&Wx::wxSTC_CMD_WORDRIGHT);
			$pos = $ep->GetCurrentPos;
			last if $sel_end <= $pos;
			$ep->SetSelection( $pos, $pos + 1 );
			$ep->CmdKeyExecute(&Wx::wxSTC_CMD_UPPERCASE);
		}
} )}

sub sentence_case { _default( sub{
		my $ep = shift;
		my $line;
		my ($sel_end, $pos) = ($ep->GetSelectionEnd, 0);
		$ep->SetCurrentPos( $ep->GetSelectionStart() - 1 );
		while () {
			$ep->CmdKeyExecute(&Wx::wxSTC_CMD_WORDRIGHT);
			$pos  = $ep->GetCurrentPos;
			$line = $ep->LineFromPosition($pos);
			if ($pos == $ep->GetLineEndPosition( $ep->LineFromPosition($pos) )) {
				$ep->CmdKeyExecute(&Wx::wxSTC_CMD_WORDRIGHT);
				$pos = $ep->GetCurrentPos;
			}
			last if $sel_end <= $pos;
			$ep->SetSelection( $pos, $pos + 1 );
			$ep->CmdKeyExecute(&Wx::wxSTC_CMD_UPPERCASE);
			$ep->SetCurrentPos( $pos + 1 );
			$ep->SearchAnchor;
			last if $ep->SearchNext( 0, "." ) == -1 ;
		}
} )}
#
#
#
sub _tabs2spaces { [' ' x Kephra::App::EditPanel::_ref()->GetTabWidth, "\t"] }
sub spaces2tabs { _tr('fore', _tabs2spaces()) }
sub tabs2spaces { _tr('back', _tabs2spaces()) }
#
#
#
sub indent2tabs   { _indention(1) }
sub indent2spaces { _indention(0) }
sub _indention {
	my $indention = shift;
	my $ep = Kephra::App::EditPanel::_ref();
	my ($begin, $end) = $ep->GetSelection;
	my $use_tabs = $ep->GetUseTabs;
	my $i;
	$ep->SetUseTabs($indention);
	$ep->BeginUndoAction();
	for ($ep->LineFromPosition($begin) .. $ep->LineFromPosition($end)) {
		$i = $ep->GetLineIndentation($_);
		$ep->SetLineIndentation( $_, $i + 1 );
		$ep->SetLineIndentation( $_, $i );
	}
	$ep->EndUndoAction;
	$ep->SetUseTabs($use_tabs);
}
#
# HTML enteties
#
my $space2entety = [' ','&nbsp;'];
my @char2entity = (
	['à','&agrave;'],['á','&aacute;'],['â','&acirc;'],['ä','&auml;'],
	['À','&Agrave;'],['Á','&Aacute;'],['Â','&Acirc;'],['Ä','&Auml;'],
	['ã','&atilde;'],['å','&aring;'],['Ã','&Atilde;'],['Å','&Aring;'],
	['æ','&aelig;'], ['Æ','&AElig;'],['ç','&ccedil;'],['Ç','&Ccedil;'],
	['è','&egrave;'],['é','&eacute;'],['ê','&ecirc;'],['ë','&euml;'],
	['È','&Egrave;'],['É','&Eacute;'],['Ê','&Ecirc;'],['Ë','&Euml;'],
	['ð','&eth;'],   ['Ð','&ETH;'],  
	['ì','&igrave;'],['í','&iacute;'],['î','&icirc;'],['ï','&iuml;'], 
	['Ì','&Igrave;'],['Í','&Iacute;'],['Î','&Icirc;'],['Ï','&Iuml;'], 
	['µ','&micro;'], ['ñ','&ntilde;'],['Ñ','&ntilde;'],
	['ò','&ograve;'],['ó','&oacute;'],['ô','&ocirc;'],['ö','&ouml;'],
	['Ò','&Ograve;'],['Ó','&Oacute;'],['Ô','&Ocirc;'],['Ö','&Ouml;'],
	['õ','&otilde;'],['ø','&oslash;'],['Õ','&Otilde;'],['Ø','&Oslash;'],
	['ù','&ugrave;'],['ú','&uacute;'],['û','&ucirc;'],['ü','&uuml;'],
	['Ù','&Ugrave;'],['Ú','&Uacute;'],['Û','&Ucirc;'],['Ü','&Uuml;'],
	['ý','&yacute;'],['Ý','&Yacute;'],['ÿ','&yuml;'], 
	['þ','&thorn;'], ['Þ','&THORN;'], ['ß','&szlig;'],
	['Š','&brvbar;'],['Ž','&acute;'], ['ž','&cedil;'],['š','&uml;'],
	['·','&middot;'],['¯','&macr;'],
	['«','&laquo;'], ['»','&raquo;'], ['¡','&iexcl;'],['¿','&iquest;'],
	['±','&plusmn;'],['×','&times;'], ['÷','&divide;'],
	['¬','&not;'],   ['°','&deg;'],   ['º','&ordm;'], ['ª','&ordf;'],
	['¹','&sup1;'],  ['²','&sup2;'],  ['³','&sup3;'],
	['Œ','&frac14;'],['œ','&frac12;'],['Ÿ','&frac34;'],
	['€','&curren;'],['¢','&cent;'],  ['£','&pound;'],['¥','&yen;'],
	['§','&sect;'],  ['¶','&para;'],  ['©','&copy;'], ['®','&reg;'],
);
sub spaces2entities { _tr('fore', $space2entety) }
sub entities2spaces { _tr('back', $space2entety) }
sub chars2entities  { _tr('fore', @char2entity) }
sub entities2chars  { _tr('back', @char2entity) }

1;
__END__

=head1 NAME

Kephra::App::Convert - character and word translation functions

=head1 DESCRIPTION

