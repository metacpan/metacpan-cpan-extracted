package syntaxhighlighter::yaml;
$VERSION = '0.01';

sub load{

	use Wx qw(wxSTC_LEX_YAML wxSTC_H_TAG);
	$_[0]->SetLexer( wxSTC_LEX_YAML );         # Set Lexers to use
	$_[0]->SetKeyWords(0,'true false yes no');                     # Add new keyword.
	$_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)
 
 $_[0]->StyleSetSpec(0,"fore:#000000");                                    # default
 $_[0]->StyleSetSpec(1,"fore:#008800");                                    # comment line
 $_[0]->StyleSetSpec(2,"fore:#000088,bold");                               # value identifier
 $_[0]->StyleSetSpec(3,"fore:#880088");                                    # keyword value
 $_[0]->StyleSetSpec(4,"fore:#880000");                                    # numerical value
 $_[0]->StyleSetSpec(5,"fore:#008888");                                    # reference/repeating value
 $_[0]->StyleSetSpec(6,"fore:#FFFFFF,bold,back:#000088,eolfilled");        # document delimiting line
 $_[0]->StyleSetSpec(7,"fore:#333366");                                    # text block marker
 $_[0]->StyleSetSpec(8,"fore:#FFFFFF,italics,bold,back:#FF0000,eolfilled");# syntax error marker
}

1;
