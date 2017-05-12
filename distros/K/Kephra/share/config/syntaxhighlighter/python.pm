package syntaxhighlighter::python;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_PYTHON wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_PYTHON );			# Set Lexers to use
 $_[0]->SetKeyWords(0,'and assert break class continue def del elif \
else except exec finally for from global if import in is lambda None \
not or pass print raise return try while yield');

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );	# Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");			# whitespace (SCE_CONF_DEFAULT)
 $_[0]->StyleSetSpec( 1,"fore:#777777");			# Comment (SCE_CONF_COMMENT)
 $_[0]->StyleSetSpec( 2,"fore:#3350ff");			# Number (SCE_CONF_NUMBER)
 $_[0]->StyleSetSpec( 3,"fore:#888820");			# String
 $_[0]->StyleSetSpec( 4,"fore:#202020");			# Single quoted string
 $_[0]->StyleSetSpec( 5,"fore:#208820");			# Keyword
 $_[0]->StyleSetSpec( 6,"fore:#882020");			# Triple quotes
 $_[0]->StyleSetSpec( 7,"fore:#202020");			# Triple double quotes
 $_[0]->StyleSetSpec( 8,"fore:#209999");			# Class name definition
 $_[0]->StyleSetSpec( 9,"fore:#202020");			# Function or method name definition
 $_[0]->StyleSetSpec(10,"fore:#000000");			# Operators
 $_[0]->StyleSetSpec(11,"fore:#777777");			# Identifiers
 $_[0]->StyleSetSpec(12,"fore:#7f7f7f");			# Comment-blocks
 $_[0]->StyleSetSpec(13,"fore:#000000,back:#E0C0E0,eolfilled");  # End of line where string is not closed
 $_[0]->StyleSetSpec(34,"fore:#0000ff");			# Matched Operators
 $_[0]->StyleSetSpec(35,"fore:#ff0000");			# Matched Operators

}

1;
