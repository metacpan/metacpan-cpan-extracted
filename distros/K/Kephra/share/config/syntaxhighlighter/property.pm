package syntaxhighlighter::property;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_PROPERTIES);

sub load {
 $_[0]->SetLexer( wxSTC_LEX_PROPERTIES );
 $_[0]->SetKeyWords(0,'');

 $_[0]->StyleSetSpec( 0,"fore:#000000");		# Default
 $_[0]->StyleSetSpec( 1,"fore:#aaaaaa");		# Comment
 $_[0]->StyleSetSpec( 2,"fore:#0000ff");		# Section
 $_[0]->StyleSetSpec( 3,"fore:#ff0000");		# Assignment operator
 $_[0]->StyleSetSpec( 4,"fore:#007700");		# Default value (@)
 $_[0]->StyleSetSpec( 5,"fore:#007b7b");		# Key
 $_[0]->StyleSetSpec(34,"fore:#0000ff,notbold");# Matched Operators
 $_[0]->StyleSetSpec(35,"fore:#ff0000,notbold");# Matched Operators
}

1;
