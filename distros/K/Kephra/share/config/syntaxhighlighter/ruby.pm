package syntaxhighlighter::ruby;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_RUBY wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_RUBY );         # Set Lexers to use
 $_[0]->SetKeyWords(0,'__FILE__ and def end in or self unless __LINE__ begin \
defined? ensure module redo super until BEGIN break do false next rescue \
then when END case else for nil require retry true while alias class elsif if \
not return undef yield');

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");               # whitespace (SCE_CONF_DEFAULT)
 $_[0]->StyleSetSpec( 1,"fore:#555555");               # Comment (SCE_CONF_COMMENT)
 $_[0]->StyleSetSpec( 2,"fore:#3350ff");               # Number (SCE_CONF_NUMBER)
 $_[0]->StyleSetSpec( 3,"fore:#888820");               # String
 $_[0]->StyleSetSpec( 4,"fore:#202020");               # Single quoted string
 $_[0]->StyleSetSpec( 5,"fore:#208820,bold");          # Keyword
 $_[0]->StyleSetSpec( 6,"fore:#882020");               # Triple quotes
 $_[0]->StyleSetSpec( 7,"fore:#202020");               # Triple double quotes
 $_[0]->StyleSetSpec( 8,"fore:#209999");               # Class name definition
 $_[0]->StyleSetSpec( 9,"fore:#202020");               # Function or method name definition
 $_[0]->StyleSetSpec(10,"fore:#000000");               # Operators
 $_[0]->StyleSetSpec(11,"fore:#000055");          # Identifiers
 $_[0]->StyleSetSpec(12,"fore:#7f7f7f");               # Comment-blocks
 $_[0]->StyleSetSpec(13,"fore:#000000,back:#E0C0E0,eolfilled");  # End of line where string is not closed
 $_[0]->StyleSetSpec(34,"fore:#0000ff");               # Matched Operators
 $_[0]->StyleSetSpec(35,"fore:#ff0000");               # Matched Operators

}

1;
