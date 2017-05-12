package Kephra::Edit::Special;
$VERSION = '0.01';

use strict;
use warnings;

sub _ep_ref { Kephra::App::EditPanel::_ref() }

sub copy_surrounding_string { # Edit String (surrounding string encapsulated by "" or '')
	my $ep = _ep_ref();
	my $pos  = $ep->GetCurrentPos;
	my $line = $ep->GetCurrentLine;
	my $lpos = $ep->PositionFromLine($line);
	my $befor_text = $ep->GetTextRange($lpos, $pos);
	my $after_text = $ep->GetTextRange($pos+1, $ep->GetLineEndPosition($line));
	my $sq_start = rindex $befor_text, '\'';
	my $sq_stop  = index $after_text, '\'';
	my $dq_start = rindex $befor_text, '"';
	my $dq_stop  = index $after_text, '"';
	return if  ($sq_start == -1 or $sq_stop == -1) 
	       and ($dq_start == -1 or $dq_stop == -1);
	Kephra::Edit::_save_positions();
	if ($sq_start > $dq_start){$ep->SetSelection($lpos+$sq_start+1, $pos+$sq_stop+1)}
	else                      {$ep->SetSelection($lpos+$dq_start+1, $pos+$dq_stop+1)}
	Kephra::Edit::copy();
	Kephra::Edit::_restore_positions();
}

sub insert_last_perl_var {
	my $ep = _ep_ref();
	my $lnr = $ep->GetCurrentLine;
	return unless $lnr;
	my $pos  = $ep->GetCurrentPos;
	my $var;     # store catched var name into that scalar
	my $nl = ''; # namespace level, how nested is current ns?
	while (1){
		# go up and get me the conent of the line
		my $line = $ep->GetLine(--$lnr);
		# catch the perl var
		my $result = $line =~ /([\$@%]\w+)[\[{ -=\(\r\n]/;
		$nl++ if $line =~ /^\s*\}/;
		$nl-- if $line =~ /\{\s*(#.*)?$/;
		$var = $nl ? '' : $1;
		# exit loop if found something in this , no subnamespace,
		# or reached end of file or end of block
		last if $var or $lnr == 0 or ($nl and $nl < 0);
	}
	return unless $var;
	$ep->InsertText( $pos, $var);
	$ep->GotoPos($pos + length $var);
}

sub insert_time_date {
	my @t = localtime;
	Kephra::Edit::insert( sprintf(
		"%02d:%02d %02d.%02d.%d",
		$t[2],$t[1],$t[3],1+$t[4],1900+$t[5]
	) );
}

1; 