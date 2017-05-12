package syntaxhighlighter::ave;
$VERSION = '0.01';

use Wx qw(wxSTC_LEX_AVE wxSTC_H_TAG);

sub load{
 $_[0]->SetLexer( wxSTC_LEX_AVE );
 $_[0]->SetKeyWords(0,'nil true false else for if while then elseif end av self \
in exit');

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)
 $_[0]->StyleSetSpec( 0,"fore:#FF0000");			# White space
 $_[0]->StyleSetSpec( 1,"fore:#aaaaaa");			# Comment
 $_[0]->StyleSetSpec( 2,"fore:#007f7f");			# Number
 $_[0]->StyleSetSpec( 3,"fore:#000077,bold");		# Keyword
 $_[0]->StyleSetSpec( 6,"fore:#f36600");			# String
 $_[0]->StyleSetSpec( 7,"fore:#207f7f,bold");		# Enumeration
 $_[0]->StyleSetSpec( 8,"back:#E0C0E0,eolfilled");	# End of line where string is not closed
 $_[0]->StyleSetSpec( 9,"fore:#7F007f");			# Identifier (everything else...)
 $_[0]->StyleSetSpec(10,"fore:#ff9999");			# Operators
 $_[0]->StyleSetSpec(11,"fore:#FF0000");			# Illegal token
 $_[0]->StyleSetSpec(32,"fore:#000000");			# Default 
# Other keywords 12-16 (bozo test colors :-) 12,13 bold
 
}

1;
