package syntaxhighlighter::make;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_MAKEFILE);

sub load{
 $_[0]->SetLexer( wxSTC_LEX_MAKEFILE );
 $_[0]->SetKeyWords(0,'');

 $_[0]->StyleSetSpec( 0,"fore:#000000");		# Default
 $_[0]->StyleSetSpec( 1,"fore:#aaaaaa");		# Comment
 $_[0]->StyleSetSpec( 2,"fore:#007F00");		# Pre-processor or other comment: !
 $_[0]->StyleSetSpec( 3,"fore:#000080");		# Variable: $(x)
 $_[0]->StyleSetSpec( 4,"fore:#7F007F");		# Operator
 $_[0]->StyleSetSpec( 5,"fore:#A00000");		# Target
 $_[0]->StyleSetSpec( 9,"fore:#7f0000,eolfilled");# Error
 $_[0]->StyleSetSpec(34,"fore:#0000ff,notbold");# Matched Operators
 $_[0]->StyleSetSpec(35,"fore:#ff0000,notbold");# Matched Operators

}

1;
