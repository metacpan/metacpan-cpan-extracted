package Kephra::Edit::Comment;
our $VERSION = '0.08';

use strict;
use warnings;

# Comment
sub add_block {
	my $csymbol = shift;
	my $symlength = length $csymbol;
	my $ep = &Kephra::App::EditPanel::_ref;
	my ($a, $b) = $ep->GetSelection;
	my ($al, $bl) = ($ep->LineFromPosition( $a ), $ep->LineFromPosition( $b ));
	my $lip;
	my $lipa = $ep->GetLineIndentPosition($al);
	my $lipb = $ep->GetLineIndentPosition($bl);
	$a += $symlength if $ep->GetTextRange($lipa, $lipa + $symlength) ne $csymbol
	                 and $a > $lipa;
	$b -= $symlength if $ep->GetTextRange($lipb, $lipb + $symlength) ne $csymbol
	                 and $b <= $lipb;

	$ep->BeginUndoAction;
	for ( $al .. $bl ) {
		$lip = $ep->GetLineIndentPosition($_);
		$ep->InsertText($lip, $csymbol), $b += $symlength
			if $ep->GetTextRange($lip, $lip + $symlength) ne $csymbol;
	}
	$ep->SetSelection($a, $b);
	$ep->EndUndoAction;
}

sub remove_block {
	my $csymbol = shift;
	my $symlength = length $csymbol;
	my $ep = &Kephra::App::EditPanel::_ref;
	my ($a, $b) = $ep->GetSelection;
	my ($al, $bl) = ($ep->LineFromPosition( $a ), $ep->LineFromPosition( $b ));
	my $lip;
	my $lipa = $ep->GetLineIndentPosition($al);
	my $rema = $ep->GetTextRange($lipa, $lipa + $symlength) eq $csymbol;
	my $lipb = $ep->GetLineIndentPosition($bl);
	my $remb = $ep->GetTextRange($lipb, $lipb + $symlength) eq $csymbol;

	$ep->BeginUndoAction;
	for ( $al .. $bl ) {
		$lip = $ep->GetLineIndentPosition($_);
		$ep->SetTargetStart($lip);
		$ep->SetTargetEnd( $lip + $symlength );
		$ep->ReplaceTarget(''), $b -= $symlength
			if $ep->SearchInTarget($csymbol) > -1;
	}
	$a -= $symlength if $rema and $a >  $lipa;
	$b += $symlength if $remb and $b <= $lipb;
	$ep->SetSelection($a, $b);
	$ep->EndUndoAction;
}

sub toggle_block {
	my $csymbol = shift;
	my $symlength = length $csymbol;
	my $ep = &Kephra::App::EditPanel::_ref;
	my $lip;

	$ep->BeginUndoAction;
	my ($a,  $b) = $ep->GetSelection;
	my ($al, $bl) = ($ep->LineFromPosition( $a ), $ep->LineFromPosition( $b ));
	$lip = $ep->GetLineIndentPosition($al);
	my $add = $ep->GetTextRange($lip, $lip + $symlength) ne $csymbol;
	my $found;

	$ep->BeginUndoAction;
	for ($al .. $bl) {
		$lip = $ep->GetLineIndentPosition($_);
		$ep->SetTargetStart($lip);
		$ep->SetTargetEnd( $lip + $symlength );
		$found = $ep->SearchInTarget($csymbol) != -1;
		if ($add){ $ep->InsertText($lip, $csymbol), $b += $symlength if not $found }
		else     { $ep->ReplaceTarget('')         , $b -= $symlength if     $found }
	}
	$a = $add ? $a + $symlength : $a - $symlength;
	$a = $ep->PositionFromLine( $al ) if $a < $ep->PositionFromLine( $al );
	$b = $ep->PositionFromLine( $bl ) if $b < $ep->PositionFromLine( $bl );
	$ep->SetSelection($a, $b);
	$ep->EndUndoAction;
}

sub format_block {
	my $csymbol  = shift;
	my $ep = Kephra::App::EditPanel::_ref();
	my $lp;
	my $a = $ep->LineFromPosition( $ep->GetSelectionStart );
	my $b = $ep->LineFromPosition( $ep->GetSelectionEnd );
	$ep->BeginUndoAction;
	for ($b .. $a) {
		$lp = $ep->PositionFromLine($_);
	}
	$ep->EndUndoAction;
}

