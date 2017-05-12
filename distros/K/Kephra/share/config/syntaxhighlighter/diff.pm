package syntaxhighlighter::diff;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_DIFF);

sub load{
 $_[0]->SetLexer( wxSTC_LEX_DIFF );
 $_[0]->SetKeyWords(0,'');

 $_[0]->StyleSetSpec( 0,"fore:#000000");	# Default
 $_[0]->StyleSetSpec( 1,"fore:#007F00");	# Comment (part before "diff ..." or "--- ..." and , Only in ..., Binary file...)
 $_[0]->StyleSetSpec( 2,"fore:#7F7F00");	# Command (diff ...)
 $_[0]->StyleSetSpec( 3,"fore:#7F0000");	# Source file (--- ...) and Destination file (+++ ...)
 $_[0]->StyleSetSpec( 4,"fore:#7F007F");	# Position setting (@@ ...)
 $_[0]->StyleSetSpec( 5,"fore:#007F7F");	# Line removal (-...)
 $_[0]->StyleSetSpec( 6,"fore:#00007F");	# Line addition (+...)

}

1;
