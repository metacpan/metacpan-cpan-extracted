package syntaxhighlighter::conf;
$VERSION = '0.01';

sub load{

use Wx qw(wxSTC_LEX_CONF wxSTC_H_TAG);

 $_[0]->SetLexer( wxSTC_LEX_CONF );         # Set Lexers to use
 $_[0]->SetKeyWords(0,'');

# $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec( 0,"fore:#000000");               # whitespace (SCE_CONF_DEFAULT)
 $_[0]->StyleSetSpec( 1,"fore:#777777");               # Comment (SCE_CONF_COMMENT)
 $_[0]->StyleSetSpec( 2,"fore:#007f7f");               # Number (SCE_CONF_NUMBER)
 $_[0]->StyleSetSpec( 3,"fore:#888820");               # Apache Runtime Directive (SCE_CONF_DIRECTIVE)
 $_[0]->StyleSetSpec( 4,"fore:#202020");               # extensions (like .gz, .tgz, .html) (SCE_CONF_EXTENSION)
 $_[0]->StyleSetSpec( 5,"fore:#208820");               # parameters for Apache Runtime directives (SCE_CONF_PARAMETER)
 $_[0]->StyleSetSpec( 6,"fore:#882020");               # Double quoted string (SCE_CONF_STRING)
 $_[0]->StyleSetSpec( 7,"fore:#202020");               # Operators (SCE_CONF_OPERATOR)
 $_[0]->StyleSetSpec( 8,"fore:#209999");               # IP address (SCE_CONF_IP)
 $_[0]->StyleSetSpec( 9,"fore:#202020");               # identifier (SCE_CONF_IDENTIFIER)
}

1;