sub add_stream {
	my $ep = Kephra::App::EditPanel::_ref();
	my ( $openbrace, $closebrace ) = @_;
	my ( $startpos, $endpos ) = $ep->GetSelection;
	my ( $commentpos, $firstopos, $lastopos, $firstcpos, $lastcpos )
		= ( -1, $endpos, -1, $endpos, -1 );
	$ep->BeginUndoAction;
	$ep->SetTargetStart($startpos);
	$ep->SetTargetEnd($endpos);
	while ( ( $commentpos = $ep->SearchInTarget($openbrace) ) > -1 ) {
		$firstopos = $commentpos if $firstopos > $commentpos;
		$lastopos = $commentpos;
		$ep->SetSelectionStart($commentpos);
		$ep->SetSelectionEnd( $commentpos + length($openbrace) );
		$ep->ReplaceSelection("");
		$endpos -= length($openbrace);
		$ep->SetTargetStart($commentpos);
		$ep->SetTargetEnd($endpos);
	}
	$ep->SetTargetStart($startpos);
	$ep->SetTargetEnd($endpos);
	while ( ( $commentpos = $ep->SearchInTarget($closebrace) ) > -1 ) {
		$firstcpos = $commentpos if ( $firstcpos > $commentpos );
		$lastcpos = $commentpos;
		$ep->SetSelectionStart($commentpos);
		$ep->SetSelectionEnd( $commentpos + length($closebrace) );
		$ep->ReplaceSelection("");
		$endpos -= length($closebrace);
		$ep->SetTargetStart($commentpos);
		$ep->SetTargetEnd($endpos);
	}
	$ep->InsertText( $endpos,   $closebrace ) if $lastcpos == -1;
	$ep->InsertText( $startpos, $openbrace ) if $lastopos == -1;
	$ep->InsertText( $startpos, $openbrace ) if $firstopos < $firstcpos;
	$ep->InsertText( $endpos,   $closebrace ) if  $lastopos < $lastcpos;
	#$ep->InsertText($endpos, $closebrace);
	#$ep->InsertText($startpos, $openbrace);
	$ep->EndUndoAction;
}

sub remove_stream {    #o=openposition c=closeposition
	my ( $openbrace, $closebrace ) = @_;
	my $ep = Kephra::App::EditPanel::_ref();
	my ( $startpos, $endpos ) = $ep->GetSelection();
	my $firstopos = my $firstcpos =               $endpos;
	my $commentpos = my $lastopos = my $lastcpos = -1;
	if ( $startpos < $endpos ) {
		$ep->BeginUndoAction();
		$ep->SetTargetStart($startpos);
		$ep->SetTargetEnd($endpos);
		while ( ( $commentpos = $ep->SearchInTarget($openbrace) ) > -1 ) {
			$firstopos = $commentpos if ( $firstopos > $commentpos );
			$lastopos = $commentpos;
			$ep->SetSelectionStart($commentpos);
			$ep->SetSelectionEnd( $commentpos + length($openbrace) );
			$ep->ReplaceSelection("");
			$endpos -= length($openbrace);
			$ep->SetTargetStart($commentpos);
			$ep->SetTargetEnd($endpos);
		}
		$ep->SetTargetStart($startpos);
		$ep->SetTargetEnd($endpos);
		while ( ($commentpos = $ep->SearchInTarget($closebrace) ) > -1 ) {
			$firstcpos = $commentpos if ( $firstcpos > $commentpos );
			$lastcpos = $commentpos;
			$ep->SetSelectionStart($commentpos);
			$ep->SetSelectionEnd( $commentpos + length($closebrace) );
			$ep->ReplaceSelection("");
			$endpos -= length($closebrace);
			$ep->SetTargetStart($commentpos);
			$ep->SetTargetEnd($endpos);
		}
		if ( $firstopos > $firstcpos ) {
			$ep->InsertText( $startpos, $closebrace );
		}
		if ( $lastopos > $lastcpos ) {
			$ep->InsertText( $endpos, $openbrace );
		}
		if ( ( $lastopos == -1 ) && ( $lastcpos == -1 ) ) {
			$ep->InsertText( $startpos, $closebrace );
			$ep->InsertText( $endpos + length($closebrace), $openbrace );
		}
		$ep->EndUndoAction();
	}
}

sub add_script    { add_block   ('#') }
sub sub_script    { remove_block('#') }
sub toggle_script { toggle_block('#') }
sub format_script { format_block('#') }
sub sub_xml       { remove_stream( '<!--', '-->' ) }
sub add_xml       { add_stream   ( '<!--', '-->' ) }
sub add_c         { add_stream   ( '/*', '*/' ) }
sub sub_c         { remove_stream( '/*', '*/' ) }

1;
__END__

=head1 NAME

Kephra::App::Comment - add and remove comments in your code text

=head1 DESCRIPTION

=cut