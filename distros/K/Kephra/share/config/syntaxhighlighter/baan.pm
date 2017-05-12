package syntaxhighlighter::baan;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_BAAN);

sub load {
 $_[0]->SetLexer( wxSTC_LEX_BAAN );
 $_[0]->SetKeyWords(0,'');

 $_[0]->StyleSetSpec( 0,"fore:#808080");			# White space
 $_[0]->StyleSetSpec( 1,"fore:#aaaaaa");			# Comment
 $_[0]->StyleSetSpec( 2,"fore:#aaaaaa,back:#E0C0E0");# Doc comment
 $_[0]->StyleSetSpec( 3,"fore:#007f7f");			# Number
 $_[0]->StyleSetSpec( 4,"fore:#000077,bold");		# Keyword
 $_[0]->StyleSetSpec( 5,"fore:#ee7b00,back:#fff8f8");# Double quoted string
 $_[0]->StyleSetSpec( 6,"fore:#800080");			# Preprocessor
 $_[0]->StyleSetSpec( 7,"fore:#B06000");			# Operators
 $_[0]->StyleSetSpec( 8,"fore:#000077");			# Identifiers
 $_[0]->StyleSetSpec( 9,"fore:#000000,back:#E0C0E0,eolfilled");# End of line where string is not closed
 $_[0]->StyleSetSpec(10,"fore:#B00040");			# Operator: * ? < > |
 $_[0]->StyleSetSpec(32,"fore:#000000");			# Default
}

1;
